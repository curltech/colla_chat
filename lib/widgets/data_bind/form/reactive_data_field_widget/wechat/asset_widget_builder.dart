import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart'
    show AssetEntity, AssetEntityImageProvider, AssetType;

class AssetWidgetBuilder extends StatelessWidget {
  const AssetWidgetBuilder({
    super.key,
    required this.entity,
    required this.isDisplayingDetail,
  });

  final AssetEntity entity;
  final bool isDisplayingDetail;

  Widget _audioAssetWidget(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).dividerColor,
      child: Stack(
        children: <Widget>[
          AnimatedPositionedDirectional(
            duration: kThemeAnimationDuration,
            top: 0.0,
            start: 0.0,
            end: 0.0,
            bottom: isDisplayingDetail ? 20.0 : 0.0,
            child: Center(
              child: Icon(
                Icons.audiotrack,
                size: isDisplayingDetail ? 24.0 : 16.0,
              ),
            ),
          ),
          AnimatedPositionedDirectional(
            duration: kThemeAnimationDuration,
            start: 0.0,
            end: 0.0,
            bottom: isDisplayingDetail ? 0.0 : -20.0,
            height: 20.0,
            child: Text(
              entity.title ?? '',
              style: const TextStyle(height: 1.0, fontSize: 10.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageAssetWidget(BuildContext context) {
    return Image(
      image: AssetEntityImageProvider(entity, isOriginal: false),
      fit: BoxFit.cover,
    );
  }

  Widget _videoAssetWidget(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _imageAssetWidget(context)),
        ColoredBox(
          color: Theme.of(context).dividerColor..withAlpha(88),
          child: Center(
            child: Icon(
              Icons.video_library,
              color: Colors.white,
              size: isDisplayingDetail ? 24.0 : 16.0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (entity.type) {
      case AssetType.audio:
        return _audioAssetWidget(context);
      case AssetType.video:
        return _videoAssetWidget(context);
      case AssetType.image:
      case AssetType.other:
        return _imageAssetWidget(context);
    }
  }
}
