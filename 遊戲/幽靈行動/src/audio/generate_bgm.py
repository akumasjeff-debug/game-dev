"""
幽靈行動 — BGM 生成腳本
使用 Python 標準庫（wave + math + random）生成所有 BGM WAV
技術規格：44100Hz / 16-bit PCM / 單聲道

BGM 清單（對應 AUDIO_SPEC 1.0）：
  base_bgm.wav       — 基地主題 1-A，BPM 76，8秒 seamless loop
  mission_bgm.wav    — 任務推進 1-B，BPM 96，8秒 seamless loop
  high_alert_bgm.wav — 緊張段 1-C，BPM 116，8秒 seamless loop
  boss_bgm.wav       — Boss 戰 1-D，BPM 100，8秒 seamless loop
  victory_bgm.wav    — 任務勝利 1-E，4秒，單次播放
  defeat_bgm.wav     — 任務失敗 1-F，3秒，單次播放
"""

import wave
import struct
import math
import os
import random

SAMPLE_RATE = 44100
MAX_AMPLITUDE = 32767
BASE = r"d:\開發遊戲\遊戲\幽靈行動\src\audio"


# ──────────────────────────────────────────────
# 基礎工具函式（沿用 generate_sfx.py 的慣例）
# ──────────────────────────────────────────────

def write_wav(filepath, frames):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(frames)


def samples_to_bytes(samples):
    data = bytearray()
    for s in samples:
        val = int(max(-1.0, min(1.0, s)) * MAX_AMPLITUDE)
        data += struct.pack('<h', val)
    return bytes(data)


def sine(freq, n_samples, amplitude=1.0, phase_offset=0.0):
    """生成 n_samples 個正弦波樣本"""
    return [amplitude * math.sin(2 * math.pi * freq * i / SAMPLE_RATE + phase_offset)
            for i in range(n_samples)]


def saw(freq, n_samples, amplitude=1.0):
    """鋸齒波（合成低音線條質感）"""
    period = SAMPLE_RATE / freq
    return [amplitude * (2.0 * ((i % period) / period) - 1.0)
            for i in range(n_samples)]


def square(freq, n_samples, amplitude=1.0, duty=0.5):
    """方波（電子鼓/bass 質感）"""
    period = SAMPLE_RATE / freq
    return [amplitude if (i % period) < period * duty else -amplitude
            for i in range(n_samples)]


def white_noise_buf(n_samples, amplitude=1.0):
    return [amplitude * (random.random() * 2 - 1) for _ in range(n_samples)]


def mix_tracks(*tracks):
    """等長混合（截短到最短軌道長度）"""
    length = min(len(t) for t in tracks)
    result = [0.0] * length
    for track in tracks:
        for i in range(length):
            result[i] += track[i]
    # 正規化防止 clipping
    peak = max(abs(s) for s in result) if result else 1.0
    if peak > 1.0:
        result = [s / peak for s in result]
    return result


def apply_envelope_full(samples, attack_s=0.01, release_s=0.05):
    """整段加淡入淡出（讓 loop 接縫平滑）"""
    n = len(samples)
    a = int(SAMPLE_RATE * attack_s)
    r = int(SAMPLE_RATE * release_s)
    result = list(samples)
    for i in range(min(a, n)):
        result[i] *= i / a
    for i in range(min(r, n)):
        idx = n - r + i
        result[idx] *= (r - i) / r
    return result


def exp_decay_buf(freq, n_samples, amplitude=1.0, decay_rate=6.0):
    return [amplitude * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
            * math.exp(-decay_rate * i / n_samples)
            for i in range(n_samples)]


# ──────────────────────────────────────────────
# 節奏輔助：按 BPM 生成打擊層
# ──────────────────────────────────────────────

def kick_pattern(bpm, total_samples, beat_positions, freq=80, decay=0.18):
    """
    beat_positions: 以「第幾拍（0-based float）」表示的踢鼓位置清單
    decay: 衰減秒數
    """
    buf = [0.0] * total_samples
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    decay_n = int(SAMPLE_RATE * decay)
    for beat in beat_positions:
        start = int(beat * beat_samples)
        for j in range(decay_n):
            if start + j >= total_samples:
                break
            t = j / decay_n
            val = math.sin(2 * math.pi * freq * j / SAMPLE_RATE) * math.exp(-6 * t)
            buf[start + j] += val * 0.85
    return buf


