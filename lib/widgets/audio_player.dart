// import 'dart:math';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';

// class VoicePlayer extends StatefulWidget {
//   final String audioPath;
//   final Duration duration;

//   const VoicePlayer({
//     super.key,
//     required this.audioPath,
//     required this.duration,
//   });

//   @override
//   State<VoicePlayer> createState() => _VoicePlayerState();
// }

// class _VoicePlayerState extends State<VoicePlayer> {
//   final _player = AudioPlayer();
//   bool _isPlaying = false;
//   Duration _currentPosition = Duration.zero;
//   double _progress = 0.0;
//   StreamSubscription? _positionSubscription;
//   StreamSubscription? _playerStateSubscription;
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     // Use a microtask to ensure initialization happens after the widget is built
//     // This helps prevent threading issues
//     Future.microtask(() => _initializePlayer());
//   }

//   @override
//   void dispose() {
//     // Cancel subscriptions first to prevent callbacks after disposal
//     _cancelSubscriptions();
//     // Use a try-catch to handle any errors during disposal
//     try {
//       _player.dispose();
//     } catch (e) {
//       debugPrint('Error disposing player: $e');
//     }
//     super.dispose();
//   }

//   void _cancelSubscriptions() async {
//     try {
//       await _positionSubscription?.cancel();
//       _positionSubscription = null;
//       await _playerStateSubscription?.cancel();
//       _playerStateSubscription = null;
//     } catch (e) {
//       debugPrint('Error cancelling subscriptions: $e');
//     }
//   }

//   @override
//   void didUpdateWidget(VoicePlayer oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.audioPath != widget.audioPath) {
//       // Use a microtask to ensure initialization happens after the widget is updated
//       Future.microtask(() => _initializePlayer());
//     }
//   }

//   Future<void> _initializePlayer() async {
//     // Cancel existing subscriptions to prevent memory leaks
//     _cancelSubscriptions();

//     try {
//       // Set up the audio source
//       await _player.setSource(DeviceFileSource(widget.audioPath));

//       // Set up position stream with error handling
//       _positionSubscription = _player.onPositionChanged.listen(
//         (position) {
//           if (mounted) {
//             setState(() {
//               _currentPosition = position;
//               _progress =
//                   position.inMilliseconds /
//                   (widget.duration.inMilliseconds == 0
//                       ? 1
//                       : widget.duration.inMilliseconds);
//             });
//           }
//         },
//         onError: (error) {
//           debugPrint('Position stream error: $error');
//         },
//       );

//       // Set up player state stream with error handling
//       _playerStateSubscription = _player.onPlayerStateChanged.listen(
//         (state) {
//           if (mounted) {
//             setState(() {
//               _isPlaying = state == PlayerState.playing;
//               if (state == PlayerState.completed) {
//                 _currentPosition = Duration.zero;
//                 _progress = 0.0;
//               }
//             });
//           }
//         },
//         onError: (error) {
//           debugPrint('Player state stream error: $error');
//         },
//       );

//       // Mark as initialized
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error initializing player: $e');
//       if (mounted) {
//         setState(() {
//           _isInitialized = false;
//         });
//       }
//     }
//   }

//   Future<void> _togglePlayPause() async {
//     if (!_isInitialized) {
//       // Try to initialize again if not initialized
//       await _initializePlayer();
//       if (!_isInitialized) return;
//     }

//     try {
//       if (_isPlaying) {
//         await _player.pause();
//       } else {
//         if (_progress >= 1.0) {
//           await _player.seek(Duration.zero);
//         }
//         await _player.resume();
//       }
//     } catch (e) {
//       debugPrint('Error toggling playback: $e');
//     }
//   }

//   Future<void> _seekTo(double value) async {
//     if (!_isInitialized) return;

//     try {
//       final position = Duration(
//         milliseconds: (widget.duration.inMilliseconds * value).round(),
//       );
//       await _player.seek(position);
//     } catch (e) {
//       debugPrint('Error seeking: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Ensure the player has a defined size
//     return Container(
//       width: double.infinity,
//       constraints: const BoxConstraints(minHeight: 80),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               // Fixed size for the play button to ensure it has dimensions
//               SizedBox(
//                 width: 48,
//                 height: 48,
//                 child: IconButton(
//                   icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
//                   onPressed: _togglePlayPause,
//                 ),
//               ),
//               Expanded(
//                 child: Slider(
//                   value: _progress.clamp(0.0, 1.0),
//                   onChanged: _seekTo,
//                 ),
//               ),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _formatDuration(_currentPosition),
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//                 Text(
//                   _formatDuration(widget.duration),
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }
// }

// class _AudioWaveform extends StatefulWidget {
//   final bool isPlaying;

//   const _AudioWaveform({required this.isPlaying});

//   @override
//   State<_AudioWaveform> createState() => _AudioWaveformState();
// }

// class _AudioWaveformState extends State<_AudioWaveform>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(_AudioWaveform oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isPlaying != oldWidget.isPlaying) {
//       if (widget.isPlaying) {
//         _controller.repeat(reverse: true);
//       } else {
//         _controller.stop();
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(Icons.volume_up, size: 16, color: Colors.grey[600]),
//         const SizedBox(width: 4),
//         SizedBox(
//           width: 16,
//           height: 16,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: List.generate(
//               3,
//               (index) => AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   final value =
//                       widget.isPlaying
//                           ? (1.0 +
//                                   sin(
//                                         (_controller.value * 3.14 +
//                                             index * 0.5),
//                                       ) *
//                                       0.3)
//                               .clamp(0.3, 1.0)
//                           : 0.3;
//                   return Container(
//                     width: 2,
//                     height: 12 * value,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[600],
//                       borderRadius: BorderRadius.circular(1),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
