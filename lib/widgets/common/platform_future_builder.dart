import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PlatformFutureBuilder<T> extends StatefulWidget {
  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final String? message;
  final Widget? messageWidget;
  final Widget? loadingWidget;

  const PlatformFutureBuilder(
      {super.key,
      this.future,
      required this.builder,
      this.message,
      this.messageWidget,
      this.loadingWidget});

  @override
  State<PlatformFutureBuilder<T>> createState() =>
      _PlatformFutureBuilderState<T>();
}

class _PlatformFutureBuilderState<T> extends State<PlatformFutureBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.future,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingWidget ?? LoadingUtil.buildLoadingIndicator();
        }
        T? data = snapshot.data;
        if (data == null) {
          if (widget.messageWidget != null) {
            return widget.messageWidget!;
          }
          String message = widget.message ?? 'No data';
          return Center(child: CommonAutoSizeText(AppLocalizations.t(message)));
        }

        return widget.builder(context, data);
      },
    );
  }
}
