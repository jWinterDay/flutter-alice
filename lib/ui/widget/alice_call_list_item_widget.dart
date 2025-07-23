import 'package:flutter/material.dart';
import 'package:flutter_alice/helper/alice_conversion_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_response.dart';
import 'package:flutter_alice/ui/utils/alice_constants.dart';

class AliceCallListItemWidget extends StatelessWidget {
  const AliceCallListItemWidget(
    this.call,
    this.itemClickAction, {
    super.key,
    required this.index,
  });
  final AliceHttpCall call;
  final Function itemClickAction;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => itemClickAction(call),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('$index', style: const TextStyle(color: Colors.red)),
                const SizedBox(width: 4),

                // contnet
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildMethodAndEndpointRow(context),
                      const SizedBox(height: 4),
                      _buildCustomMethod(context),
                      const SizedBox(height: 4),
                      _buildServerRow(),
                      const SizedBox(height: 4),
                      _buildStatsRow(),
                    ],
                  ),
                ),
                _buildResponseColumn(context),
              ],
            ),
          ),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildMethodAndEndpointRow(BuildContext context) {
    final Color? textColor = _getEndpointTextColor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          call.method,
          style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(padding: EdgeInsets.only(left: 10)),
        Expanded(
          child: Text(
            call.endpoint,
            overflow: TextOverflow.ellipsis,
            // softWrap: true,
            style: TextStyle(fontSize: 16, color: textColor),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomMethod(BuildContext context) {
    final dynamic bodyMap = call.request?.body;
    if (bodyMap == null || bodyMap is! Map) {
      return const SizedBox.shrink();
    }
    final dynamic method = bodyMap['Method']?.toString();
    if (method == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            method,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildServerRow() {
    return Row(
      children: <Widget>[
        _getSecuredConnectionIcon(call.secure),
        Expanded(
          child: Text(
            call.server + (call.port == null ? '' : ':${call.port}'),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            softWrap: false,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: Text(_formatTime(call.request!.time), style: const TextStyle(fontSize: 12))),
        Flexible(
          child: Text(AliceConversionHelper.formatTime(call.duration), style: const TextStyle(fontSize: 12)),
        ),
        Flexible(
          child: Text(
            '${AliceConversionHelper.formatBytes(call.request!.size)} / '
            '${AliceConversionHelper.formatBytes(call.response!.size)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AliceConstants.grey);
  }

  String _formatTime(DateTime time) {
    return '${formatTimeUnit(time.hour)}:'
        '${formatTimeUnit(time.minute)}:'
        '${formatTimeUnit(time.second)}:'
        '${formatTimeUnit(time.millisecond)}';
  }

  String formatTimeUnit(int timeUnit) {
    return (timeUnit < 10) ? '0$timeUnit' : '$timeUnit';
  }

  Widget _buildResponseColumn(BuildContext context) {
    final List<Widget> widgets = <Widget>[];
    if (call.loading) {
      widgets.add(const Text('Loading..', style: TextStyle(fontSize: 12)));
      widgets.add(const SizedBox(height: 4));
    }
    widgets.add(
      Text(
        _getStatus(call.response!),
        style: TextStyle(
          fontSize: 16,
          color: _getStatusTextColor(context),
        ),
      ),
    );
    return SizedBox(
      width: 50,
      child: Column(
        children: widgets,
      ),
    );
  }

  Color? _getStatusTextColor(BuildContext context) {
    final int status = call.response?.status ?? 0;
    if (status == -1) {
      return AliceConstants.red;
    } else if (status < 200) {
      return Theme.of(context).textTheme.bodyMedium!.color;
    } else if (status >= 200 && status < 300) {
      return AliceConstants.green;
    } else if (status >= 300 && status < 400) {
      return AliceConstants.orange;
    } else if (status >= 400 && status < 600) {
      return AliceConstants.red;
    } else {
      return Theme.of(context).textTheme.bodyMedium!.color;
    }
  }

  Color? _getEndpointTextColor(BuildContext context) {
    if (call.loading) {
      return AliceConstants.grey;
    } else {
      return _getStatusTextColor(context);
    }
  }

  String _getStatus(AliceHttpResponse response) {
    if (response.status == -1) {
      return 'ERR';
    } else if (response.status == 0) {
      return '???';
    } else {
      return '${response.status}';
    }
  }

  Widget _getSecuredConnectionIcon(bool secure) {
    IconData iconData;
    Color iconColor;
    if (secure) {
      iconData = Icons.lock_outline;
      iconColor = AliceConstants.green;
    } else {
      iconData = Icons.lock_open;
      iconColor = AliceConstants.red;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Icon(
        iconData,
        color: iconColor,
        size: 12,
      ),
    );
  }
}
