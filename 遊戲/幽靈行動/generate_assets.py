"""
幽靈行動 - 素材生成工具
用途：
  1. 從 policeman_cc0 精靈產生玩家版（藍色調）和 Boss 版（金色調）
  2. 生成更高品質的音效（多層次槍聲 + 更豐富的 BGM）
執行：python generate_assets.py
"""

import struct, math
from pathlib import Path
from PIL import Image

ROOT    = Path(__file__).parent / "src" / "assets"
SRC_COP = ROOT / "characters/swat/policeman_cc0/Policeman"
OUT_PLR = ROOT / "characters/swat/policeman_player/Policeman"
OUT_BSS = ROOT / "characters/swat/policeman_boss/Policeman"
AUDIO   = ROOT / "audio"

# ─────────────── 精靈重新上色 ────────────────────────────────

def _shift_hue(img: Image.Image, mode: str) -> Image.Image:
    """
    mode='player' → 整體藍色調（友軍 SWAT）
    mode='boss'   → 整體金色調 + 加深（精銳 Boss）
    使用 numpy 對所有非透明像素做通道調整，效果明顯
    """
    import numpy as np
    rgba = np.array(img.convert("RGBA"), dtype=np.float32)
    r, g, b, a = rgba[:,:,0], rgba[:,:,1], rgba[:,:,2], rgba[:,:,3]
    mask = a > 10  # 只處理非透明像素

    if mode == "player":
        # 藍色調：紅通道壓低、藍通道拉高（整體偏藍鋼色）
        rgba[mask, 0] = np.clip(r[mask] * 0.60, 0, 255)        # 紅 ↓↓
        rgba[mask, 1] = np.clip(g[mask] * 0.80, 0, 255)        # 綠 ↓
        rgba[mask, 2] = np.clip(b[mask] * 1.0 + 55, 0, 255)   # 藍 ↑↑

    elif mode == "boss":
        # 金色調：紅+綠拉高、藍壓低，並整體加深增加威脅感
        rgba[mask, 0] = np.clip(r[mask] * 1.0 + 45, 0, 255)   # 紅 ↑
        rgba[mask, 1] = np.clip(g[mask] * 1.0 + 30, 0, 255)   # 綠 ↑（金黃感）
        rgba[mask, 2] = np.clip(b[mask] * 0.30, 0, 255)       # 藍 ↓↓↓

    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def generate_sprites():
    folders = ["_idle", "_walk", "_shoot"]

    for out_root, mode in [(OUT_PLR, "player"), (OUT_BSS, "boss")]:
        label = "玩家（藍）" if mode == "player" else "Boss（金）"
        print(f"\n── 生成 {label} 精靈 ──")

        for folder in folders:
            src_dir = SRC_COP / folder
            tgt_dir = out_root / folder
            tgt_dir.mkdir(parents=True, exist_ok=True)

            pngs = sorted(src_dir.glob("*.png"))
            for img_path in pngs:
                img = Image.open(img_path).convert("RGBA")
                result = _shift_hue(img, mode)
                result.save(tgt_dir / img_path.name)

            print(f"  {folder}: {len(pngs)} 幀 → {tgt_dir.relative_to(ROOT)}")

    print("\n精靈生成完成！")


# ─────────────── 音效生成 ─────────────────────────────────────

SAMPLE_RATE = 44100

def _write_wav(path: Path, samples: list[float], sample_rate: int = SAMPLE_RATE):
    """將 float 樣本（-1.0~1.0）寫成 16bit PCM WAV"""
    clipped = [max(-1.0, min(1.0, s)) for s in samples]
    pcm = struct.pack(f"<{len(clipped)}h", *[int(s * 32767) for s in clipped])
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(pcm)))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b"data")
        f.write(struct.pack("<I", len(pcm)))
        f.write(pcm)


def _sine(freq, duration, amp=1.0, sr=SAMPLE_RATE):
    n = int(sr * duration)
    return [amp * math.sin(2 * math.pi * freq * t / sr) for t in range(n)]


def _noise(duration, amp=1.0, sr=SAMPLE_RATE):
    import random
    n = int(sr * duration)
    return [amp * (random.random() * 2 - 1) for _ in range(n)]


def _envelope(samples, attack=0.002, decay=0.05, sustain=0.3, release=0.1, sr=SAMPLE_RATE):
    total = len(samples)
    a = int(sr * attack)
    d = int(sr * decay)
    r = int(sr * release)
    result = []
    for i, s in enumerate(samples):
        if i < a:
            env = i / a
        elif i < a + d:
            env = 1.0 - (1.0 - sustain) * (i - a) / d
        elif i < total - r:
            env = sustain
        else:
            env = sustain * (total - i) / r
        result.append(s * env)
    return result


def _mix(*tracks):
    """混合多條音軌（自動對齊長度）"""
    max_len = max(len(t) for t in tracks)
    result = [0.0] * max_len
    for t in tracks:
        for i, s in enumerate(t):
            result[i] += s
    peak = max(abs(s) for s in result) or 1.0
    return [s / peak for s in result]


