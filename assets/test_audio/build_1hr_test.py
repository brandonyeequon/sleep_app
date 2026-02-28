#!/usr/bin/env python3
"""
Build a 1-hour realistic sleep audio test file.

Simulates a night of sleep with realistic patterns:
- Sleep onset: quiet breathing transitioning to deeper sleep
- Multiple snoring episodes of varying intensity/duration
- 3-4 apnea episodes (snoring → silence → gasp → breathing)
- Quiet periods between episodes
- Gradual pattern: light sleep → heavy snoring → apnea cycles → lighter sleep

Uses real ESC-50 clips (snoring, breathing, cough) + generated silence.
"""

import wave
import struct
import random
import os
import array

SAMPLE_RATE = 44100
CHANNELS = 1
SAMPLE_WIDTH = 2  # 16-bit

SNORE_DIR = "/Users/brandonyeequon/Team-sleep/data/foreground_events/snoring"
BREATH_DIR = "/Users/brandonyeequon/Team-sleep/data/foreground_events/normal_breathing"
COUGH_DIR = "/Users/brandonyeequon/Team-sleep/data/foreground_events/cough"
OUT_FILE = "/Users/brandonyeequon/SLEEP/sleep_app/assets/test_audio/sleep_test_1hr.wav"

random.seed(42)  # Reproducible

def read_wav_samples(path):
    """Read a WAV file and return raw sample bytes."""
    with wave.open(path, 'rb') as w:
        return w.readframes(w.getnframes())

def generate_silence(duration_s):
    """Generate silence (very quiet noise floor) for given duration."""
    n_samples = int(SAMPLE_RATE * duration_s)
    # Add very faint noise floor to sound natural (amplitude ~50 out of 32768)
    samples = array.array('h', [random.randint(-50, 50) for _ in range(n_samples)])
    return samples.tobytes()

def crossfade(data_a, data_b, fade_samples=4410):
    """Simple crossfade between two byte segments (0.1s default)."""
    # Convert to sample arrays
    fmt = f'<{len(data_a)//2}h'
    fmt_b = f'<{len(data_b)//2}h'
    a = list(struct.unpack(fmt, data_a))
    b = list(struct.unpack(fmt_b, data_b))

    fade = min(fade_samples, len(a), len(b))

    # Fade out end of a, fade in start of b
    result = a[:-fade]
    for i in range(fade):
        t = i / fade
        mixed = int(a[len(a) - fade + i] * (1 - t) + b[i] * t)
        mixed = max(-32768, min(32767, mixed))
        result.append(mixed)
    result.extend(b[fade:])

    return struct.pack(f'<{len(result)}h', *result)

def pick_clips(directory, n):
    """Pick n random clips from directory."""
    files = sorted([f for f in os.listdir(directory) if f.endswith('.wav')])
    chosen = [random.choice(files) for _ in range(n)]
    return [os.path.join(directory, f) for f in chosen]

def build_segment(clip_type, duration_s):
    """Build a segment of given type and approximate duration."""
    if clip_type == "silence":
        return generate_silence(duration_s)

    clip_dir = {
        "snoring": SNORE_DIR,
        "breathing": BREATH_DIR,
        "cough": COUGH_DIR,
    }[clip_type]

    # Each ESC-50 clip is 5s, figure out how many we need
    n_clips = max(1, int(duration_s / 5))
    clips = pick_clips(clip_dir, n_clips)

    data = b''
    for clip_path in clips:
        data += read_wav_samples(clip_path)

    # Trim to exact duration
    target_bytes = int(duration_s * SAMPLE_RATE) * SAMPLE_WIDTH
    if len(data) > target_bytes:
        data = data[:target_bytes]

    return data