def hi_hat_pattern(bpm, total_samples, beat_positions, freq=8000, decay=0.04):
    """踩镲層（高頻短促噪音）"""
    buf = [0.0] * total_samples
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    decay_n = int(SAMPLE_RATE * decay)
    for beat in beat_positions:
        start = int(beat * beat_samples)
        for j in range(decay_n):
            if start + j >= total_samples:
                break
            t = j / decay_n
            noise_val = (random.random() * 2 - 1)
            val = noise_val * math.exp(-15 * t)
            buf[start + j] += val * 0.3
    return buf


def snare_pattern(bpm, total_samples, beat_positions, freq=200, decay=0.12):
    """軍鼓層"""
    buf = [0.0] * total_samples
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    decay_n = int(SAMPLE_RATE * decay)
    for beat in beat_positions:
        start = int(beat * beat_samples)
        for j in range(decay_n):
            if start + j >= total_samples:
                break
            t = j / decay_n
            tone = math.sin(2 * math.pi * freq * j / SAMPLE_RATE)
            noise_val = (random.random() * 2 - 1)
            val = (tone * 0.4 + noise_val * 0.6) * math.exp(-10 * t)
            buf[start + j] += val * 0.6
    return buf


def bass_line(bpm, total_samples, note_pattern, freq_base=80):
    """
    note_pattern: [(beat_offset_float, freq_multiplier, duration_beats), ...]
    生成低音線條（鋸齒波 + 指數衰減）
    """
    buf = [0.0] * total_samples
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    for (beat_offset, freq_mul, dur_beats) in note_pattern:
        freq = freq_base * freq_mul
        start = int(beat_offset * beat_samples)
        dur_n = int(dur_beats * beat_samples)
        if start >= total_samples:
            continue
        end = min(start + dur_n, total_samples)
        n = end - start
        for j in range(n):
            t = j / SAMPLE_RATE
            # 鋸齒波基音 + 低八度 sine 疊加
            saw_val = (2.0 * ((j % (SAMPLE_RATE / freq)) / (SAMPLE_RATE / freq)) - 1.0) * 0.5
            sine_val = math.sin(2 * math.pi * freq * 0.5 * t) * 0.3
            decay_env = math.exp(-3.0 * j / max(n, 1))
            val = (saw_val + sine_val) * (0.3 + 0.7 * decay_env)
            buf[start + j] += val * 0.7
    return buf


def melody_line(bpm, total_samples, note_pattern):
    """
    note_pattern: [(beat_offset_float, freq, duration_beats, amplitude), ...]
    生成旋律線（正弦 + 五度和聲疊加）
    """
    buf = [0.0] * total_samples
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    for (beat_offset, freq, dur_beats, amp) in note_pattern:
        start = int(beat_offset * beat_samples)
        dur_n = int(dur_beats * beat_samples)
        if start >= total_samples:
            continue
        end = min(start + dur_n, total_samples)
        n = end - start
        for j in range(n):
            t = j / SAMPLE_RATE
            # 主音 + 五度和音 + 八度
            val = (
                math.sin(2 * math.pi * freq * t) * 0.5 +
                math.sin(2 * math.pi * freq * 1.5 * t) * 0.2 +
                math.sin(2 * math.pi * freq * 0.5 * t) * 0.3
            )
            # ADSR 包絡：快速 attack，慢速 release
            attack_n = min(int(SAMPLE_RATE * 0.02), n // 4)
            release_n = min(int(SAMPLE_RATE * 0.06), n // 3)
            if j < attack_n:
                env = j / max(attack_n, 1)
            elif j >= n - release_n:
                env = (n - j) / max(release_n, 1)
            else:
                env = 1.0
            buf[start + j] += val * env * amp
    return buf


def pad_layer(freq, total_samples, amplitude=0.2):
    """
    環境 pad 層（低頻正弦 + 緩慢調製，製造空間感）
    """
    buf = [0.0] * total_samples
    lfo_freq = 0.3  # 0.3 Hz 慢速震盪
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        lfo = 0.5 + 0.5 * math.sin(2 * math.pi * lfo_freq * t)
        val = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 1.01 * t) * 0.4  # 輕微失諧產生律動感
        )
        buf[i] = val * amplitude * lfo
    return buf