def gen_gunshot():
    """多層次槍聲：爆音 + 低頻衝擊 + 金屬環境聲"""
    import random
    random.seed(42)

    sr = SAMPLE_RATE

    # 層 1：爆音（白噪音 burst）
    blast_dur = 0.012
    blast = _noise(blast_dur, amp=0.9, sr=sr)
    blast = _envelope(blast, attack=0.0005, decay=0.01, sustain=0.0, release=0.001, sr=sr)

    # 層 2：低頻衝擊（80Hz 短正弦）
    body_dur = 0.08
    body = _sine(80, body_dur, amp=0.7, sr=sr)
    body = _envelope(body, attack=0.001, decay=0.04, sustain=0.05, release=0.03, sr=sr)

    # 層 3：上中頻殘響（700Hz 衰減）
    ring_dur = 0.15
    ring = _sine(700, ring_dur, amp=0.15, sr=sr)
    ring = _envelope(ring, attack=0.001, decay=0.1, sustain=0.0, release=0.04, sr=sr)

    # 層 4：高頻裂聲（3500Hz 極短）
    crack_dur = 0.006
    crack = _sine(3500, crack_dur, amp=0.4, sr=sr)
    crack = _envelope(crack, attack=0.0002, decay=0.005, sustain=0.0, release=0.0005, sr=sr)

    total_dur = 0.25
    total_n = int(sr * total_dur)

    def pad(t): return t + [0.0] * (total_n - len(t))

    mixed = _mix(pad(blast), pad(body), pad(ring), pad(crack))
    _write_wav(AUDIO / "sfx/gunshot.wav", mixed)
    print("  gunshot.wav → 多層次（爆音+低頻+環境聲）")


def gen_reload():
    """換彈聲：彈匣出 + 短停頓 + 彈匣入 + 上膛滑動"""
    sr = SAMPLE_RATE

    def metallic_click(freq, dur, amp):
        s = _sine(freq, dur, amp, sr)
        n = _noise(dur * 0.5, amp * 0.3, sr)
        n += [0.0] * (len(s) - len(n))
        mixed = [a + b for a, b in zip(s, n)]
        return _envelope(mixed, attack=0.001, decay=dur * 0.4, sustain=0.1, release=dur * 0.3, sr=sr)

    gap = [0.0] * int(sr * 0.12)
    gap2 = [0.0] * int(sr * 0.08)

    eject  = metallic_click(380, 0.06, 0.9)   # 彈匣退出
    insert = metallic_click(520, 0.08, 1.0)   # 彈匣插入
    rack   = metallic_click(260, 0.05, 0.8)   # 上膛

    sequence = eject + gap + insert + gap2 + rack
    _write_wav(AUDIO / "sfx/reload.wav", sequence)
    print("  reload.wav → 三段金屬聲（退匣+插匣+上膛）")


def gen_enemy_death():
    """敵人死亡聲：短促喘息 + 沉悶衝擊"""
    sr = SAMPLE_RATE

    impact = _sine(120, 0.04, 0.8, sr)
    impact = _envelope(impact, attack=0.001, decay=0.03, sustain=0.05, release=0.008, sr=sr)

    noise_hit = _noise(0.05, 0.5, sr)
    noise_hit = _envelope(noise_hit, attack=0.0005, decay=0.04, sustain=0.0, release=0.005, sr=sr)

    gap = [0.0] * int(sr * 0.02)
    fall = _sine(80, 0.15, 0.3, sr)
    fall = [s * max(0, 1.0 - i / len(fall)) for i, s in enumerate(fall)]

    sequence = _mix(
        impact + gap + fall,
        noise_hit + [0.0] * (len(gap) + len(fall))
    )
    _write_wav(AUDIO / "sfx/enemy_death.wav", sequence)
    print("  enemy_death.wav → 衝擊+沉落聲")


