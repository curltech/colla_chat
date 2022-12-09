import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';

class PlaylistWidget extends StatefulWidget {
  final AbstractMediaPlayerController controller;
  final Function(int index, String filename)? onSelected;

  const PlaylistWidget({super.key, required this.controller, this.onSelected});

  @override
  State createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPlaylist(context);
  }

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    List<PlatformMediaSource> playlist = widget.controller.playlist;
    return Column(children: [
      Card(
        color: Colors.white.withOpacity(0.5),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16.0, top: 16.0),
              alignment: Alignment.topLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    child: const Icon(Icons.add),
                    onTap: () async {
                      await widget.controller.sourceFilePicker();
                    },
                  ),
                  InkWell(
                    child: const Icon(Icons.remove),
                    onTap: () async {
                      //await controller.remove(index);
                    },
                  )
                ],
              ),
            ),
            SizedBox(
              height: 150.0,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (int initialIndex, int finalIndex) async {
                  setState(() {
                    if (finalIndex > playlist.length) {
                      finalIndex = playlist.length;
                    }
                    if (initialIndex < finalIndex) finalIndex--;
                    widget.controller.move(initialIndex, finalIndex);
                  });
                },
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  playlist.length,
                  (int index) {
                    return ListTile(
                      key: Key(index.toString()),
                      leading: Text(
                        index.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      title: Text(
                        playlist[index].filename.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      onTap: () {
                        widget.controller.playlistVisible = false;
                        widget.controller.setCurrentIndex(index);
                        if (widget.onSelected != null) {
                          widget.onSelected!(index, playlist[index].filename);
                        }
                      },
                    );
                  },
                  growable: true,
                ),
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
    ]);
  }
}
