"""
generate_bgm.py
生成台灣熱炒店風格 BGM（G 大調五聲音階，128 BPM）
輸出：assets/audio/bgm/main_theme.wav
格式：16-bit PCM、44100 Hz、單聲道、約 16 秒
"""

import wave
import struct
import math
import os

# ── 基本參數 ──────────────────────────────────────
SAMPLE_RATE = 44100
BPM = 128
BEAT_SEC = 60.0 / BPM          # 每拍秒數 = 0.46875 秒

# 任務規格寫 0.117 秒（=15 BPM? 應為 eighth-note 或指每「格」0.117 秒）
# 根據任務說明：每拍 0.117 秒 → 直接沿用規格值
BEAT_UNIT = 0.117               # 任務規格中的「每拍」單位秒數

# ── 頻率對照表 ─────────────────────────────────────
G2 = 98.0
G4 = 392.0
A4 = 440.0
B4 = 493.9
D5 = 587.3
E5 = 659.3
G5 = 784.0
D4 = 293.7
B3 = 246.9

# ── 音符序列（頻率, 拍數）────────────────────────────
bar1 = [
    (G4, 0.25), (B4, 0.25), (D5, 0.25), (G5, 0.25),
    (E5, 0.5),  (D5, 0.5),
    (B4, 0.25), (A4, 0.25), (G4, 0.5),
    (D4, 0.5),  (G4, 0.5),
]

bar2 = [
    (D5, 0.25), (E5, 0.25), (D5, 0.25), (B4, 0.25),
    (A4, 0.5),  (G4, 0.5),
    (A4, 0.25), (B4, 0.25), (D5, 0.5),
    (G5, 0.5),  (E5, 0.5),
]

bar3 = [
    (E5, 0.5),  (D5, 0.25), (B4, 0.25),
    (A4, 0.5),  (G4, 0.5),
    (B4, 0.25), (D5, 0.25), (E5, 0.5),
    (G5, 0.75), (E5, 0.25),
]

bar4 = [
    (D5, 0.5),  (B4, 0.5),
    (A4, 0.5),  (G4, 0.5),
    (B4, 0.5),  (D5, 0.5),
    (G4, 1.0),
]

melody = bar1 + bar2 + bar3 + bar4


# ── ADSR 包絡 ──────────────────────────────────────
def make_adsr(num_samples, attack=0.02, decay=0.05, sustain=0.8, release=0.05):
    """傳回長度為 num_samples 的 ADSR 包絡陣列（值域 0.0~1.0）"""
    sr = SAMPLE_RATE
    attack_s  = int(attack  * sr)
    decay_s   = int(decay   * sr)
    release_s = int(release * sr)
    sustain_s = max(0, num_samples - attack_s - decay_s - release_s)

    env = []
    # Attack
    for i in range(min(attack_s, num_samples)):
        env.append(i / max(attack_s, 1))
    # Decay
    for i in range(min(decay_s, num_samples - len(env))):
        env.append(1.0 - (1.0 - sustain) * (i / max(decay_s, 1)))
    # Sustain
    for _ in range(min(sustain_s, num_samples - len(env))):
        env.append(sustain)
    # Release
    remaining = num_samples - len(env)
    for i in range(remaining):
        env.append(sustain * (1.0 - i / max(remaining, 1)))

    return env


# ── 單音合成（三個正弦波疊加）──────────────────────────
def synthesize_note(freq, duration_sec, volume=0.9):
    """
    合成單一音符：基頻 + 八度音 + 五度音
    freq: 基礎頻率 Hz
    duration_sec: 持續秒數
    """
    num_samples = int(duration_sec * SAMPLE_RATE)
    env = make_adsr(num_samples)
    samples = []

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # 基頻 × 1.0
        s  = math.sin(2 * math.pi * freq * t) * 1.0
        # 八度音（× 2.0 頻率）× 0.4
        s += math.sin(2 * math.pi * freq * 2.0 * t) * 0.4
        # 五度音（× 1.5 頻率）× 0.25
        s += math.sin(2 * math.pi * freq * 1.5 * t) * 0.25

        # 疊加後正規化（三波峰值約 1.65）
        s /= 1.65
        s *= env[i] * volume
        samples.append(s)

    return samples


# ── 低頻低音伴奏（G2，持續整段）────────────────────────
def synthesize_bass(total_samples, volume=0.1):
    """G2 98Hz 持續低音，模擬低音伴奏"""
    freq = G2
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * freq * t)
        samples.append(s * volume)
    return samples


# ── 主合成流程 ──────────────────────────────────────
def generate_melody_samples():
    """依 melody 序列合成所有音符，回傳 float 樣本列表"""
    all_samples = []
    for freq, beats in melody:
        duration = beats * BEAT_UNIT
        note_samples = synthesize_note(freq, duration)
        all_samples.extend(note_samples)
    return all_samples


def mix_with_bass(melody_samples):
    """將旋律與低音伴奏混合"""
    total = len(melody_samples)
    bass = synthesize_bass(total)
    mixed = []
    for i in range(total):
        mixed.append(melody_samples[i] + bass[i])
    return mixed


def clamp_to_int16(samples):
    """將 float 樣本（-1.0~1.0）轉換為 16-bit int，並 clamp 避免溢位"""
    result = []
    MAX_INT16 = 32767
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        result.append(int(clamped * MAX_INT16))
    return result


# ── 寫入 WAV ──────────────────────────────────────
def write_wav(filepath, int16_samples):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)           # 單聲道
        wf.setsampwidth(2)           # 16-bit = 2 bytes
        wf.setframerate(SAMPLE_RATE)
        data = struct.pack(f'<{len(int16_samples)}h', *int16_samples)
        wf.writeframes(data)
    print(f"[generate_bgm] 已寫入 {filepath}（{len(int16_samples)} 樣本）")


# ── 入口 ──────────────────────────────────────────
if __name__ == "__main__":
    TARGET_DURATION = 16.0          # 目標輸出長度：16 秒
    TARGET_SAMPLES  = int(TARGET_DURATION * SAMPLE_RATE)

    print("[generate_bgm] 合成旋律…")
    melody_samples = generate_melody_samples()

    # melody 重複一次（共約 32 秒），取前 16 秒
    full_samples = melody_samples + melody_samples
    full_samples = full_samples[:TARGET_SAMPLES]

    print("[generate_bgm] 混入低音伴奏…")
    mixed = mix_with_bass(full_samples)

    print("[generate_bgm] 轉換為 16-bit…")
    int16 = clamp_to_int16(mixed)

    # 輸出路徑（相對於此腳本的 .. = src/）
    script_dir = os.path.dirname(os.path.abspath(__file__))
    src_dir    = os.path.dirname(script_dir)
    out_path   = os.path.join(src_dir, "assets", "audio", "bgm", "main_theme.wav")

    print(f"[generate_bgm] 寫入 {out_path}…")
    write_wav(out_path, int16)

    file_size = os.path.getsize(out_path)
    print(f"[generate_bgm] 完成！檔案大小：{file_size:,} bytes（{file_size / 1024:.1f} KB）")
