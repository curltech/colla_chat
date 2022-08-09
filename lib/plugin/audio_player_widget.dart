import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../l10n/localization.dart';
import '../widgets/common/app_bar_view.dart';
import '../widgets/common/widget_mixin.dart';

class AudioPlayerWidget extends StatefulWidget with TileDataMixin {
  final AudioPlayer audioPlayer;

  const AudioPlayerWidget({
    Key? key,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AudioPlayerWidgetState();
  }

  @override
  String get routeName => 'audio_player';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'AudioPlayer';
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  PlayerState? _audioPlayerState;
  Duration? _duration;
  Duration? _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get player => widget.audioPlayer;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  Widget _buildAudioPlayer(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('play_button'),
              onPressed: _isPlaying ? null : _play,
              iconSize: 48.0,
              icon: const Icon(Icons.play_arrow),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: _isPlaying ? _pause : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: _isPlaying || _isPaused ? _stop : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
              color: Colors.cyan,
            ),
          ],
        ),
        Slider(
          onChanged: (v) {
            final duration = _duration;
            if (duration == null) {
              return;
            }
            final position = v * duration.inMilliseconds;
            player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null &&
                  _duration != null &&
                  _position!.inMilliseconds > 0 &&
                  _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
                  ? _durationText
                  : '',
          style: const TextStyle(fontSize: 16.0),
        ),
        Text('State: $_audioPlayerState'),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      player.stop();
      setState(() {
        _playerState = PlayerState.stopped;
        _position = _duration;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _audioPlayerState = state;
      });
    });
  }

  Future<void> play(String url, String localFile) async {
    await player.setSource(AssetSource('sounds/coin.wav'));
    await player.setSourceUrl(url); // equivalent to setSource(UrlSource(url));
    await player
        .play(DeviceFileSource(localFile)); // will immediately start playing
    await player.setVolume(0.5);
    await player.setPlaybackRate(0.5); // half speed
  }

  Future<void> _play() async {
    final position = _position;
    if (position != null && position.inMilliseconds > 0) {
      await player.seek(position);
    }
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
      child: _buildAudioPlayer(context),
    );

    return appBarView;
  }
}
