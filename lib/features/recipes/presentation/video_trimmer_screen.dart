import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final File file;

  const VideoTrimmerScreen({super.key, required this.file});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<void> _saveVideo() async {
    // Asegurar que el recorte no exceda los 10 segundos
    if ((_endValue - _startValue) > 10500) { // 10.5 seg margen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El video no puede exceder los 10 segundos. Ajuste los controles.')),
      );
      return;
    }

    setState(() => _progressVisibility = true);

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) {
        setState(() => _progressVisibility = false);
        if (outputPath != null) {
          Navigator.of(context).pop(File(outputPath));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar el video')),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recortar a 10s'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 32),
            onPressed: _progressVisibility ? null : _saveVideo,
          )
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.only(bottom: 30.0),
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Visibility(
                visible: _progressVisibility,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.red,
                ),
              ),
              Expanded(
                child: VideoViewer(trimmer: _trimmer),
              ),
              Center(
                child: TrimViewer(
                  trimmer: _trimmer,
                  viewerHeight: 60,
                  viewerWidth: MediaQuery.of(context).size.width,
                  maxVideoLength: const Duration(seconds: 10), // Limitar vista a 10 segundos máximo
                  onChangeStart: (value) => _startValue = value,
                  onChangeEnd: (value) => _endValue = value,
                  onChangePlaybackState: (value) {
                    setState(() => _isPlaying = value);
                  },
                ),
              ),
              TextButton(
                onPressed: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() => _isPlaying = playbackState);
                },
                child: _isPlaying
                    ? const Icon(Icons.pause, size: 64, color: Colors.white)
                    : const Icon(Icons.play_arrow, size: 64, color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
