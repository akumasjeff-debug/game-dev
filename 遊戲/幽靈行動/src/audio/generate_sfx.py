"""
幽靈行動 — 音效佔位符生成腳本
使用 Python 標準庫（wave + math）生成所有 WAV 音效
取樣率：44100Hz / 16-bit PCM / 單聲道
"""

import wave
import struct
import math
import os
import random

SAMPLE_RATE = 44100
MAX_AMPLITUDE = 32767  # 16-bit


def write_wav(filepath, frames):
    """將 frames（bytes）寫入 WAV 檔"""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)       # 16-bit = 2 bytes
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(frames)


def samples_to_bytes(samples):
    """將 float 樣本列表（-1.0 ~ 1.0）轉成 16-bit PCM bytes"""
    data = bytearray()
    for s in samples:
        val = int(max(-1.0, min(1.0, s)) * MAX_AMPLITUDE)
        data += struct.pack('<h', val)
    return bytes(data)


def sine(freq, duration, amplitude=1.0, phase=0.0):
    """生成正弦波樣本列表"""
    n = int(SAMPLE_RATE * duration)
    return [amplitude * math.sin(2 * math.pi * freq * i / SAMPLE_RATE + phase)
            for i in range(n)]


def fade_out(samples, fade_duration):
    """尾端淡出（指數衰減）"""
    n = len(samples)
    fade_n = int(SAMPLE_RATE * fade_duration)
    fade_n = min(fade_n, n)
    result = list(samples)
    for i in range(fade_n):
        idx = n - fade_n + i
        factor = 1.0 - (i / fade_n)
        result[idx] *= factor
    return result


def fade_in(samples, fade_duration):
    """頭端淡入"""
    fade_n = int(SAMPLE_RATE * fade_duration)
    result = list(samples)
    for i in range(min(fade_n, len(result))):
        result[i] *= i / fade_n
    return result


def envelope(samples, attack=0.005, decay=0.0, sustain=1.0, release=0.02):
    """ADSR 包絡，全部以秒計"""
    n = len(samples)
    a_n = int(SAMPLE_RATE * attack)
    d_n = int(SAMPLE_RATE * decay)
    r_n = int(SAMPLE_RATE * release)
    result = []
    for i, s in enumerate(samples):
        if i < a_n:
            env = i / max(a_n, 1)
        elif i < a_n + d_n:
            t = (i - a_n) / max(d_n, 1)
            env = 1.0 - t * (1.0 - sustain)
        elif i >= n - r_n:
            t = (i - (n - r_n)) / max(r_n, 1)
            env = sustain * (1.0 - t)
        else:
            env = sustain
        result.append(s * env)
    return result


def white_noise(duration, amplitude=1.0):
    """白噪音"""
    n = int(SAMPLE_RATE * duration)
    return [amplitude * (random.random() * 2 - 1) for _ in range(n)]


def mix(*tracks):
    """混合多個軌道（正規化至 -1~1）"""
    length = max(len(t) for t in tracks)
    result = [0.0] * length
    for track in tracks:
        for i, s in enumerate(track):
            result[i] += s
    peak = max(abs(s) for s in result) if result else 1.0
    if peak > 1.0:
        result = [s / peak for s in result]
    return result


def glide(freq_start, freq_end, duration, amplitude=1.0):
    """線性滑音（portamento）"""
    n = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / n
        freq = freq_start + (freq_end - freq_start) * t
        samples.append(amplitude * math.sin(phase))
        phase += 2 * math.pi * freq / SAMPLE_RATE
    return samples


def exp_decay(freq, duration, amplitude=1.0, decay_rate=8.0):
    """指數衰減正弦（模擬打擊音）"""
    n = int(SAMPLE_RATE * duration)
    return [amplitude * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
            * math.exp(-decay_rate * i / n)
            for i in range(n)]


def concat(*tracks):
    """串接音軌"""
    result = []
    for t in tracks:
        result.extend(t)
    return result


# ──────────────────────────────────────────────
# UI 音效
# ──────────────────────────────────────────────

BASE = r"d:\開發遊戲\遊戲\幽靈行動\src\audio"