def gen_bgm_battle():
    """戰鬥 BGM：8 秒循環，低音貝斯 + 打擊樂 + 緊張旋律"""
    sr = SAMPLE_RATE
    bpm = 140
    beat = sr * 60 // bpm  # samples per beat
    bar = beat * 4         # 4/4 拍，一小節
    loop_bars = 4
    total = bar * loop_bars

    track = [0.0] * total

    def add_sine(freq, start, dur_beats, amp):
        n = int(dur_beats * beat)
        s = _sine(freq, n / sr, amp, sr)
        s = _envelope(s, attack=0.01, decay=0.1, sustain=0.6, release=0.1, sr=sr)
        for i, v in enumerate(s):
            if start + i < total:
                track[start + i] += v

    def add_noise_hit(start, dur, amp):
        n = int(dur * sr)
        s = _noise(dur, amp, sr)
        s = _envelope(s, attack=0.001, decay=dur * 0.3, sustain=0.1, release=dur * 0.4, sr=sr)
        for i, v in enumerate(s):
            if start + i < total:
                track[start + i] += v

    # 低音貝斯（E2 = 82 Hz，每半拍）
    bass_notes = [82, 82, 92, 82, 73, 82, 87, 82]
    for bar_i in range(loop_bars):
        for beat_i in range(8):
            start = bar_i * bar + beat_i * beat // 2
            freq = bass_notes[beat_i % len(bass_notes)]
            add_sine(freq, start, 0.45, 0.5)

    # 緊張旋律線（Am 五聲音階）
    melody = [220, 261, 293, 349, 220, 392, 349, 261]
    for bar_i in range(loop_bars):
        for beat_i in range(8):
            if beat_i in [0, 1, 3, 4, 6, 7]:
                start = bar_i * bar + beat_i * beat // 2
                freq = melody[beat_i % len(melody)] / 2  # 低八度
                add_sine(freq, start, 0.3, 0.25)

    # 大鼓（每 1、3 拍）+ 小鼓（每 2、4 拍）
    for bar_i in range(loop_bars):
        for beat_i in range(4):
            start = bar_i * bar + beat_i * beat
            if beat_i % 2 == 0:
                add_noise_hit(start, 0.08, 0.7)   # 大鼓
            else:
                add_noise_hit(start, 0.05, 0.5)   # 小鼓

    # Hi-hat（每八分音符）
    for bar_i in range(loop_bars):
        for eighth in range(8):
            if eighth % 2 == 1:  # 反拍 hi-hat
                start = bar_i * bar + eighth * beat // 2
                hat = _noise(0.015, 0.2, sr)
                hat = _envelope(hat, attack=0.001, decay=0.01, sustain=0.0, release=0.004, sr=sr)
                for i, v in enumerate(hat):
                    if start + i < total:
                        track[start + i] += v

    # 正規化
    peak = max(abs(s) for s in track) or 1.0
    normalized = [s / peak * 0.85 for s in track]

    _write_wav(AUDIO / "bgm/bgm_battle.wav", normalized)
    print(f"  bgm_battle.wav → {loop_bars} 小節循環（BPM {bpm}，貝斯+打擊+旋律）")


def gen_bgm_gameplay():
    """關卡 3 救援任務 BGM：較慢節奏，緊張潛行風"""
    sr = SAMPLE_RATE
    bpm = 90
    beat = sr * 60 // bpm
    bar = beat * 4
    loop_bars = 4
    total = bar * loop_bars

    track = [0.0] * total

    def add_sine(freq, start, dur_beats, amp):
        n = int(dur_beats * beat)
        s = _sine(freq, n / sr, amp, sr)
        s = _envelope(s, attack=0.02, decay=0.15, sustain=0.5, release=0.2, sr=sr)
        for i, v in enumerate(s):
            if start + i < total:
                track[start + i] += v

    # 深沉低音（Dm 和弦感）
    bass_pattern = [73, 73, 69, 73, 87, 73, 82, 69]
    for bar_i in range(loop_bars):
        for beat_i in range(8):
            start = bar_i * bar + beat_i * beat // 2
            add_sine(bass_pattern[beat_i % len(bass_pattern)], start, 0.5, 0.4)

    # 緩慢旋律（上方聲部）
    for bar_i in range(loop_bars):
        for beat_i in [0, 2, 4, 6]:
            start = bar_i * bar + beat_i * beat // 2
            melody_freqs = [293, 349, 261, 329]
            add_sine(melody_freqs[(beat_i // 2) % 4], start, 0.9, 0.2)

    # 輕微打擊（稀疏）
    for bar_i in range(loop_bars):
        for beat_i in [0, 2]:
            start = bar_i * bar + beat_i * beat
            n = int(0.06 * sr)
            hit = _noise(0.06, 0.3, sr)
            hit = _envelope(hit, attack=0.001, decay=0.04, sustain=0.05, release=0.01, sr=sr)
            for i, v in enumerate(hit):
                if start + i < total:
                    track[start + i] += v

    peak = max(abs(s) for s in track) or 1.0
    normalized = [s / peak * 0.8 for s in track]
    _write_wav(AUDIO / "bgm/gameplay_bgm.wav", normalized)
    print(f"  gameplay_bgm.wav → {loop_bars} 小節循環（BPM {bpm}，潛行氛圍）")


def generate_audio():
    print("\n── 生成音效 ──")
    gen_gunshot()
    gen_reload()
    gen_enemy_death()

    print("\n── 生成 BGM ──")
    gen_bgm_battle()
    gen_bgm_gameplay()

    print("\n音效生成完成！")


# ─────────────── 主程式 ────────────────────────────────────────

if __name__ == "__main__":
    print("═" * 50)
    print("  幽靈行動 素材生成工具")
    print("═" * 50)
    generate_sprites()
    generate_audio()
    print("\n═" * 50)
    print("  所有素材生成完畢！")
    print("═" * 50)
