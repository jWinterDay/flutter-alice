import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/widget/alice_base_call_details_widget.dart';

class AliceCallErrorWidget extends StatefulWidget {
  const AliceCallErrorWidget(this.call, {super.key});
  final AliceHttpCall call;

  @override
  State<StatefulWidget> createState() {
    return _AliceCallErrorWidgetState();
  }
}

class _AliceCallErrorWidgetState extends AliceBaseCallDetailsWidgetState<AliceCallErrorWidget> {
  AliceHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (_call.error != null) {
      final List<Widget> rows = <Widget>[];

      final error = _call.error!.error;
      String errorText = 'Error is empty';

      if (error != null) {
        errorText = error.toString();
      }

      final bodyContent = formatBody(_call.error!.body, getContentType(_call.error!.headers));

      rows.add(getListRow('Headers: ', ''));
      if (_call.error!.headers != null) {
        _call.error!.headers!.forEach((String header, value) {
          rows.add(getListRow('   • $header:', value.toString()));
        });
      }

      rows.add(getListRow('Error:', errorText));
      rows.add(getListRow('Status:', _call.error!.status.toString()));
      rows.add(getListRow('Body:', bodyContent ?? 'body is empty'));

      return Container(
        padding: const EdgeInsets.all(6),
        child: ListView(children: rows),
      );
    } else {
      return const Center(child: Text('Nothing to display here'));
    }
  }
}
