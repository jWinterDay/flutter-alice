import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/widget/alice_base_call_details_widget.dart';

class AliceCallResponseWidget extends StatefulWidget {
  const AliceCallResponseWidget(this.call, {super.key});
  final AliceHttpCall call;

  @override
  State<StatefulWidget> createState() {
    return _AliceCallResponseWidgetState();
  }
}

class _AliceCallResponseWidgetState extends AliceBaseCallDetailsWidgetState<AliceCallResponseWidget> {
  static const String _imageContentType = 'image';
  static const String _videoContentType = 'video';
  static const String _jsonContentType = 'json';
  static const String _xmlContentType = 'xml';
  static const String _textContentType = 'text';

  static const int _kLargeOutputSize = 100000;
  bool _showLargeBody = false;
  bool _showUnsupportedBody = false;

  AliceHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    if (!_call.loading) {
      rows.addAll(_buildGeneralDataRows());
      rows.addAll(_buildHeadersRows());
      rows.addAll(_buildBodyRows());

      return Container(
        padding: const EdgeInsets.all(6),
        child: ListView(children: rows),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[CircularProgressIndicator(), Text('Awaiting response...')],
        ),
      );
    }
  }

  @override
  void dispose() {
    //_betterPlayerController?.dispose();
    super.dispose();
  }

  List<Widget> _buildGeneralDataRows() {
    final List<Widget> rows = <Widget>[];
    rows.add(getListRow('Received:', _call.response!.time.toString()));
    rows.add(getListRow('Bytes received:', formatBytes(_call.response!.size)));

    final int status = _call.response!.status;
    String statusText = '$status';
    if (status == -1) {
      statusText = 'Error';
    }

    rows.add(getListRow('Status:', statusText));
    return rows;
  }

  List<Widget> _buildHeadersRows() {
    final List<Widget> rows = <Widget>[];
    final Map<String, String>? headers = _call.response!.headers;
    String headersContent = 'Headers are empty';
    if (headers != null && headers.isNotEmpty) {
      headersContent = '';
    }
    rows.add(getListRow('Headers: ', headersContent));
    if (_call.response!.headers != null) {
      _call.response!.headers!.forEach((String header, String value) {
        rows.add(getListRow('   • $header:', value));
      });
    }
    return rows;
  }

  List<Widget> _buildBodyRows() {
    final List<Widget> rows = <Widget>[];
    if (_isImageResponse()) {
      rows.addAll(_buildImageBodyRows());
    } else if (_isVideoResponse()) {
      // rows.addAll(_buildVideoBodyRows());
    } else if (_isTextResponse()) {
      if (_isLargeResponseBody()) {
        rows.addAll(_buildLargeBodyTextRows());
      } else {
        rows.addAll(_buildTextBodyRows());
      }
    } else {
      rows.addAll(_buildUnknownBodyRows());
    }

    return rows;
  }

  List<Widget> _buildImageBodyRows() {
    final List<Widget> rows = <Widget>[];
    rows.add(
      Column(
        children: <Widget>[
          const Row(
            children: <Widget>[
              Text(
                'Body: Image',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Image.network(
            _call.uri,
            fit: BoxFit.fill,
            headers: _buildRequestHeaders(),
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    return rows;
  }

  List<Widget> _buildLargeBodyTextRows() {
    final List<Widget> rows = <Widget>[];
    if (_showLargeBody) {
      return _buildTextBodyRows();
    } else {
      rows.add(getListRow('Body:', 'Too large to show (${_call.response!.body.toString().length} Bytes)'));
      rows.add(const SizedBox(height: 8));
      rows.add(
        ElevatedButton(
          child: const Text('Show body'),
          onPressed: () {
            setState(() {
              _showLargeBody = true;
            });
          },
        ),
      );
      rows.add(const SizedBox(height: 8));
      rows.add(const Text('Warning! It will take some time to render output.'));
    }
    return rows;
  }

  List<Widget> _buildTextBodyRows() {
    final List<Widget> rows = <Widget>[];
    final Map<String, String>? headers = _call.response!.headers;
    final String bodyContent = formatBody(_call.response!.body, getContentType(headers))!;
    rows.add(getListRow('Body:', bodyContent));
    return rows;
  }

  List<Widget> _buildUnknownBodyRows() {
    final List<Widget> rows = <Widget>[];
    final Map<String, String>? headers = _call.response!.headers;
    final String contentType = getContentType(headers) ?? '<unknown>';

    if (_showUnsupportedBody) {
      final String bodyContent = formatBody(_call.response!.body, getContentType(headers))!;
      rows.add(getListRow('Body:', bodyContent));
    } else {
      rows.add(
        getListRow(
            'Body:',
            'Unsupported body. Alice can render video/image/text body. '
                "Response has Content-Type: $contentType which can't be handled. "
                "If you're feeling lucky you can try button below to try render body"
                ' as text, but it may fail.'),
      );
      rows.add(
        ElevatedButton(
          child: const Text('Show unsupported body'),
          onPressed: () {
            setState(() {
              _showUnsupportedBody = true;
            });
          },
        ),
      );
    }
    return rows;
  }

  Map<String, String> _buildRequestHeaders() {
    final Map<String, String> requestHeaders = <String, String>{};
    if (_call.request?.headers != null) {
      requestHeaders.addAll(
        _call.request!.headers.map(
          (String key, dynamic value) {
            return MapEntry<String, String>(key, value.toString());
          },
        ),
      );
    }
    return requestHeaders;
  }

  bool _isImageResponse() {
    return _getContentTypeOfResponse()!.toLowerCase().contains(_imageContentType);
  }

  bool _isVideoResponse() {
    return _getContentTypeOfResponse()!.toLowerCase().contains(_videoContentType);
  }

  bool _isTextResponse() {
    final String responseContentTypeLowerCase = _getContentTypeOfResponse()!.toLowerCase();

    return responseContentTypeLowerCase.contains(_jsonContentType) ||
        responseContentTypeLowerCase.contains(_xmlContentType) ||
        responseContentTypeLowerCase.contains(_textContentType);
  }

  String? _getContentTypeOfResponse() {
    return getContentType(_call.response!.headers);
  }

  bool _isLargeResponseBody() {
    return _call.response!.body != null && _call.response!.body.toString().length > _kLargeOutputSize;
  }
}
