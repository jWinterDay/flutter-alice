import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_alice/helper/alice_conversion_helper.dart';
import 'package:flutter_alice/ui/utils/alice_parser.dart';

abstract class AliceBaseCallDetailsWidgetState<T extends StatefulWidget> extends State<T> {
  final JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  Widget getListRow(String name, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SelectableText(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Padding(padding: EdgeInsets.only(left: 5)),
        Flexible(
          child: SelectableText(
            value,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
        ),
      ],
    );
  }

  String formatBytes(int bytes) => AliceConversionHelper.formatBytes(bytes);

  String formatDuration(int duration) => AliceConversionHelper.formatTime(duration);

  String? formatBody(dynamic body, String? contentType) => AliceParser.formatBody(body, contentType);

  String? getContentType(Map<String, dynamic>? headers) => AliceParser.getContentType(headers);
}