def main():
    print("Building 1-hour realistic sleep test file...")
    print()

    # Define the sleep session timeline
    # Realistic night: onset → light sleep → deep sleep with snoring →
    # apnea episodes → lighter snoring → quiet sleep → light waking

    segments = []

    # ============================================================
    # PHASE 1: Sleep Onset (0:00 - 8:00) - Quiet breathing
    # ============================================================
    segments.append(("breathing", 60, "Sleep onset - quiet breathing"))
    segments.append(("silence", 30, "Settling in"))
    segments.append(("breathing", 75, "Falling asleep"))
    segments.append(("silence", 40, "Deep relaxation"))
    segments.append(("breathing", 90, "Light sleep breathing"))
    segments.append(("silence", 25, "Quiet"))
    segments.append(("breathing", 60, "Drifting deeper"))
    # ~6:20

    # ============================================================
    # PHASE 2: Light Sleep (8:00 - 18:00) - Occasional mild snoring
    # ============================================================
    segments.append(("breathing", 60, "Light sleep"))
    segments.append(("snoring", 30, "First mild snoring"))
    segments.append(("breathing", 45, "Returns to breathing"))
    segments.append(("silence", 20, "Brief quiet"))
    segments.append(("breathing", 40, "Breathing"))
    segments.append(("snoring", 40, "Snoring episode"))
    segments.append(("breathing", 50, "Normal breathing"))
    segments.append(("silence", 25, "Quiet period"))
    segments.append(("breathing", 45, "Breathing"))
    segments.append(("snoring", 20, "Brief snore"))
    segments.append(("breathing", 35, "Recovery"))
    segments.append(("silence", 15, "Quiet"))
    segments.append(("breathing", 50, "Steady breathing"))
    segments.append(("snoring", 25, "Another snoring bout"))
    segments.append(("breathing", 40, "Normal breathing"))
    # ~9:40

    # ============================================================
    # PHASE 3: Deep Sleep - Heavy Snoring (18:00 - 35:00)
    # ============================================================
    segments.append(("snoring", 90, "Heavy snoring begins"))
    segments.append(("breathing", 20, "Brief breathing"))
    segments.append(("snoring", 120, "Sustained heavy snoring"))
    segments.append(("silence", 10, "First apnea pause"))
    segments.append(("cough", 5, "Recovery gasp"))
    segments.append(("breathing", 35, "Post-apnea breathing"))
    segments.append(("snoring", 90, "Snoring resumes"))
    segments.append(("silence", 15, "Longer apnea pause"))
    segments.append(("cough", 5, "Recovery gasp"))
    segments.append(("breathing", 30, "Catching breath"))
    segments.append(("snoring", 75, "More snoring"))
    segments.append(("breathing", 30, "Breathing"))
    segments.append(("snoring", 100, "Heavy snoring episode"))
    segments.append(("silence", 8, "Brief pause"))
    segments.append(("snoring", 60, "Continues"))
    segments.append(("breathing", 25, "Brief rest"))
    segments.append(("snoring", 80, "Deep sleep snoring"))
    # ~13:23

    # ============================================================
    # PHASE 4: Apnea Cluster (35:00 - 48:00) - Repeated events
    # ============================================================
    # Classic OSA pattern: snore → pause → gasp → repeat
    for i in range(8):
        snore_dur = random.randint(40, 80)
        pause_dur = random.randint(6, 18)
        segments.append(("snoring", snore_dur, f"Apnea cycle {i+1} - snoring"))
        segments.append(("silence", pause_dur, f"Apnea cycle {i+1} - pause ({pause_dur}s)"))
        segments.append(("cough", 5, f"Apnea cycle {i+1} - recovery gasp"))
        segments.append(("breathing", random.randint(15, 30), f"Apnea cycle {i+1} - recovery breathing"))
    # ~14:00 of apnea cycling

    # ============================================================
    # PHASE 5: Lighter Sleep (48:00 - 55:00) - Less snoring
    # ============================================================
    segments.append(("breathing", 60, "Transitioning to lighter sleep"))
    segments.append(("silence", 30, "Quiet"))
    segments.append(("breathing", 45, "Light breathing"))
    segments.append(("snoring", 30, "Mild snoring"))
    segments.append(("breathing", 40, "Breathing"))
    segments.append(("silence", 20, "Quiet"))
    segments.append(("snoring", 25, "Brief snore"))
    segments.append(("silence", 10, "Apnea"))
    segments.append(("cough", 5, "Recovery"))
    segments.append(("breathing", 50, "Recovery breathing"))
    segments.append(("snoring", 30, "Mild snoring"))
    segments.append(("breathing", 45, "Breathing"))
    segments.append(("silence", 25, "Quiet period"))
    segments.append(("breathing", 50, "Light sleep"))
    # ~7:45

    # ============================================================
    # PHASE 6: Final Sleep (55:00 - 65:00) - Mostly quiet
    # ============================================================
    segments.append(("breathing", 80, "Deep quiet sleep"))
    segments.append(("silence", 35, "Very quiet"))
    segments.append(("breathing", 60, "Gentle breathing"))
    segments.append(("snoring", 15, "Brief mild snore"))
    segments.append(("breathing", 50, "Breathing"))
    segments.append(("silence", 20, "Quiet"))
    segments.append(("breathing", 70, "Pre-wake breathing"))
    segments.append(("snoring", 15, "Brief snore"))
    segments.append(("breathing", 55, "Waking up gradually"))
    segments.append(("silence", 15, "Final quiet"))
    segments.append(("breathing", 50, "Awake breathing"))
    # ~7:45

    # Build the audio
    total_duration = sum(s[1] for s in segments)
    print(f"Planned duration: {total_duration}s ({total_duration/60:.1f} min)")
    print(f"Total segments: {len(segments)}")
    print()

    # Count event types
    type_durations = {}
    for seg_type, dur, _ in segments:
        type_durations[seg_type] = type_durations.get(seg_type, 0) + dur

    for t, d in sorted(type_durations.items()):
        pct = d / total_duration * 100
        print(f"  {t:12s}: {d:4d}s ({d/60:.1f} min) = {pct:.1f}%")
    print()

    # Generate audio data
    all_data = b''
    for i, (seg_type, duration, desc) in enumerate(segments):
        seg_data = build_segment(seg_type, duration)

        # Crossfade with previous segment to avoid clicks
        if all_data and seg_data:
            fade = min(2205, len(all_data) // 2, len(seg_data) // 2)  # 0.05s fade
            if fade > 100:
                all_data = crossfade(all_data, seg_data, fade)
            else:
                all_data += seg_data
        else:
            all_data += seg_data

        elapsed = len(all_data) / SAMPLE_RATE / SAMPLE_WIDTH
        if i % 10 == 0 or i == len(segments) - 1:
            print(f"  [{i+1:3d}/{len(segments)}] {elapsed/60:5.1f}min  {desc}")

    # Write output WAV
    print()
    print(f"Writing {len(all_data) / SAMPLE_RATE / SAMPLE_WIDTH / 60:.1f} min to {OUT_FILE}...")

    with wave.open(OUT_FILE, 'wb') as out:
        out.setnchannels(CHANNELS)
        out.setsampwidth(SAMPLE_WIDTH)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(all_data)

    file_size = os.path.getsize(OUT_FILE)
    final_duration = len(all_data) / SAMPLE_RATE / SAMPLE_WIDTH
    print(f"Done! {file_size / 1024 / 1024:.1f} MB, {final_duration/60:.1f} min")

if __name__ == "__main__":
    main()
