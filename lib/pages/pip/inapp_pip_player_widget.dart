import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pip_player/models/pip_settings.dart';
import 'package:flutter_pip_player/pip_controller.dart';
import 'package:flutter_pip_player/pip_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mini Player Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _parentKey = GlobalKey();
  bool _isPlaying = false;

  final PipController _pipController = PipController(
    isSnaping: true,
    title: 'Custom Player',
    settings: PipSettings(
      collapsedWidth: 200,
      collapsedHeight: 120,
      expandedWidth: 350,
      expandedHeight: 280,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.indigo,
      progressBarColor: Colors.amber,
      animationDuration: Duration(milliseconds: 400),
      animationCurve: Curves.easeOutQuart,
      isReelsMode: true,
      reelsBackgroundColor: Colors.black45,
      reelsDragSensitivity: 50.0,
      reelsHeight: 100.0,
      reelsSliderColor: Colors.white,
      reelsSliderIcon: Icons.drag_handle,
      reelsSliderIconColor: Colors.black,
      reelsSliderSize: 25,
      reelsWidth: 30,
    ),
  );

  void _toggleMiniPlayer() {
    // Show the PiP player
    _pipController.show();
    // Update settings
    _pipController.updateSettings(PipSettings(
      collapsedWidth: 150,
      collapsedHeight: 200,
      expandedWidth: 350,
      expandedHeight: 280,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.indigo,
      progressBarColor: Colors.amber,
      animationDuration: Duration(milliseconds: 400),
      animationCurve: Curves.easeOutQuart,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _parentKey,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.red),
            SizedBox(width: 8),
            Text('My Video App'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
                  width: 120,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.play_arrow, size: 30),
                  ),
                ),
                title: Text('Video ${index + 1}'),
                subtitle: Text('Duration: ${2 + index} mins'),
                onTap: _toggleMiniPlayer,
              );
            },
          ),

          // Mini player
          // PiP player
          PipPlayer(
            controller: _pipController,
            content: Container(
              color: Colors.amberAccent,
            ),
            onReelsDown: () {
              log('down');
            },
            onReelsUp: () {
              log('up');
            },
            onClose: () {
              _pipController.hide();
            },
            onExpand: () {
              _pipController.expand();
            },
            onRewind: () {
              _pipController.progress - 1;
            },
            onForward: () {
              _pipController.progress + 1;
            },
            onFullscreen: () {
              /// Write logic for full screen
              /// you can navigate to other screen
            },
            onPlayPause: () {
              setState(() => _isPlaying = !_isPlaying);
            },
            onTap: () {
              /// do any action
              /// or
              _pipController.toggleExpanded();
            },
          ),
        ],
      ),
    );
  }
}