def gen_btn_click():
    """短促高頻 click — 440Hz，0.08秒"""
    s = exp_decay(440, 0.08, amplitude=0.8, decay_rate=12.0)
    s = envelope(s, attack=0.002, release=0.01)
    write_wav(os.path.join(BASE, "ui", "btn_click.wav"), samples_to_bytes(s))
    print("  ui/btn_click.wav — 440Hz 短促高頻 click (0.08s)")


def gen_decision_open():
    """低頻→高頻滑音提示 — 220Hz→440Hz，0.3秒"""
    s = glide(220, 440, 0.3, amplitude=0.75)
    s = envelope(s, attack=0.01, release=0.06)
    write_wav(os.path.join(BASE, "ui", "decision_open.wav"), samples_to_bytes(s))
    print("  ui/decision_open.wav — 220→440Hz 滑音 (0.3s)")


def gen_decision_confirm():
    """確認音 — 660Hz，0.15秒"""
    s = sine(660, 0.15, amplitude=0.7)
    s = envelope(s, attack=0.005, release=0.04)
    write_wav(os.path.join(BASE, "ui", "decision_confirm.wav"), samples_to_bytes(s))
    print("  ui/decision_confirm.wav — 660Hz 確認音 (0.15s)")


def gen_ult_ready():
    """大招冷卻完成 — 880Hz 三連音，各 0.1s，間隔 0.033s，共 0.4s"""
    silence = [0.0] * int(SAMPLE_RATE * 0.033)
    beat = sine(880, 0.1, amplitude=0.65)
    beat = envelope(beat, attack=0.005, release=0.03)
    # 第三音升頻強調
    beat3 = sine(1100, 0.1, amplitude=0.75)
    beat3 = envelope(beat3, attack=0.005, release=0.03)
    s = concat(beat, silence, beat, silence, beat3)
    write_wav(os.path.join(BASE, "ui", "ult_ready.wav"), samples_to_bytes(s))
    print("  ui/ult_ready.wav — 880Hz 三連音 (0.4s)")


def gen_victory():
    """勝利 stinger — C大調上行五音，共 1.0秒"""
    # C4=261.63 D4=293.66 E4=329.63 G4=392.00 C5=523.25
    freqs = [261.63, 293.66, 329.63, 392.00, 523.25]
    durations = [0.12, 0.12, 0.12, 0.18, 0.46]
    parts = []
    for freq, dur in zip(freqs, durations):
        note = sine(freq, dur, amplitude=0.7)
        note = envelope(note, attack=0.008, release=0.04)
        parts.append(note)
    s = concat(*parts)
    write_wav(os.path.join(BASE, "ui", "victory.wav"), samples_to_bytes(s))
    print("  ui/victory.wav — C大調上行 stinger (1.0s)")


def gen_defeat():
    """失敗 stinger — 低頻下行，0.8秒"""
    # A3→F3→D3 下行
    freqs = [220.00, 174.61, 146.83]
    durations = [0.2, 0.2, 0.4]
    parts = []
    for freq, dur in zip(freqs, durations):
        note = sine(freq, dur, amplitude=0.6)
        note = envelope(note, attack=0.01, release=0.08)
        parts.append(note)
    s = concat(*parts)
    write_wav(os.path.join(BASE, "ui", "defeat.wav"), samples_to_bytes(s))
    print("  ui/defeat.wav — 低頻下行 stinger (0.8s)")


# ──────────────────────────────────────────────
# 大招音效
# ──────────────────────────────────────────────

def gen_shield_ult():
    """盾兵護盾 — 低沉厚重 160Hz，0.6秒"""
    # 主體：低頻嗡鳴上升
    body = glide(120, 200, 0.4, amplitude=0.8)
    body = envelope(body, attack=0.05, release=0.1)
    # 第二諧波增厚
    body2 = glide(240, 400, 0.4, amplitude=0.3)
    body2 = envelope(body2, attack=0.05, release=0.1)
    # 尾音持續
    tail = sine(160, 0.2, amplitude=0.5)
    tail = envelope(tail, attack=0.0, release=0.15)
    s = mix(body, body2)
    s = concat(list(s), tail)
    write_wav(os.path.join(BASE, "ult", "shield_ult.wav"), samples_to_bytes(s))
    print("  ult/shield_ult.wav — 160Hz 低沉護盾音 (0.6s)")


