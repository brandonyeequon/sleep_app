import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:wav/wav.dart';

import '../models/sleep_event.dart';

class _ClassifiedFrame {
  final SleepEventType type;
  final double confidence;

  const _ClassifiedFrame({required this.type, required this.confidence});
}

class AudioAnalysisService {
  static const int _sampleRate = 16000;
  static const double _frameDuration = 0.48; // YAMNet frame duration in seconds
  static const double _confidenceThreshold = 0.15;

  // Process audio in chunks of 30 seconds to avoid memory issues
  static const int _chunkSamples = _sampleRate * 30;

  // YAMNet class indices for sleep-related sounds
  static const int _breathingIdx = 36;
  static const int _wheezeIdx = 37;
  static const int _snoringIdx = 38;
  static const int _gaspIdx = 39;
  static const int _pantIdx = 40;
  static const int _snortIdx = 41;
  static const int _coughIdx = 42;
  static const int _silenceIdx = 494;
  static const int _numClasses = 521;

  Interpreter? _interpreter;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/yamnet.tflite');
      debugPrint('AudioAnalysisService: YAMNet interpreter loaded successfully');
    } catch (e) {
      debugPrint('AudioAnalysisService: Failed to load YAMNet interpreter: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<List<SleepEvent>> analyzeFile(
    String filePath, {
    void Function(double progress, String message)? onProgress,
  }) async {
    debugPrint('AudioAnalysisService: Starting analysis of $filePath');
    onProgress?.call(0.0, 'Reading audio file...');
    await Future.delayed(Duration.zero);

    // Convert non-WAV formats to WAV first
    String wavPath = filePath;
    File? tempFile;
    if (!filePath.toLowerCase().endsWith('.wav')) {
      onProgress?.call(0.02, 'Converting audio format...');
      await Future.delayed(Duration.zero);
      final converted = await _convertToWav(filePath);
      if (converted == null) {
        debugPrint('AudioAnalysisService: Failed to convert file to WAV');
        return [];
      }
      wavPath = converted;
      tempFile = File(converted);
    }

    final audioData = await _readAndPreprocess(wavPath);

    // Clean up temp file
    if (tempFile != null) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    if (audioData.isEmpty) {
      debugPrint('AudioAnalysisService: No audio data after preprocessing');
      return [];
    }
    debugPrint('AudioAnalysisService: Preprocessed ${audioData.length} samples '
        '(${(audioData.length / _sampleRate).toStringAsFixed(1)}s)');

    onProgress?.call(0.1, 'Running audio analysis...');
    await Future.delayed(Duration.zero);

    final classifications = await _runInference(audioData, onProgress);
    if (classifications.isEmpty) {
      debugPrint('AudioAnalysisService: No classifications produced');
      return [];
    }
    debugPrint('AudioAnalysisService: ${classifications.length} frames classified');

    onProgress?.call(0.92, 'Smoothing results...');
    await Future.delayed(Duration.zero);
    final smoothed = _smoothClassifications(classifications);

    onProgress?.call(0.95, 'Grouping events...');
    await Future.delayed(Duration.zero);
    final events = _groupIntoEvents(smoothed, DateTime.now());
    debugPrint('AudioAnalysisService: ${events.length} events grouped');

    onProgress?.call(1.0, 'Analysis complete');
    return events;
  }

  Future<Float32List> _readAndPreprocess(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('AudioAnalysisService: File does not exist: $filePath');
      return Float32List(0);
    }

    debugPrint('AudioAnalysisService: Reading file (${await file.length()} bytes)');
    final bytes = await file.readAsBytes();

    final wav = Wav.read(bytes);
    debugPrint('AudioAnalysisService: WAV: ${wav.samplesPerSecond}Hz, '
        '${wav.channels.length}ch, ${wav.channels[0].length} samples');

    // Get mono channel (average if stereo)
    final Float64List mono;
    if (wav.channels.length == 1) {
      mono = wav.channels[0];
    } else {
      mono = Float64List(wav.channels[0].length);
      for (var i = 0; i < mono.length; i++) {
        double sum = 0;
        for (var ch = 0; ch < wav.channels.length; ch++) {
          sum += wav.channels[ch][i];
        }
        mono[i] = sum / wav.channels.length;
      }
    }

    // Resample to 16kHz if needed
    final Float64List resampled;
    final srcRate = wav.samplesPerSecond;
    if (srcRate != _sampleRate) {
      resampled = _resample(mono, srcRate);
    } else {
      resampled = mono;
    }

    // Normalize to [-1, 1] and convert to Float32
    double maxVal = 0;
    for (var i = 0; i < resampled.length; i++) {
      final abs = resampled[i].abs();
      if (abs > maxVal) maxVal = abs;
    }

    final result = Float32List(resampled.length);
    if (maxVal > 0) {
      for (var i = 0; i < resampled.length; i++) {
        result[i] = (resampled[i] / maxVal).clamp(-1.0, 1.0);
      }
    }

    return result;
  }

  /// Converts MP3/M4A/AAC/etc. to 16kHz mono WAV using platform tools.
  /// Returns path to temp WAV file, or null on failure.
  Future<String?> _convertToWav(String inputPath) async {
    final tempDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = inputPath.split('.').last;
    final tempInput = '${tempDir.path}/somnix_input_$ts.$ext';
    final tempWav = '${tempDir.path}/somnix_convert_$ts.wav';

    // Copy input to temp dir so subprocess can access it (sandbox-safe)
    try {
      await File(inputPath).copy(tempInput);
    } catch (e) {
      debugPrint('AudioAnalysisService: Failed to copy input file: $e');
      return null;
    }

    ProcessResult result;

    if (Platform.isMacOS) {
      // macOS: use built-in afconvert (supports MP3, M4A, AAC, FLAC, etc.)
      result = await Process.run('afconvert', [
        '-f', 'WAVE', // output format: WAV
        '-d', 'LEI16@16000', // data format: 16-bit little-endian int at 16kHz
        '-c', '1', // mono
        tempInput,
        tempWav,
      ]);
    } else if (Platform.isLinux) {
      // Linux: try ffmpeg
      result = await Process.run('ffmpeg', [
        '-i', tempInput,
        '-ar', '16000',
        '-ac', '1',
        '-y', // overwrite
        tempWav,
      ]);
    } else {
      debugPrint('AudioAnalysisService: Audio conversion not supported on ${Platform.operatingSystem}');
      try { await File(tempInput).delete(); } catch (_) {}
      return null;
    }

    // Clean up temp input copy
    try { await File(tempInput).delete(); } catch (_) {}

    if (result.exitCode != 0) {
      debugPrint('AudioAnalysisService: Conversion failed (exit ${result.exitCode})');
      debugPrint('  stderr: ${result.stderr}');
      return null;
    }

    if (!await File(tempWav).exists()) {
      debugPrint('AudioAnalysisService: Converted file not found at $tempWav');
      return null;
    }

    debugPrint('AudioAnalysisService: Converted to WAV at $tempWav');
    return tempWav;
  }

  Float64List _resample(Float64List samples, int srcRate) {
    final ratio = srcRate / _sampleRate;
    final newLength = (samples.length / ratio).floor();
    final result = Float64List(newLength);

    for (var i = 0; i < newLength; i++) {
      final srcPos = i * ratio;
      final srcIdx = srcPos.floor();
      final frac = srcPos - srcIdx;

      if (srcIdx + 1 < samples.length) {
        result[i] = samples[srcIdx] * (1 - frac) + samples[srcIdx + 1] * frac;
      } else {
        result[i] = samples[srcIdx];
      }
    }

    return result;
  }

  Future<List<_ClassifiedFrame>> _runInference(
    Float32List audio,
    void Function(double progress, String message)? onProgress,
  ) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      debugPrint('AudioAnalysisService: Interpreter is null');
      return [];
    }

    final totalChunks = (audio.length / _chunkSamples).ceil();
    final allFrames = <_ClassifiedFrame>[];

    debugPrint('AudioAnalysisService: Processing $totalChunks chunks');

    for (var chunkIdx = 0; chunkIdx < totalChunks; chunkIdx++) {
      final start = chunkIdx * _chunkSamples;
      final end = min(start + _chunkSamples, audio.length);
      final chunkLength = end - start;

      // Need at least ~0.975s of audio for YAMNet to produce a frame
      if (chunkLength < (_sampleRate * 0.975).round()) break;

      final chunk = Float32List.sublistView(audio, start, end);

      // Resize input tensor to match chunk length
      interpreter.resizeInputTensor(0, [chunkLength]);
      interpreter.allocateTensors();

      // Set input and invoke — use runInference to avoid copyTo shape issues
      // (YAMNet output shapes are dynamic and not known until after invoke)
      interpreter.runInference([chunk]);

      // Read output tensor data directly after inference
      final scoresTensor = interpreter.getOutputTensor(0);
      final actualShape = scoresTensor.shape;
      final numFrames = actualShape[0];

      // Read raw bytes and interpret as Float32
      final rawBytes = Uint8List.fromList(scoresTensor.data);
      final allScores = rawBytes.buffer.asFloat32List();

      debugPrint('AudioAnalysisService: Chunk $chunkIdx → $numFrames frames (shape: $actualShape)');

      // Classify each frame
      for (var f = 0; f < numFrames; f++) {
        final frameScores = Float32List.fromList(
          allScores.sublist(f * _numClasses, (f + 1) * _numClasses),
        );

        final prevType = allFrames.isNotEmpty
            ? allFrames.last.type
            : SleepEventType.normalBreathing;
        allFrames.add(_classifyFrame(frameScores, prevType));
      }

      // Report progress
      if (onProgress != null) {
        final progress = 0.1 + ((chunkIdx + 1) / totalChunks) * 0.8;
        final processedSeconds = (end / _sampleRate).round();
        final totalSeconds = (audio.length / _sampleRate).round();
        onProgress(
          progress,
          'Analyzing audio... ${_formatDuration(processedSeconds)} / ${_formatDuration(totalSeconds)}',
        );
      }
      // Yield for UI updates
      await Future.delayed(Duration.zero);
    }

    return allFrames;
  }

  // Lower thresholds for specific events — snoring co-occurs with breathing
  // in YAMNet's class hierarchy, so it needs priority-based detection
  static const double _snoringThreshold = 0.05;
  static const double _gaspThreshold = 0.08;

  _ClassifiedFrame _classifyFrame(Float32List scores, SleepEventType prevType) {
    // Extract scores for sleep-related classes
    final snoringScore = max(scores[_snoringIdx], scores[_snortIdx]);
    final gaspScore =
        [scores[_gaspIdx], scores[_pantIdx], scores[_coughIdx]].reduce(max);
    final silenceScore = scores[_silenceIdx];
    final breathingScore = max(scores[_breathingIdx], scores[_wheezeIdx]);

    // Priority-based classification: specific events override generic breathing
    // because YAMNet's "Breathing" is a parent class that always fires when
    // snoring/gasping occurs

    // 1. Snoring takes priority (always co-occurs with high breathing scores)
    if (snoringScore > _snoringThreshold && snoringScore > gaspScore) {
      return _ClassifiedFrame(
        type: SleepEventType.snoring,
        confidence: snoringScore,
      );
    }

    // 2. Gasp / cough / pant
    if (gaspScore > _gaspThreshold) {
      return _ClassifiedFrame(
        type: SleepEventType.recoveryGasp,
        confidence: gaspScore,
      );
    }

    // 3. Silence — contextual: pause if it follows snoring (potential apnea)
    if (silenceScore > _confidenceThreshold && silenceScore > breathingScore) {
      if (prevType == SleepEventType.snoring ||
          prevType == SleepEventType.pauseEvent) {
        return _ClassifiedFrame(
          type: SleepEventType.pauseEvent,
          confidence: silenceScore,
        );
      }
    }

    // 4. Default: normal breathing
    return _ClassifiedFrame(
      type: SleepEventType.normalBreathing,
      confidence: breathingScore,
    );
  }

  List<_ClassifiedFrame> _smoothClassifications(List<_ClassifiedFrame> raw) {
    if (raw.length < 5) return raw;

    final smoothed = <_ClassifiedFrame>[];
    const windowRadius = 2; // window of 5 = 2 on each side

    for (var i = 0; i < raw.length; i++) {
      final start = max(0, i - windowRadius);
      final end = min(raw.length, i + windowRadius + 1);

      final counts = <SleepEventType, int>{};
      double totalConfidence = 0;
      for (var j = start; j < end; j++) {
        counts[raw[j].type] = (counts[raw[j].type] ?? 0) + 1;
        totalConfidence += raw[j].confidence;
      }

      SleepEventType majorityType = raw[i].type;
      int maxCount = 0;
      for (final entry in counts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          majorityType = entry.key;
        }
      }

      smoothed.add(_ClassifiedFrame(
        type: majorityType,
        confidence: totalConfidence / (end - start),
      ));
    }

    return smoothed;
  }

  List<SleepEvent> _groupIntoEvents(
    List<_ClassifiedFrame> classified,
    DateTime startTime,
  ) {
    if (classified.isEmpty) return [];

    final frameDurationMs = (_frameDuration * 1000).round();
    final events = <SleepEvent>[];
    var currentType = classified.first.type;
    var groupStart = 0;
    double confidenceSum = classified.first.confidence;
    int count = 1;

    for (var i = 1; i < classified.length; i++) {
      if (classified[i].type != currentType) {
        final eventStart = startTime.add(Duration(
          milliseconds: groupStart * frameDurationMs,
        ));
        final eventDuration = Duration(
          milliseconds: (i - groupStart) * frameDurationMs,
        );

        events.add(SleepEvent(
          timestamp: eventStart,
          duration: eventDuration,
          type: currentType,
          confidence: confidenceSum / count,
        ));

        currentType = classified[i].type;
        groupStart = i;
        confidenceSum = classified[i].confidence;
        count = 1;
      } else {
        confidenceSum += classified[i].confidence;
        count++;
      }
    }

    // Emit final group
    final eventStart = startTime.add(Duration(
      milliseconds: groupStart * frameDurationMs,
    ));
    final eventDuration = Duration(
      milliseconds: (classified.length - groupStart) * frameDurationMs,
    );

    events.add(SleepEvent(
      timestamp: eventStart,
      duration: eventDuration,
      type: currentType,
      confidence: confidenceSum / count,
    ));

    return events;
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
