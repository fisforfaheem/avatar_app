import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';

class AudioUploader extends StatefulWidget {
  final Function(String name, String audioPath, Duration duration) onUpload;

  const AudioUploader({super.key, required this.onUpload});

  @override
  State<AudioUploader> createState() => _AudioUploaderState();
}

class _AudioUploaderState extends State<AudioUploader> {
  final _nameController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  AudioPlayer? _audioPlayer;
  Duration _duration = Duration.zero;
  String? _errorMessage;
  String? _tempFilePath;
  StreamSubscription? _durationSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer?.onDurationChanged.listen((
      Duration d,
    ) {
      if (!_isDisposed && mounted) {
        setState(() => _duration = d);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _durationSubscription?.cancel();
    _durationSubscription = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _cleanupTempFile();
    super.dispose();
  }

  void _cleanupTempFile() {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _tempFilePath = null;
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    }
  }

  // Safe setState that checks if the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _pickFile() async {
    try {
      _safeSetState(() {
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'mpeg'],
        withData: true,
      );

      if (_isDisposed) return;

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return;
      }

      final file = result.files.first;

      // Verify file size (limit to 10MB)
      if (file.size > 10 * 1024 * 1024) {
        _safeSetState(() {
          _errorMessage = 'File size must be less than 10MB';
        });
        return;
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
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
        throw Exception('No file data available');
      }

      if (_isDisposed) {
        // Clean up if widget was disposed during async operation
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (e) {
          debugPrint('Error cleaning up temp file: $e');
        }
        return;
      }

      _cleanupTempFile();
      _tempFilePath = tempFile.path;

      _safeSetState(() {
        _selectedFile = file;
      });

      // Get audio duration
      try {
        if (_audioPlayer == null) {
          _initAudioPlayer();
        }

        await _audioPlayer?.stop();
        await _audioPlayer?.setSource(DeviceFileSource(tempFile.path));

        // Wait for duration to be set via listener
        await Future.delayed(const Duration(milliseconds: 500));

        if (_isDisposed) return;

        if (_duration == Duration.zero) {
          _safeSetState(() {
            _errorMessage = 'Could not determine audio duration';
            _selectedFile = null;
          });
          return;
        }

        // Limit duration to 5 minutes
        if (_duration.inMinutes > 5) {
          _safeSetState(() {
            _errorMessage = 'Audio must be shorter than 5 minutes';
            _selectedFile = null;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error loading audio: $e');
        if (!_isDisposed) {
          _safeSetState(() {
            _errorMessage =
                'Error loading audio file. Please try another file.';
            _selectedFile = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (!_isDisposed) {
        _safeSetState(() {
          _errorMessage = 'Error selecting file. Please try again.';
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    // More specific error messages
    if (_nameController.text.trim().isEmpty && _selectedFile == null) {
      _safeSetState(() {
        _errorMessage = 'Please provide both a name and an audio file';
      });
      return;
    } else if (_nameController.text.trim().isEmpty) {
      _safeSetState(() {
        _errorMessage = 'Please provide a name for this voice';
      });
      return;
    } else if (_selectedFile == null) {
      _safeSetState(() {
        _errorMessage = 'Please select an audio file';
      });
      return;
    }

    _safeSetState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Get the AvatarProvider
      final avatarProvider = Provider.of<AvatarProvider>(
        context,
        listen: false,
      );

      // Generate unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

      // Get file bytes
      List<int> fileBytes;
      if (_selectedFile!.bytes != null) {
        fileBytes = _selectedFile!.bytes!;
      } else if (_tempFilePath != null) {
        fileBytes = await File(_tempFilePath!).readAsBytes();
      } else {
        throw Exception('No file data available');
      }

      // Save the file using the AvatarProvider's storage service
      final savedFilePath = await avatarProvider.saveAudioFile(
        fileName,
        fileBytes,
      );
      debugPrint('File saved to: $savedFilePath');

      if (!_isDisposed && mounted) {
        widget.onUpload(_nameController.text.trim(), savedFilePath, _duration);

        // Reset form
        _safeSetState(() {
          _nameController.clear();
          _selectedFile = null;
          _duration = Duration.zero;
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice sample has been added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _errorMessage = 'Error saving file. Please try again.';
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _handleCancel() {
    _safeSetState(() {
      _nameController.clear();
      _selectedFile = null;
      _duration = Duration.zero;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if both name and file are provided
    final bool isFormValid =
        _nameController.text.trim().isNotEmpty && _selectedFile != null;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      margin: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 150 : 200),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        border: Border.all(
          color: isDarkMode ? theme.colorScheme.outline : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Voice',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w300,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Voice Name',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              hintText: 'e.g., Happy Greeting, Introduction, etc.',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // Add error border when name is empty but file is selected
              errorBorder:
                  _selectedFile != null && _nameController.text.trim().isEmpty
                      ? OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.error),
                        borderRadius: BorderRadius.circular(12),
                      )
                      : null,
              // Show helper text when name is empty but file is selected
              helperText:
                  _selectedFile != null && _nameController.text.trim().isEmpty
                      ? 'Please enter a name for this voice'
                      : null,
              helperStyle:
                  _selectedFile != null && _nameController.text.trim().isEmpty
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
              filled: isDarkMode,
              fillColor:
                  isDarkMode ? theme.colorScheme.surfaceContainerHighest : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
            enabled: !_isUploading,
            onChanged:
                (_) => _safeSetState(() {}), // Rebuild UI when text changes
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (_selectedFile == null)
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                height: isMobile ? 100 : 150,
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5)
                          : Colors.white,
                  border: Border.all(
                    // Highlight border when name is provided but no file
                    color:
                        _nameController.text.trim().isNotEmpty
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : isDarkMode
                            ? theme.colorScheme.outline
                            : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundDecoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      // Highlight border when name is provided but no file
                      color:
                          _nameController.text.trim().isNotEmpty
                              ? theme.colorScheme.primary.withOpacity(0.5)
                              : isDarkMode
                              ? theme.colorScheme.outline
                              : Colors.grey.shade300,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  shadows: const [BoxShadow(color: Colors.transparent)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: isMobile ? 36 : 48,
                      // Highlight icon when name is provided but no file
                      color:
                          _nameController.text.trim().isNotEmpty
                              ? theme.colorScheme.primary.withOpacity(0.7)
                              : isDarkMode
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              )
                              : Colors.grey[400],
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      'Click to select an audio file',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.grey[600],
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      'MP3, WAV, OGG, MPEG, or M4A (max 5 minutes)',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7)
                                : Colors.grey[400],
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: isMobile ? 70 : 80,
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    isDarkMode
                        ? Border.all(color: theme.colorScheme.outline)
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.audio_file,
                      size: isMobile ? 14 : 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: isMobile ? 18 : 24),
                    onPressed: _isUploading ? null : _handleCancel,
                    color: theme.colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 48,
                      minHeight: isMobile ? 32 : 48,
                    ),
                  ),
                ],
              ),
            ),
          if (_errorMessage != null) ...[
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
          if (_selectedFile != null) ...[
            SizedBox(height: isMobile ? 6 : 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isMobile ? 10 : 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                SizedBox(width: isMobile ? 2 : 4),
                Expanded(
                  child: Text(
                    'Audio will be stored locally on your device.',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isUploading ? null : _handleCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 6 : 8,
                  ),
                  minimumSize: Size(isMobile ? 60 : 80, isMobile ? 32 : 36),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              FilledButton(
                onPressed: _isUploading || !isFormValid ? null : _handleSubmit,
                style: ButtonStyle(
                  // Make the button more prominent when it's enabled
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return isDarkMode
                          ? theme.colorScheme.onSurface.withOpacity(0.12)
                          : theme.disabledColor;
                    }
                    return theme.colorScheme.primary;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return isDarkMode
                          ? theme.colorScheme.onSurface.withOpacity(0.38)
                          : Colors.white70;
                    }
                    return theme.colorScheme.onPrimary;
                  }),
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                  minimumSize: WidgetStateProperty.all<Size>(
                    Size(isMobile ? 80 : 100, isMobile ? 32 : 36),
                  ),
                  elevation: WidgetStateProperty.resolveWith<double>((
                    Set<WidgetState> states,
                  ) {
                    return isDarkMode ? 4.0 : 2.0;
                  }),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isUploading ? 'Adding...' : 'Add Voice',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                    if (isFormValid && !_isUploading) ...[
                      SizedBox(width: isMobile ? 4 : 8),
                      Icon(Icons.check_circle, size: isMobile ? 14 : 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