def normalize_buf(buf, target=0.9):
    peak = max(abs(s) for s in buf) if buf else 1.0
    if peak < 0.001:
        return buf
    factor = target / peak
    return [s * factor for s in buf]


# ──────────────────────────────────────────────
# BGM 1-A：基地主題（BPM 76，8秒）
# 沉穩待命感，電子低頻 pad + 琥珀鋼琴線條
# ──────────────────────────────────────────────

def gen_base_bgm():
    bpm = 76
    duration = 8.0
    n = int(SAMPLE_RATE * duration)
    random.seed(10)

    # 踢鼓（一拍一次，強調第 1、3 拍，第 1、3、5、7 拍）
    beats_per_bar = 4
    total_beats = bpm / 60 * duration  # 約 10.13 拍
    kick_beats = [i for i in range(int(total_beats) + 1) if i % 2 == 0]
    kick = kick_pattern(bpm, n, kick_beats, freq=70, decay=0.20)

    # 軍鼓（第 2、4 拍）
    snare_beats = [i for i in range(1, int(total_beats) + 1) if i % 2 == 1]
    snare = snare_pattern(bpm, n, snare_beats, freq=180, decay=0.10)

    # 踩镲（每半拍）
    hat_beats = [i * 0.5 for i in range(int(total_beats * 2) + 1)]
    hat = hi_hat_pattern(bpm, n, hat_beats, freq=6000, decay=0.025)

    # 低音線（Am → G → F → E 八小節進行）
    # A2=110 G2=98 F2=87.3 E2=82.4
    bass = bass_line(bpm, n, [
        (0.0, 1.0, 2.0),    # A2 = 110Hz 基頻乘1
        (2.0, 0.89, 2.0),   # G2 ≈ 98Hz
        (4.0, 0.794, 2.0),  # F2 ≈ 87.3Hz
        (6.0, 0.749, 2.0),  # E2 ≈ 82.4Hz
    ], freq_base=110)

    # 環境 pad（低頻 Am 根音）
    pad = pad_layer(110, n, amplitude=0.18)

    # 主旋律（輕柔的鋼琴音線條，使用 A minor 音階）
    # A3=220 C4=261.63 D4=293.66 E4=329.63 G4=392.00
    melody = melody_line(bpm, n, [
        (0.5, 220.00, 1.0, 0.35),
        (1.5, 261.63, 0.5, 0.30),
        (2.0, 293.66, 1.0, 0.30),
        (3.0, 329.63, 1.5, 0.35),
        (4.5, 261.63, 0.5, 0.28),
        (5.0, 220.00, 1.5, 0.32),
        (6.5, 196.00, 0.5, 0.25),
        (7.0, 220.00, 1.0, 0.30),
    ])

    # 混合各層
    raw = [kick[i] * 0.6 + snare[i] * 0.5 + hat[i] * 0.3
           + bass[i] * 0.8 + pad[i] * 0.7 + melody[i] * 0.6
           for i in range(n)]

    # seamless loop：頭尾淡入淡出（各 0.08 秒）
    result = apply_envelope_full(raw, attack_s=0.08, release_s=0.08)
    result = normalize_buf(result, target=0.82)

    path = os.path.join(BASE, "bgm", "base_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/base_bgm.wav — 基地主題 BPM 76，8秒 seamless loop")


# ──────────────────────────────────────────────
# BGM 1-B：任務推進一般（BPM 96，8秒）
# 緊張感背景，電子打擊律動 + 低音合成器線條
# ──────────────────────────────────────────────

