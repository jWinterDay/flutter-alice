import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_form_data_file.dart';
import 'package:flutter_alice/model/alice_from_data_field.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/widget/alice_base_call_details_widget.dart';

class AliceCallRequestWidget extends StatefulWidget {
  const AliceCallRequestWidget(this.call, {super.key});
  final AliceHttpCall call;

  @override
  State<StatefulWidget> createState() {
    return _AliceCallRequestWidget();
  }
}

class _AliceCallRequestWidget extends AliceBaseCallDetailsWidgetState<AliceCallRequestWidget> {
  AliceHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    rows.add(getListRow('Started:', _call.request!.time.toString()));
    rows.add(getListRow('Bytes sent:', formatBytes(_call.request!.size)));
    rows.add(getListRow('Content type:', getContentType(_call.request!.headers)!));

    final dynamic body = _call.request!.body;
    String? bodyContent = 'Body is empty';
    if (body != null) {
      bodyContent = formatBody(body, getContentType(_call.request!.headers));
    }
    rows.add(getListRow('Body:', bodyContent!));

    final List<AliceFormDataField>? formDataFields = _call.request!.formDataFields;

    if (formDataFields?.isNotEmpty == true) {
      rows.add(getListRow('Form data fields: ', ''));
      for (final AliceFormDataField field in formDataFields!) {
        rows.add(getListRow('   • ${field.name}:', field.value));
      }
    }
    final List<AliceFormDataFile>? formDataFiles = _call.request!.formDataFiles;
    if (formDataFiles?.isNotEmpty == true) {
      rows.add(getListRow('Form data files: ', ''));
      for (final AliceFormDataFile field in formDataFiles!) {
        rows.add(getListRow('   • ${field.fileName}:', '${field.contentType} / ${field.length} B'));
      }
    }

    final Map<String, dynamic> headers = _call.request!.headers;
    String headersContent = 'Headers are empty';
    if (headers.isNotEmpty) {
      headersContent = '';
    }
    rows.add(getListRow('Headers: ', headersContent));
    if (_call.request?.headers != null) {
      _call.request!.headers.forEach((String header, dynamic value) {
        rows.add(getListRow('   • $header:', value.toString()));
      });
    }
    final Map<String, dynamic> queryParameters = _call.request!.queryParameters;
    String queryParametersContent = 'Query parameters are empty';
    if (queryParameters.isNotEmpty) {
      queryParametersContent = '';
    }
    rows.add(getListRow('Query Parameters: ', queryParametersContent));
    if (_call.request?.queryParameters != null) {
      _call.request!.queryParameters.forEach((String query, dynamic value) {
        rows.add(getListRow('   • $query:', value.toString()));
      });
    }

    return Container(
      padding: const EdgeInsets.all(6),
      child: ListView(children: rows),
    );
  }
}
