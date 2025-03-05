import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoicePlayer extends StatefulWidget {
  final String audioPath;
  final Duration duration;

  const VoicePlayer({
    super.key,
    required this.audioPath,
    required this.duration,
  });

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  double _progress = 0.0;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VoicePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Cancel existing subscriptions
      await _positionSubscription?.cancel();
      await _playerStateSubscription?.cancel();

      // Set up the audio source
      await _player.setSource(DeviceFileSource(widget.audioPath));

      // Set up position stream
      _positionSubscription = _player.onPositionChanged.listen(
        (position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _progress = position.inMilliseconds /
                  (widget.duration.inMilliseconds == 0
                      ? 1
                      : widget.duration.inMilliseconds);
            });
          }
        },
      );

      // Set up player state stream
      _playerStateSubscription = _player.onPlayerStateChanged.listen(
        (state) {
          if (mounted) {
            setState(() {
              _isPlaying = state == PlayerState.playing;
              if (state == PlayerState.completed) {
                _currentPosition = Duration.zero;
                _progress = 0.0;
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_progress >= 1.0) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  Future<void> _seekTo(double value) async {
    try {
      final position = Duration(
        milliseconds: (widget.duration.inMilliseconds * value).round(),
      );
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
            ),
            Expanded(
              child: Slider(
                value: _progress.clamp(0.0, 1.0),
                onChanged: _seekTo,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _formatDuration(widget.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _AudioWaveform extends StatefulWidget {
  final bool isPlaying;

  const _AudioWaveform({
    required this.isPlaying,
  });

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_up,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 16,
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final value = widget.isPlaying
                      ? (1.0 +
                              sin((_controller.value * 3.14 + index * 0.5)) *
                                  0.3)
                          .clamp(0.3, 1.0)
                      : 0.3;
                  return Container(
                    width: 2,
                    height: 12 * value,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