def gen_mission_bgm():
    bpm = 96
    duration = 8.0
    n = int(SAMPLE_RATE * duration)
    random.seed(20)

    total_beats = bpm / 60 * duration  # 約 12.8 拍

    # 踢鼓（每拍一次，切分音：0, 0.75, 2, 2.75, 4, 4.75, ...）
    kick_beats = []
    for bar in range(4):
        b = bar * 4.0
        kick_beats.extend([b, b + 0.75, b + 2.0, b + 2.75])
    kick_beats = [b for b in kick_beats if b < total_beats]
    kick = kick_pattern(bpm, n, kick_beats, freq=75, decay=0.16)

    # 軍鼓（第 2、4 拍，更清脆）
    snare_beats = [i for i in range(1, int(total_beats) + 1) if i % 2 == 1]
    snare = snare_pattern(bpm, n, snare_beats, freq=220, decay=0.09)

    # 踩镲（每四分之一拍）
    hat_beats = [i * 0.25 for i in range(int(total_beats * 4) + 1)]
    hat = hi_hat_pattern(bpm, n, hat_beats, freq=7500, decay=0.02)

    # 低音線（E minor 進行，E2 → D2 → C2 → B1）
    # E2=82.4 D2=73.4 C2=65.4 B1=61.7
    bass = bass_line(bpm, n, [
        (0.0, 1.0,   2.0),
        (2.0, 0.891, 2.0),
        (4.0, 0.794, 2.0),
        (6.0, 0.749, 2.0),
    ], freq_base=82.4)

    # 高頻電子金屬點綴（短促 stab）
    stab_buf = [0.0] * n
    stab_beats = [1.5, 3.5, 5.5, 7.5]
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    stab_n = int(0.05 * SAMPLE_RATE)
    for beat in stab_beats:
        start = int(beat * beat_samples)
        for j in range(stab_n):
            if start + j >= n:
                break
            t = j / stab_n
            stab_buf[start + j] += (math.sin(2 * math.pi * 1200 * j / SAMPLE_RATE)
                                    * math.exp(-20 * t) * 0.4)

    # 旋律（E minor，緊張但不焦慮）
    # E3=164.81 G3=196.00 A3=220 B3=246.94 D4=293.66
    melody = melody_line(bpm, n, [
        (0.0, 164.81, 0.75, 0.30),
        (0.75, 196.00, 0.5,  0.25),
        (1.5, 220.00, 1.0,  0.32),
        (2.5, 246.94, 0.5,  0.28),
        (3.0, 220.00, 1.0,  0.30),
        (4.0, 196.00, 0.75, 0.28),
        (4.75, 164.81, 0.75, 0.25),
        (5.5, 196.00, 1.0,  0.28),
        (6.5, 220.00, 0.5,  0.30),
        (7.0, 246.94, 1.0,  0.32),
    ])

    raw = [kick[i] * 0.7 + snare[i] * 0.55 + hat[i] * 0.35
           + bass[i] * 0.85 + stab_buf[i] + melody[i] * 0.55
           for i in range(n)]

    result = apply_envelope_full(raw, attack_s=0.08, release_s=0.08)
    result = normalize_buf(result, target=0.85)

    path = os.path.join(BASE, "bgm", "mission_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/mission_bgm.wav — 任務推進 BPM 96，8秒 seamless loop")


# ──────────────────────────────────────────────
# BGM 1-C：高警戒緊張段（BPM 116，8秒）
# 壓力升高，厚重低音 + 急促切分 + 細密弦律
# ──────────────────────────────────────────────

