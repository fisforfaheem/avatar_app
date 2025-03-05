import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioUploader extends StatefulWidget {
  final Function(String name, String audioPath, Duration duration) onUpload;

  const AudioUploader({
    super.key,
    required this.onUpload,
  });

  @override
  State<AudioUploader> createState() => _AudioUploaderState();
}

class _AudioUploaderState extends State<AudioUploader> {
  final _nameController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  final _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  String? _errorMessage;
  String? _tempFilePath;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  void _cleanupTempFile() {
    if (_tempFilePath != null) {
      try {
        File(_tempFilePath!).deleteSync();
        _tempFilePath = null;
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return;
      }

      final file = result.files.first;

      // Verify file size (limit to 10MB)
      if (file.size > 10 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'File size must be less than 10MB';
        });
        return;
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path,
          'temp_${DateTime.now().millisecondsSinceEpoch}_${file.name}'));

      // Write the file data
      if (file.bytes != null) {
        await tempFile.writeAsBytes(file.bytes!);
      } else if (file.path != null) {
        await File(file.path!).copy(tempFile.path);
      } else {
        throw Exception('No file data available');
      }

      _cleanupTempFile();
      _tempFilePath = tempFile.path;

      setState(() {
        _selectedFile = file;
      });

      // Get audio duration
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(DeviceFileSource(tempFile.path));

        // Wait for duration to be set via listener
        await Future.delayed(const Duration(milliseconds: 500));

        if (_duration == Duration.zero) {
          setState(() {
            _errorMessage = 'Could not determine audio duration';
            _selectedFile = null;
          });
          return;
        }

        // Limit duration to 5 minutes
        if (_duration.inMinutes > 5) {
          setState(() {
            _errorMessage = 'Audio must be shorter than 5 minutes';
            _selectedFile = null;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error loading audio: $e');
        setState(() {
          _errorMessage = 'Error loading audio file. Please try another file.';
          _selectedFile = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      setState(() {
        _errorMessage = 'Error selecting file. Please try again.';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty || _selectedFile == null) {
      setState(() {
        _errorMessage = 'Please provide both a name and an audio file';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('App documents directory: ${appDir.path}');

      // Create a voices subdirectory if it doesn't exist
      final voicesDir = Directory(path.join(appDir.path, 'voices'));
      if (!await voicesDir.exists()) {
        await voicesDir.create(recursive: true);
      }
      debugPrint('Voices directory: ${voicesDir.path}');

      // Generate unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      final savedFile = File(path.join(voicesDir.path, fileName));
      debugPrint('Saving file to: ${savedFile.path}');

      // Copy the file from temp location
      if (_tempFilePath != null) {
        await File(_tempFilePath!).copy(savedFile.path);
        debugPrint('File copied successfully');
      } else {
        throw Exception('No temporary file available');
      }

      if (mounted) {
        widget.onUpload(
          _nameController.text.trim(),
          savedFile.path,
          _duration,
        );

        // Reset form
        setState(() {
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving file. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _handleCancel() {
    setState(() {
      _nameController.clear();
      _selectedFile = null;
      _duration = Duration.zero;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
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
          Text(
            'Add New Voice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Voice Name',
              hintText: 'e.g., Happy Greeting, Introduction, etc.',
              border: OutlineInputBorder(),
            ),
            enabled: !_isUploading,
          ),
          const SizedBox(height: 16),
          if (_selectedFile == null)
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundDecoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  shadows: const [BoxShadow(color: Colors.transparent)],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to select an audio file',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MP3, WAV, OGG, or M4A (max 5 minutes)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.audio_file,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isUploading ? null : _handleCancel,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          if (_selectedFile != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Audio will be stored locally on your device. For better persistence, a cloud storage solution would be needed in a production environment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isUploading ? null : _handleCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isUploading ||
                        _nameController.text.trim().isEmpty ||
                        _selectedFile == null
                    ? null
                    : _handleSubmit,
                child: Text(_isUploading ? 'Adding...' : 'Add Voice'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
