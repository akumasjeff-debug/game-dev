import wave, struct, math, os

def generate_bgm(filename, notes, tempo_bpm=90, sample_rate=22050):
    """生成多音符旋律 BGM"""
    frames = []
    beat_duration = 60.0 / tempo_bpm

    for freq, beats in notes:
        num_samples = int(sample_rate * beat_duration * beats)
        for i in range(num_samples):
            t = i / sample_rate
            # 主旋律 + 低頻伴奏
            val = 0.4 * math.sin(2 * math.pi * freq * t)
            if freq > 0:
                val += 0.2 * math.sin(2 * math.pi * freq * 0.5 * t)  # 低八度
            # 淡入淡出
            fade = min(i / (sample_rate * 0.02), 1.0) * min((num_samples - i) / (sample_rate * 0.02), 1.0)
            val *= fade
            frames.append(struct.pack('<h', int(val * 32767)))

    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(frames))

output_dir = r"D:\開發遊戲\遊戲\幽靈行動\src\audio\bgm"
os.makedirs(output_dir, exist_ok=True)

# 停車場 BGM：低沉緊張，D小調，慢速
warehouse_notes = [
    (146.83, 2), (130.81, 2), (146.83, 1), (0, 1),   # D3 C3 D3 rest
    (164.81, 2), (146.83, 2), (130.81, 1), (0, 1),   # E3 D3 C3 rest
    (146.83, 1), (130.81, 1), (116.54, 2), (0, 2),   # D3 C3 Bb2 rest
    (130.81, 3), (0, 1),                               # C3 rest
] * 2
generate_bgm(os.path.join(output_dir, "warehouse_bgm.wav"), warehouse_notes, tempo_bpm=70)
print("Generated: warehouse_bgm.wav")

# 港口 BGM：中速，緊張節奏，E小調
harbor_notes = [
    (164.81, 1), (184.99, 1), (196.0, 2),   # E3 F#3 G3
    (184.99, 1), (164.81, 1), (146.83, 2),   # F#3 E3 D3
    (164.81, 1), (0, 1), (184.99, 2),        # E3 rest F#3
    (196.0, 1), (164.81, 1), (146.83, 2),   # G3 E3 D3
] * 3
generate_bgm(os.path.join(output_dir, "harbor_bgm.wav"), harbor_notes, tempo_bpm=95)
print("Generated: harbor_bgm.wav")

print("Done.")