def gen_high_alert_bgm():
    bpm = 116
    duration = 8.0
    n = int(SAMPLE_RATE * duration)
    random.seed(30)

    total_beats = bpm / 60 * duration  # 約 15.5 拍

    # 踢鼓（高密度切分，強調衝擊感）
    kick_beats = []
    for bar in range(4):
        b = bar * 4.0
        kick_beats.extend([b, b + 0.5, b + 2.0, b + 2.5, b + 3.25])
    kick_beats = [b for b in kick_beats if b < total_beats]
    kick = kick_pattern(bpm, n, kick_beats, freq=80, decay=0.14)

    # 軍鼓（每拍都有，更頻繁）
    snare_beats = [i for i in range(int(total_beats) + 1) if i % 2 == 1]
    snare = snare_pattern(bpm, n, snare_beats, freq=250, decay=0.08)

    # 踩镲（八分音符）
    hat_beats = [i * 0.25 for i in range(int(total_beats * 4) + 1)]
    hat = hi_hat_pattern(bpm, n, hat_beats, freq=9000, decay=0.015)

    # 低音（C minor，更緊張的和弦進行）
    # C2=65.4 Bb1=58.3 Ab1=51.9 G1=49.0
    bass = bass_line(bpm, n, [
        (0.0, 1.0,   2.0),
        (2.0, 0.891, 2.0),
        (4.0, 0.794, 2.0),
        (6.0, 0.749, 2.0),
    ], freq_base=65.4)

    # 厚重低頻 pad（增加壓迫感）
    pad = pad_layer(65.4, n, amplitude=0.25)

    # 急促上升弦律（E minor 但帶 7th，不完整感）
    # 使用更密集的音符
    melody = melody_line(bpm, n, [
        (0.0, 196.00, 0.5, 0.28),
        (0.5, 220.00, 0.5, 0.30),
        (1.0, 246.94, 0.5, 0.32),
        (1.5, 261.63, 0.5, 0.28),
        (2.0, 246.94, 0.5, 0.28),
        (2.5, 220.00, 0.5, 0.26),
        (3.0, 233.08, 0.5, 0.30),
        (3.5, 261.63, 0.5, 0.28),
        (4.0, 293.66, 0.5, 0.32),
        (4.5, 261.63, 0.5, 0.28),
        (5.0, 246.94, 0.5, 0.30),
        (5.5, 220.00, 0.5, 0.28),
        (6.0, 196.00, 0.5, 0.26),
        (6.5, 174.61, 0.5, 0.28),
        (7.0, 196.00, 0.5, 0.30),
        (7.5, 220.00, 0.5, 0.32),
    ])

    raw = [kick[i] * 0.75 + snare[i] * 0.6 + hat[i] * 0.4
           + bass[i] * 0.9 + pad[i] * 0.6 + melody[i] * 0.5
           for i in range(n)]

    result = apply_envelope_full(raw, attack_s=0.08, release_s=0.08)
    result = normalize_buf(result, target=0.88)

    path = os.path.join(BASE, "bgm", "high_alert_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/high_alert_bgm.wav — 高警戒 BPM 116，8秒 seamless loop")


# ──────────────────────────────────────────────
# BGM 1-D：Boss 戰（BPM 100，8秒）
# 重量感、史詩感，合成弦樂 + 重低頻鼓 + 管風琴 pad
# ──────────────────────────────────────────────

def gen_boss_bgm():
    bpm = 100
    duration = 8.0
    n = int(SAMPLE_RATE * duration)
    random.seed(40)

    total_beats = bpm / 60 * duration  # 約 13.3 拍

    # 踢鼓（非常重，第 1 拍強調）
    kick_beats = [0.0, 1.0, 3.0, 4.0, 5.0, 6.0, 7.5, 8.0, 9.0, 11.0, 12.0, 13.0]
    kick_beats = [b for b in kick_beats if b < total_beats]
    kick = kick_pattern(bpm, n, kick_beats, freq=65, decay=0.25)

    # 軍鼓（沉重版）
    snare_beats = [2.0, 6.0, 10.0]
    snare_beats = [b for b in snare_beats if b < total_beats]
    snare = snare_pattern(bpm, n, snare_beats, freq=160, decay=0.18)

    # 踩镲（較稀疏）
    hat_beats = [i * 0.5 for i in range(int(total_beats * 2) + 1)]
    hat = hi_hat_pattern(bpm, n, hat_beats, freq=6500, decay=0.03)

    # 低音（D minor，史詩感進行 D → C → Bb → A）
    # D2=73.4 C2=65.4 Bb1=58.3 A1=55.0
    bass = bass_line(bpm, n, [
        (0.0,  1.0,   4.0),
        (4.0,  0.891, 2.0),
        (6.0,  0.794, 1.0),
        (7.0,  0.749, 1.0),
    ], freq_base=73.4)

    # 管風琴式 pad（D minor 和弦，低頻厚重）
    # D2=73.4 + F2=87.3 + A2=110 的三音疊加
    pad_d = pad_layer(73.4, n, amplitude=0.22)
    pad_f = pad_layer(87.3, n, amplitude=0.18)
    pad_a = pad_layer(110.0, n, amplitude=0.15)

    # 史詩弦律（D minor 上行主題）
    # D3=146.83 F3=174.61 A3=220 C4=261.63 D4=293.66
    melody = melody_line(bpm, n, [
        (0.0, 146.83, 1.5, 0.40),
        (1.5, 174.61, 0.5, 0.35),
        (2.0, 220.00, 2.0, 0.42),
        (4.0, 261.63, 1.0, 0.38),
        (5.0, 220.00, 0.5, 0.35),
        (5.5, 196.00, 0.5, 0.32),
        (6.0, 174.61, 1.0, 0.35),
        (7.0, 146.83, 1.0, 0.40),
    ])

    # 電吉他 stab（短促 8va stab 增加衝擊）
    stab_buf = [0.0] * n
    beat_samples = int(60 / bpm * SAMPLE_RATE)
    stab_beats_pos = [0.0, 4.0, 8.0, 12.0]
    stab_n = int(0.08 * SAMPLE_RATE)
    for beat in stab_beats_pos:
        start = int(beat * beat_samples)
        for j in range(stab_n):
            if start + j >= n:
                break
            t_env = math.exp(-12 * j / stab_n)
            stab_buf[start + j] += (
                math.sin(2 * math.pi * 293.66 * j / SAMPLE_RATE) * 0.5 * t_env +
                math.sin(2 * math.pi * 146.83 * j / SAMPLE_RATE) * 0.3 * t_env
            ) * 0.5

    raw = [kick[i] * 0.8 + snare[i] * 0.6 + hat[i] * 0.25
           + bass[i] * 0.85 + pad_d[i] + pad_f[i] + pad_a[i]
           + melody[i] * 0.65 + stab_buf[i]
           for i in range(n)]

    result = apply_envelope_full(raw, attack_s=0.08, release_s=0.08)
    result = normalize_buf(result, target=0.90)

    path = os.path.join(BASE, "bgm", "boss_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/boss_bgm.wav — Boss 戰 BPM 100，8秒 seamless loop")