def gen_medic_ult():
    """醫療兵治療 — 輕柔上揚 528Hz，0.5秒"""
    body = glide(400, 660, 0.35, amplitude=0.65)
    body = envelope(body, attack=0.02, release=0.08)
    # 確認「叮」音
    ding = exp_decay(1046, 0.15, amplitude=0.5, decay_rate=10.0)
    silence = [0.0] * int(SAMPLE_RATE * 0.02)
    s = concat(body, silence, ding)
    write_wav(os.path.join(BASE, "ult", "medic_ult.wav"), samples_to_bytes(s))
    print("  ult/medic_ult.wav — 528Hz 輕柔治療音 (0.5s)")


def gen_assault_ult():
    """突擊手火力 — 快速噪音爆發，0.4秒"""
    # 前奏：短促上膛聲（高頻金屬撞擊）
    clank = exp_decay(800, 0.05, amplitude=0.6, decay_rate=20.0)
    clank_n = [s + white_noise(0.05, 0.2)[i] for i, s in enumerate(clank)]
    # 主體：密集噪音爆發 + 低頻底音
    burst = white_noise(0.3, 0.8)
    low = sine(80, 0.3, amplitude=0.5)
    low = envelope(low, attack=0.005, release=0.05)
    burst_mix = mix(burst, low)
    burst_mix = envelope(list(burst_mix), attack=0.01, release=0.08)
    silence = [0.0] * int(SAMPLE_RATE * 0.01)
    s = concat(clank_n, silence, list(burst_mix))
    write_wav(os.path.join(BASE, "ult", "assault_ult.wav"), samples_to_bytes(s))
    print("  ult/assault_ult.wav — 噪音爆發火力音 (0.4s)")


def gen_sniper_ult():
    """狙擊手 — 高頻尖銳短促 1200Hz，0.2秒"""
    body = exp_decay(1200, 0.15, amplitude=0.85, decay_rate=15.0)
    tail = glide(1200, 600, 0.05, amplitude=0.2)
    s = concat(body, tail)
    s = envelope(s, attack=0.001, release=0.02)
    write_wav(os.path.join(BASE, "ult", "sniper_ult.wav"), samples_to_bytes(s))
    print("  ult/sniper_ult.wav — 1200Hz 高頻狙擊音 (0.2s)")


def gen_demo_ult():
    """爆破手 — 低頻爆炸感 80Hz + noise，0.7秒"""
    # 低頻衝擊
    bass = exp_decay(80, 0.4, amplitude=0.9, decay_rate=6.0)
    bass2 = exp_decay(50, 0.4, amplitude=0.6, decay_rate=5.0)
    # 爆炸噪音層
    noise = white_noise(0.5, 0.7)
    noise = envelope(noise, attack=0.002, release=0.25)
    # 0.1秒靜音後爆炸
    pre_silence = [0.0] * int(SAMPLE_RATE * 0.05)
    main_mix = mix(bass, bass2, noise[:len(bass)])
    tail_noise = noise[len(bass):]
    s = concat(pre_silence, list(main_mix), list(tail_noise))
    write_wav(os.path.join(BASE, "ult", "demo_ult.wav"), samples_to_bytes(s))
    print("  ult/demo_ult.wav — 80Hz 爆炸 + 噪音 (0.7s)")


def gen_recon_ult():
    """偵察手煙霧 — 白噪音淡入，0.5秒"""
    noise = white_noise(0.5, 0.6)
    # 頻率過濾模擬：用多諧波低頻 sine 疊加模擬「模糊」感
    low1 = sine(300, 0.5, amplitude=0.15)
    low2 = sine(450, 0.5, amplitude=0.1)
    s = mix(noise, low1, low2)
    s = fade_in(list(s), 0.2)
    s = fade_out(s, 0.15)
    write_wav(os.path.join(BASE, "ult", "recon_ult.wav"), samples_to_bytes(s))
    print("  ult/recon_ult.wav — 白噪音煙霧淡入 (0.5s)")


