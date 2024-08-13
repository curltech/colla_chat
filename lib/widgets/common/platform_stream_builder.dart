import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PlatformStreamBuilder<T> extends StatelessWidget {
  final Stream<T>? stream;
  final Widget Function(BuildContext context, T data) builder;
  final String? message;
  final Widget? messageWidget;
  final Widget? loadingWidget;

  const PlatformStreamBuilder(
      {super.key,
      this.stream,
      required this.builder,
      this.message,
      this.messageWidget,
      this.loadingWidget});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingWidget ?? LoadingUtil.buildLoadingIndicator();
        }
        T? data = snapshot.data;
        if (data == null) {
          if (messageWidget != null) {
            return messageWidget!;
          }
          String message = this.message ?? 'No data';
          return Center(child: CommonAutoSizeText(AppLocalizations.t(message)));
        }

        return builder(context, data);
      },
    );
  }
}
