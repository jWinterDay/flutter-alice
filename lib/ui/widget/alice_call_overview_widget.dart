import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/widget/alice_base_call_details_widget.dart';

class AliceCallOverviewWidget extends StatefulWidget {
  const AliceCallOverviewWidget(this.call, {super.key});
  final AliceHttpCall call;

  @override
  State<StatefulWidget> createState() {
    return _AliceCallOverviewWidget();
  }
}

class _AliceCallOverviewWidget extends AliceBaseCallDetailsWidgetState<AliceCallOverviewWidget> {
  AliceHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    rows.add(getListRow('Method: ', _call.method));
    rows.add(getListRow('Server: ', _call.server));
    rows.add(getListRow('Endpoint: ', _call.endpoint));
    rows.add(getListRow('Port: ', _call.port == null ? '-' : _call.port.toString()));
    rows.add(getListRow('Started:', _call.request!.time.toString()));
    rows.add(getListRow('Finished:', _call.response!.time.toString()));
    rows.add(getListRow('Duration:', formatDuration(_call.duration)));
    rows.add(getListRow('Bytes sent:', formatBytes(_call.request!.size)));
    rows.add(getListRow('Bytes received:', formatBytes(_call.response!.size)));
    rows.add(getListRow('Client:', _call.client));
    rows.add(getListRow('Secure:', _call.secure.toString()));

    // query parameters
    final Map<String, dynamic> queryParameters = _call.request!.queryParameters;
    if (queryParameters.isNotEmpty) {
      rows.add(getListRow('Query parameters:', ''));

      for (final MapEntry<String, dynamic> entry in queryParameters.entries) {
        final String key = entry.key;
        final String value = entry.value.toString();
        rows.add(getListRow(' * $key:', value));
      }
    }

    return Container(padding: const EdgeInsets.all(6), child: ListView(children: rows));
  }
}