# ──────────────────────────────────────────────
# 戰鬥音效
# ──────────────────────────────────────────────

def gen_footstep():
    """腳步聲 — 低頻短促，0.1秒"""
    # 低頻撞擊 + 少量噪音
    thud = exp_decay(120, 0.08, amplitude=0.7, decay_rate=18.0)
    n_part = white_noise(0.08, 0.3)
    n_part = envelope(n_part, attack=0.001, release=0.04)
    s = mix(thud, n_part)
    # 尾端少量高頻（靴子底摩擦）
    high = exp_decay(600, 0.02, amplitude=0.2, decay_rate=25.0)
    s = concat(list(s)[:int(SAMPLE_RATE * 0.08)], high)
    write_wav(os.path.join(BASE, "combat", "footstep.wav"), samples_to_bytes(s))
    print("  combat/footstep.wav — 低頻腳步 (0.1s)")


def gen_gunshot():
    """槍聲 — noise burst，0.15秒"""
    # 短促高能噪音
    burst = white_noise(0.03, 1.0)
    burst = envelope(burst, attack=0.001, release=0.02)
    # 低頻底音模擬膛壓
    bass = exp_decay(100, 0.12, amplitude=0.7, decay_rate=12.0)
    bass2 = exp_decay(200, 0.06, amplitude=0.4, decay_rate=15.0)
    silence = [0.0] * int(SAMPLE_RATE * 0.12)
    # 填齊長度
    burst_padded = list(burst) + [0.0] * (int(SAMPLE_RATE * 0.12))
    s = mix(burst_padded[:int(SAMPLE_RATE * 0.15)],
            bass,
            bass2)
    write_wav(os.path.join(BASE, "combat", "gunshot.wav"), samples_to_bytes(s))
    print("  combat/gunshot.wav — noise burst 槍聲 (0.15s)")


def gen_explosion():
    """爆炸 — 低頻 + 噪音，0.6秒"""
    # 低頻衝擊核心
    core = exp_decay(60, 0.35, amplitude=0.95, decay_rate=5.0)
    core2 = exp_decay(90, 0.35, amplitude=0.7, decay_rate=6.0)
    # 中頻噪音體
    noise_body = white_noise(0.5, 0.8)
    noise_body = envelope(noise_body, attack=0.002, release=0.3)
    # 高頻碎片聲（短促）
    shrapnel = white_noise(0.08, 0.4)
    shrapnel = envelope(shrapnel, attack=0.001, release=0.04)
    shrapnel_padded = list(shrapnel) + [0.0] * (int(SAMPLE_RATE * 0.52))
    # 組合
    core_padded = list(core) + [0.0] * int(SAMPLE_RATE * 0.25)
    core2_padded = list(core2) + [0.0] * int(SAMPLE_RATE * 0.25)
    target_len = int(SAMPLE_RATE * 0.6)

    def pad(lst, length):
        return (lst + [0.0] * length)[:length]

    s = mix(
        pad(core_padded, target_len),
        pad(core2_padded, target_len),
        pad(noise_body, target_len),
        pad(shrapnel_padded, target_len),
    )
    write_wav(os.path.join(BASE, "combat", "explosion.wav"), samples_to_bytes(s))
    print("  combat/explosion.wav — 低頻爆炸 + 噪音 (0.6s)")


# ──────────────────────────────────────────────
# 執行
# ──────────────────────────────────────────────

if __name__ == "__main__":
    random.seed(42)   # 讓噪音結果可重現

    print("\n[UI 音效]")
    gen_btn_click()
    gen_decision_open()
    gen_decision_confirm()
    gen_ult_ready()
    gen_victory()
    gen_defeat()

    print("\n[大招音效]")
    gen_shield_ult()
    gen_medic_ult()
    gen_assault_ult()
    gen_sniper_ult()
    gen_demo_ult()
    gen_recon_ult()

    print("\n[戰鬥音效]")
    gen_footstep()
    gen_gunshot()
    gen_explosion()

    print("\n全部完成，共 15 個 WAV 音效。")
