import 'package:flutter/material.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/helper/alice_conversion_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';

class AliceStatsScreen extends StatelessWidget {
  const AliceStatsScreen(this.aliceCore, {super.key});
  final AliceCore aliceCore;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: aliceCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alice - HTTP Inspector - Stats'),
        ),
        body: Container(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: _buildMainListWidgets(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainListWidgets() {
    return <Widget>[
      _getRow('Total requests:', '${_getTotalRequests()}'),
      _getRow('Pending requests:', '${_getPendingRequests()}'),
      _getRow('Success requests:', '${_getSuccessRequests()}'),
      _getRow('Redirection requests:', '${_getRedirectionRequests()}'),
      _getRow('Error requests:', '${_getErrorRequests()}'),
      _getRow('Bytes send:', AliceConversionHelper.formatBytes(_getBytesSent())),
      _getRow('Bytes received:', AliceConversionHelper.formatBytes(_getBytesReceived())),
      _getRow('Average request time:', AliceConversionHelper.formatTime(_getAverageRequestTime())),
      _getRow('Max request time:', AliceConversionHelper.formatTime(_getMaxRequestTime())),
      _getRow('Min request time:', AliceConversionHelper.formatTime(_getMinRequestTime())),
      _getRow('Get requests:', "${_getRequests("GET")} "),
      _getRow('Post requests:', "${_getRequests("POST")} "),
      _getRow('Delete requests:', "${_getRequests("DELETE")} "),
      _getRow('Put requests:', "${_getRequests("PUT")} "),
      _getRow('Patch requests:', "${_getRequests("PATCH")} "),
      _getRow('Secured requests:', '${_getSecuredRequests()}'),
      _getRow('Unsecured requests:', '${_getUnsecuredRequests()}'),
    ];
  }

  Widget _getRow(String label, String value) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: _getLabelTextStyle(),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 10),
        ),
        Text(
          value,
          style: _getValueTextStyle(),
        ),
      ],
    );
  }

  TextStyle _getLabelTextStyle() {
    return const TextStyle(fontSize: 16);
  }

  TextStyle _getValueTextStyle() {
    return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }

  int _getTotalRequests() {
    return calls.length;
  }

  int _getSuccessRequests() => calls
      .where(
          (AliceHttpCall call) => call.response != null && call.response!.status >= 200 && call.response!.status < 300)
      .toList()
      .length;

  int _getRedirectionRequests() => calls
      .where(
          (AliceHttpCall call) => call.response != null && call.response!.status >= 300 && call.response!.status < 400)
      .toList()
      .length;

  int _getErrorRequests() => calls
      .where(
          (AliceHttpCall call) => call.response != null && call.response!.status >= 400 && call.response!.status < 600)
      .toList()
      .length;

  int _getPendingRequests() => calls.where((AliceHttpCall call) => call.loading).toList().length;

  int _getBytesSent() {
    int bytes = 0;
    for (final AliceHttpCall call in calls) {
      bytes += call.request!.size;
    }
    return bytes;
  }

  int _getBytesReceived() {
    int bytes = 0;
    for (final AliceHttpCall call in calls) {
      if (call.response != null) {
        bytes += call.response!.size;
      }
    }
    return bytes;
  }

  int _getAverageRequestTime() {
    int requestTimeSum = 0;
    int requestsWithDurationCount = 0;
    for (final AliceHttpCall call in calls) {
      if (call.duration != 0) {
        requestTimeSum = call.duration;
        requestsWithDurationCount++;
      }
    }
    if (requestTimeSum == 0) {
      return 0;
    }
    return requestTimeSum ~/ requestsWithDurationCount;
  }

  int _getMaxRequestTime() {
    int maxRequestTime = 0;
    for (final AliceHttpCall call in calls) {
      if (call.duration > maxRequestTime) {
        maxRequestTime = call.duration;
      }
    }
    return maxRequestTime;
  }

  int _getMinRequestTime() {
    int minRequestTime = 10000000;
    if (calls.isEmpty) {
      minRequestTime = 0;
    } else {
      for (final AliceHttpCall call in calls) {
        if (call.duration != 0 && call.duration < minRequestTime) {
          minRequestTime = call.duration;
        }
      }
    }
    return minRequestTime;
  }

  int _getRequests(String requestType) =>
      calls.where((AliceHttpCall call) => call.method == requestType).toList().length;

  int _getSecuredRequests() => calls.where((AliceHttpCall call) => call.secure).toList().length;

  int _getUnsecuredRequests() => calls.where((AliceHttpCall call) => !call.secure).toList().length;

  List<AliceHttpCall> get calls => aliceCore.callsSubject.value;
}
