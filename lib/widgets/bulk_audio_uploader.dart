import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/avatar.dart';

class BulkAudioUploader extends StatefulWidget {
  final Function(List<Voice> voices) onUpload;
  final String avatarColor;

  const BulkAudioUploader({
    super.key,
    required this.onUpload,
    required this.avatarColor,
  });

  @override
  State<BulkAudioUploader> createState() => _BulkAudioUploaderState();
}

class _BulkAudioUploaderState extends State<BulkAudioUploader> {
  List<PlatformFile> _selectedFiles = [];
  List<String> _tempFilePaths = [];
  List<Map<String, dynamic>> _audioDetails = [];
  bool _isUploading = false;
  String? _errorMessage;
  AudioPlayer? _audioPlayer;
  bool _isDisposed = false;
  bool _isProcessing = false;
  int _processedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _cleanupTempFiles();
    super.dispose();
  }

  void _cleanupTempFiles() {
    if (kIsWeb) return;
    for (final tempPath in _tempFilePaths) {
      try {
        final file = File(tempPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    }
    _tempFilePaths = [];
  }

  // Safe setState that checks if the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _pickFiles() async {
    try {
      _safeSetState(() {
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'mpeg'],
        withData: true,
      );

      if (_isDisposed) return;

      if (result == null || result.files.isEmpty) {
        debugPrint('No files selected');
        return;
      }

      // Clear previous selections
      _cleanupTempFiles();
      _safeSetState(() {
        _selectedFiles = [];
        _audioDetails = [];
        _processedCount = 0;
        _totalCount = result.files.length;
        _isProcessing = true;
      });

      // Create temporary directory for native platforms
      final tempDir = kIsWeb ? null : await getTemporaryDirectory();

      // Process each file
      for (final file in result.files) {
        if (_isDisposed) return;
        // Verify file size (limit to 10MB)
        if (file.size > 10 * 1024 * 1024) {
          _safeSetState(() {
            _processedCount++;
          });
          continue; // Skip this file
        }

        Uint8List? fileBytes;
        String? tempFilePath;

        if (kIsWeb) {
          fileBytes = file.bytes;
          if (fileBytes == null) {
            _safeSetState(() => _processedCount++);
            continue;
          }
        } else {
          // Create a temporary file on native
          if (tempDir == null) continue; // Should not happen on native
          final tempFile = File(
            path.join(
              tempDir.path,
              'temp_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            ),
          );

          // Write the file data
          if (file.bytes != null) {
            await tempFile.writeAsBytes(file.bytes!);
          } else if (file.path != null) {
            await File(file.path!).copy(tempFile.path);
          } else {
            _safeSetState(() => _processedCount++);
            continue; // Skip if no data
          }
          fileBytes = await tempFile.readAsBytes();

          if (_isDisposed) {
            try {
              if (tempFile.existsSync()) tempFile.deleteSync();
            } catch (e) {
              debugPrint('Error cleaning up temp file: $e');
            }
            return;
          }
          tempFilePath = tempFile.path;
          _tempFilePaths.add(tempFilePath);
        }

        // Get audio duration
        try {
          if (_audioPlayer == null) _initAudioPlayer();
          await _audioPlayer?.stop();

          if (kIsWeb) {
            await _audioPlayer?.setSource(BytesSource(fileBytes));
          } else {
            await _audioPlayer?.setSource(DeviceFileSource(tempFilePath!));
          }

          // A more robust way to get duration
          final completer = Completer<Duration>();
          final sub = _audioPlayer?.onDurationChanged.listen((d) {
            if (d > Duration.zero && !completer.isCompleted) {
              completer.complete(d);
            }
          });

          // Wait for duration with a timeout
          final duration = await completer.future.timeout(
            const Duration(seconds: 2),
            onTimeout:
                () =>
                    _audioPlayer?.getDuration().then(
                      (d) => d ?? Duration.zero,
                    ) ??
                    Future.value(Duration.zero),
          );
          sub?.cancel();

          if (_isDisposed) return;

          if (duration == Duration.zero) {
            _safeSetState(() {
              _processedCount++;
            });
            continue; // Skip this file
          }

          // Limit duration to 5 minutes
          if (duration.inMinutes > 5) {
            _safeSetState(() {
              _processedCount++;
            });
            continue; // Skip this file
          }

          // Add to selected files and details
          _safeSetState(() {
            _selectedFiles.add(file);
            _audioDetails.add({
              'file': file,
              'bytes': fileBytes, // Pass bytes for both platforms
              'duration': duration,
              'name': _generateNameFromFilename(file.name),
            });
            _processedCount++;
          });
        } catch (e) {
          debugPrint('Error loading audio: $e');
          _safeSetState(() {
            _processedCount++;
          });
        }
      }

      _safeSetState(() {
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (!_isDisposed) {
        _safeSetState(() {
          _errorMessage = 'Error selecting files. Please try again.';
          _isProcessing = false;
        });
      }
    }
  }

  String _generateNameFromFilename(String filename) {
    // Remove extension
    final nameWithoutExt = filename.split('.').first;

    // Replace underscores and hyphens with spaces
    final nameWithSpaces = nameWithoutExt.replaceAll(RegExp(r'[_-]'), ' ');

    // Capitalize first letter of each word
    final words = nameWithSpaces.split(' ');
    final capitalizedWords =
        words.map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).toList();

    return capitalizedWords.join(' ');
  }

  Future<void> _handleSubmit() async {
    if (_audioDetails.isEmpty) {
      _safeSetState(() {
        _errorMessage = 'Please select at least one valid audio file';
        return;
      });
      return;
    }

    _safeSetState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      List<Voice> voicesToUpload = [];
      for (final detail in _audioDetails) {
        final duration = detail['duration'] as Duration;
        final name = detail['name'] as String;
        final bytes = detail['bytes'] as Uint8List;

        final voice = Voice(
          name: name,
          audioUrl:
              'placeholder', // Will be replaced by the provider after saving
          duration: duration,
          audioBytes: bytes, // Pass the bytes to be saved
        );
        voicesToUpload.add(voice);
      }

      // Pass the list of voices to the callback.
      widget.onUpload(voicesToUpload);

      _safeSetState(() {
        _isUploading = false;
        _selectedFiles.clear();
        _audioDetails.clear();
        _cleanupTempFiles();
      });
    } catch (e) {
      debugPrint('Error during bulk upload submission: $e');
      if (!_isDisposed) {
        _safeSetState(() {
          _errorMessage = 'Error preparing files for upload. Please try again.';
          _isUploading = false;
        });
      }
    }
  }

  void _handleCancel() {
    _safeSetState(() {
      _selectedFiles = [];
      _audioDetails = [];
      _errorMessage = null;
    });
    _cleanupTempFiles();
  }

  void _removeAudio(int index) {
    _safeSetState(() {
      final tempPath = _audioDetails[index]['tempPath'] as String;
      try {
        final file = File(tempPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _tempFilePaths.remove(tempPath);
      } catch (e) {
        debugPrint('Error removing temp file: $e');
      }

      _audioDetails.removeAt(index);
    });
  }

  void _updateAudioName(int index, String newName) {
    _safeSetState(() {
      _audioDetails[index]['name'] = newName;
    });
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'blue':
        return const Color(0xFF007AFF); // iOS blue
      case 'purple':
        return const Color(0xFF5856D6); // iOS purple
      case 'pink':
        return const Color(0xFFFF2D55); // iOS pink
      case 'orange':
        return const Color(0xFFFF9500); // iOS orange
      case 'green':
        return const Color(0xFF34C759); // iOS green
      case 'teal':
        return const Color(0xFF5AC8FA); // iOS teal
      case 'red':
        return const Color(0xFFFF3B30); // iOS red
      case 'amber':
        return const Color(0xFFFFCC00); // iOS yellow
      case 'indigo':
        return const Color(0xFF5E5CE6); // iOS indigo
      case 'cyan':
        return const Color(0xFF32ADE6); // iOS cyan
      default:
        return const Color(0xFF007AFF); // Default to iOS blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color avatarColor = _getColorFromString(widget.avatarColor);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulk Upload Voices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_audioDetails.isNotEmpty)
                Text(
                  '${_audioDetails.length} files selected',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // File selection area
          if (_selectedFiles.isEmpty)
            InkWell(
              onTap: _isProcessing ? null : _pickFiles,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 125,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.05),
                  border: Border.all(color: avatarColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    _isProcessing
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                avatarColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Processing $_processedCount of $_totalCount files...',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: avatarColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click to select multiple audio files',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MP3, WAV, OGG, MPEG, or M4A (max 5 minutes each)',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
              ),
            )
          else
            Column(
              children: [
                // Selected files list
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _audioDetails.length,
                    itemBuilder: (context, index) {
                      final audioDetail = _audioDetails[index];
                      final file = audioDetail['file'] as PlatformFile;
                      final duration = audioDetail['duration'] as Duration;
                      final name = audioDetail['name'] as String;

                      return Container(
                        decoration: BoxDecoration(
                          border:
                              index < _audioDetails.length - 1
                                  ? Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  )
                                  : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: TextFormField(
                            initialValue: name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                              hintText: 'Enter voice name',
                            ),
                            onChanged:
                                (value) => _updateAudioName(index, value),
                          ),
                          subtitle: Text(
                            '${(file.size / 1024).toStringAsFixed(1)} KB • ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade300,
                              size: 20,
                            ),
                            onPressed: () => _removeAudio(index),
                            tooltip: 'Remove',
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Add more files button
                TextButton.icon(
                  onPressed: _isProcessing ? null : _pickFiles,
                  icon: Icon(Icons.add, size: 16, color: avatarColor),
                  label: Text(
                    'ADD MORE FILES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: avatarColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    backgroundColor: avatarColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedFiles.isNotEmpty)
                TextButton(
                  onPressed: _isUploading ? null : _handleCancel,
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isUploading || _isProcessing || _audioDetails.isEmpty
                        ? null
                        : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: avatarColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isUploading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'UPLOAD ${_audioDetails.length} FILES',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
