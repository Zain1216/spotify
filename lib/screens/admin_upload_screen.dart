import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/firebase_service.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _minutesController = TextEditingController(text: '3');
  final _secondsController = TextEditingController(text: '30');

  PlatformFile? _pickedAudio;
  Uint8List? _audioBytes;
  PlatformFile? _pickedCover;
  Uint8List? _coverBytes;

  final _firebaseService = FirebaseService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null && !kIsWeb) {
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        setState(() {
          _pickedAudio = file;
          _audioBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error picking audio file: $e";
      });
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null && !kIsWeb) {
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        setState(() {
          _pickedCover = file;
          _coverBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error picking cover image: $e";
      });
    }
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedAudio == null || _audioBytes == null) {
      setState(() {
        _errorMessage = "Please select an audio file (MP3/WAV/M4A).";
      });
      return;
    }

    if (_pickedCover == null || _coverBytes == null) {
      setState(() {
        _errorMessage = "Please select a cover image.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = "Uploading track and artwork...";
      _errorMessage = null;
    });

    try {
      final min = int.tryParse(_minutesController.text.trim()) ?? 3;
      final sec = int.tryParse(_secondsController.text.trim()) ?? 0;
      final duration = Duration(minutes: min, seconds: sec);

      await _firebaseService.uploadSong(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        duration: duration,
        audioBytes: _audioBytes!,
        audioFileName: _pickedAudio!.name,
        coverBytes: _coverBytes!,
        coverFileName: _pickedCover!.name,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            if (progress < 0.7) {
              _statusMessage = "Uploading audio file: ${(progress * 100 / 0.7).toStringAsFixed(0)}%";
            } else {
              _statusMessage = "Uploading artwork image: ${((progress - 0.7) * 100 / 0.3).toStringAsFixed(0)}%";
            }
          });
        },
      );

      setState(() {
        _statusMessage = "Upload complete!";
        _pickedAudio = null;
        _audioBytes = null;
        _pickedCover = null;
        _coverBytes = null;
        _titleController.clear();
        _artistController.clear();
        _albumController.clear();
        _minutesController.text = '3';
        _secondsController.text = '30';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Song uploaded successfully and synced to database!"),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Upload failed: ${e.toString().replaceFirst(RegExp(r'\[.*\]\s*'), '')}";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1DB954).withOpacity(0.15),
              const Color(0xFF121212),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(36.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Title
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFF1DB954),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Admin Dashboard',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload new audio tracks directly to Firebase cloud storage.',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Song Title Field
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Song Title', Icons.title_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter song title' : null,
                    ),
                    const SizedBox(height: 20),

                    // Artist Field
                    TextFormField(
                      controller: _artistController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Artist Name', Icons.person_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter artist name' : null,
                    ),
                    const SizedBox(height: 20),

                    // Album Field
                    TextFormField(
                      controller: _albumController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Album Title', Icons.album_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter album title' : null,
                    ),
                    const SizedBox(height: 20),

                    // Duration Input Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minutesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Minutes', Icons.timer_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter minutes';
                              if (int.tryParse(value) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _secondsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Seconds', Icons.timer_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter seconds';
                              final sec = int.tryParse(value);
                              if (sec == null) return 'Must be a number';
                              if (sec < 0 || sec >= 60) return 'Must be 0-59';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // File Pickers Layout
                    Row(
                      children: [
                        // Audio Picker Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _pickAudioFile,
                                icon: const Icon(Icons.audiotrack_rounded),
                                label: const Text('Pick Audio (MP3)'),
                                style: _buildPickerButtonStyle(_pickedAudio != null),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pickedAudio != null ? _pickedAudio!.name : 'No audio file selected',
                                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Image Picker Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _pickCoverImage,
                                icon: const Icon(Icons.image_rounded),
                                label: const Text('Pick Cover Art'),
                                style: _buildPickerButtonStyle(_pickedCover != null),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pickedCover != null ? _pickedCover!.name : 'No cover image selected',
                                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cover Art Preview
                    if (_pickedCover != null && _coverBytes != null) ...[
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                            image: DecorationImage(
                              image: MemoryImage(_coverBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Progress indicators if uploading
                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage ?? 'Uploading...',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1DB954),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Main Upload Button
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadSong,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3.0,
                              ),
                            )
                          : Text(
                              'UPLOAD TRACK',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1DB954)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  ButtonStyle _buildPickerButtonStyle(bool hasFile) {
    return ElevatedButton.styleFrom(
      backgroundColor: hasFile ? const Color(0xFF1DB954).withOpacity(0.2) : Colors.white.withOpacity(0.05),
      foregroundColor: hasFile ? const Color(0xFF1DB954) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: hasFile ? const Color(0xFF1DB954) : Colors.white12,
          width: 1.0,
        ),
      ),
    );
  }
}
