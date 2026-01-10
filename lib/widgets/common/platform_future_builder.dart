import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PlatformFutureBuilder<T> extends StatelessWidget {
  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final String? message;
  final Widget? messageWidget;
  final Widget? loadingWidget;
  final double? width;
  final double? height;

  const PlatformFutureBuilder(
      {super.key,
      this.future,
      required this.builder,
      this.message,
      this.width,
      this.height,
      this.messageWidget,
      this.loadingWidget});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingWidget ??
              LoadingUtil.buildLoadingIndicator(width: width, height: height);
        }
        T? data = snapshot.data;
        if (data == null) {
          if (messageWidget != null) {
            return messageWidget!;
          }
          String? message = this.message;
          if (message != null) {
            return Center(child: AutoSizeText(AppLocalizations.t(message)));
          }
          return nilBox;
        }

        return builder(context, data);
      },
    );
  }
}