# ──────────────────────────────────────────────
# BGM 1-E：任務勝利（4秒，單次播放）
# 軍號式上升旋律 + 大鼓收尾，解脫 + 成就感
# ──────────────────────────────────────────────

def gen_victory_bgm():
    duration = 4.0
    n = int(SAMPLE_RATE * duration)
    random.seed(50)

    buf = [0.0] * n

    # 主旋律：軍號式 C 大調上行（C4→E4→G4→C5，再到 E5 高點）
    # C4=261.63 E4=329.63 G4=392.00 C5=523.25 E5=659.26
    melody_notes = [
        (0.0,   261.63, 0.25, 0.7),
        (0.25,  329.63, 0.25, 0.7),
        (0.5,   392.00, 0.25, 0.72),
        (0.75,  329.63, 0.25, 0.65),
        (1.0,   392.00, 0.5,  0.75),
        (1.5,   523.25, 0.5,  0.80),
        (2.0,   659.26, 1.0,  0.85),  # 高點延音
        (3.0,   523.25, 0.5,  0.70),
        (3.5,   392.00, 0.5,  0.65),
    ]

    beat_samples_60bpm = int(60 / 90 * SAMPLE_RATE)  # BPM 90 基準

    for (beat, freq, dur_beats, amp) in melody_notes:
        start = int(beat * beat_samples_60bpm)
        dur_n = int(dur_beats * beat_samples_60bpm)
        end = min(start + dur_n, n)
        seg_n = end - start
        for j in range(seg_n):
            t = j / SAMPLE_RATE
            # 五度 + 八度疊加（軍號質感）
            val = (
                math.sin(2 * math.pi * freq * t) * 0.55 +
                math.sin(2 * math.pi * freq * 1.5 * t) * 0.25 +
                math.sin(2 * math.pi * freq * 2.0 * t) * 0.15 +
                math.sin(2 * math.pi * freq * 0.5 * t) * 0.05
            )
            attack_n = min(int(SAMPLE_RATE * 0.015), seg_n // 4)
            release_n = min(int(SAMPLE_RATE * 0.05), seg_n // 3)
            if j < attack_n:
                env = j / max(attack_n, 1)
            elif j >= seg_n - release_n:
                env = (seg_n - j) / max(release_n, 1)
            else:
                env = 1.0
            buf[start + j] += val * env * amp

    # 大鼓三連擊（第 2 拍後方）
    # 位置：2.0秒、2.25秒、2.5秒
    drum_times = [2.0, 2.25, 2.5]
    drum_n = int(0.18 * SAMPLE_RATE)
    for dt in drum_times:
        start = int(dt * SAMPLE_RATE)
        for j in range(drum_n):
            if start + j >= n:
                break
            t_env = math.exp(-8 * j / drum_n)
            buf[start + j] += math.sin(2 * math.pi * 70 * j / SAMPLE_RATE) * t_env * 0.7

    # 尾端淡出（最後 0.5 秒）
    result = apply_envelope_full(buf, attack_s=0.02, release_s=0.5)
    result = normalize_buf(result, target=0.88)

    path = os.path.join(BASE, "bgm", "victory_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/victory_bgm.wav — 任務勝利旋律，4秒單次播放")


# ──────────────────────────────────────────────
# BGM 1-F：任務失敗（3秒，單次播放）
# 低沉下滑，略有遺憾但不強烈負面
# ──────────────────────────────────────────────

def gen_defeat_bgm():
    duration = 3.0
    n = int(SAMPLE_RATE * duration)
    random.seed(60)

    buf = [0.0] * n

    # 下行弦樂（A minor 下行，G3→E3→D3→A2）
    # G3=196.00 E3=164.81 D3=146.83 A2=110.00
    descent_notes = [
        (0.0,  196.00, 0.6, 0.55),
        (0.6,  164.81, 0.6, 0.50),
        (1.2,  146.83, 0.7, 0.48),
        (1.9,  130.81, 0.5, 0.42),
        (2.4,  110.00, 0.6, 0.38),
    ]

    for (t_start, freq, dur, amp) in descent_notes:
        start = int(t_start * SAMPLE_RATE)
        dur_n = int(dur * SAMPLE_RATE)
        end = min(start + dur_n, n)
        seg_n = end - start
        for j in range(seg_n):
            t = j / SAMPLE_RATE
            # 純正弦（哀愁弦樂質感）
            val = (
                math.sin(2 * math.pi * freq * t) * 0.60 +
                math.sin(2 * math.pi * freq * 2.0 * t) * 0.15 +
                math.sin(2 * math.pi * freq * 0.5 * t) * 0.25
            )
            attack_n = min(int(SAMPLE_RATE * 0.03), seg_n // 4)
            release_n = min(int(SAMPLE_RATE * 0.10), seg_n // 3)
            if j < attack_n:
                env = j / max(attack_n, 1)
            elif j >= seg_n - release_n:
                env = (seg_n - j) / max(release_n, 1)
            else:
                env = 1.0
            buf[start + j] += val * env * amp

    # 低頻鋼琴低鍵單音（A2，1.5秒後）
    piano_start = int(1.5 * SAMPLE_RATE)
    piano_n = int(1.2 * SAMPLE_RATE)
    for j in range(piano_n):
        if piano_start + j >= n:
            break
        t_env = math.exp(-4 * j / piano_n)
        buf[piano_start + j] += (
            math.sin(2 * math.pi * 110.00 * j / SAMPLE_RATE) * 0.4 * t_env +
            math.sin(2 * math.pi * 55.00 * j / SAMPLE_RATE) * 0.2 * t_env
        )

    # 全段漸弱淡出
    result = apply_envelope_full(buf, attack_s=0.03, release_s=0.6)
    result = normalize_buf(result, target=0.75)  # 比其他 BGM 稍安靜

    path = os.path.join(BASE, "bgm", "defeat_bgm.wav")
    write_wav(path, samples_to_bytes(result))
    print(f"  bgm/defeat_bgm.wav — 任務失敗低沉下滑，3秒單次播放")


# ──────────────────────────────────────────────
# 執行
# ──────────────────────────────────────────────

if __name__ == "__main__":
    print("\n[BGM 生成 — 幽靈行動]")
    gen_base_bgm()
    gen_mission_bgm()
    gen_high_alert_bgm()
    gen_boss_bgm()
    gen_victory_bgm()
    gen_defeat_bgm()
    print("\n全部完成，共 6 個 BGM WAV 檔案。")
    print("放置路徑：d:\\開發遊戲\\遊戲\\幽靈行動\\src\\audio\\bgm\\")
