import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/helper/alice_save_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/utils/alice_constants.dart';
import 'package:flutter_alice/ui/widget/alice_call_error_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_overview_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_request_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_response_widget.dart';
import 'package:collection/collection.dart';
import 'package:share_plus/share_plus.dart';

class AliceCallDetailsScreen extends StatefulWidget {
  const AliceCallDetailsScreen(this.call, this.core, {super.key});
  final AliceHttpCall call;
  final AliceCore core;

  @override
  State createState() => _AliceCallDetailsScreenState();
}

class _AliceCallDetailsScreenState extends State<AliceCallDetailsScreen> with SingleTickerProviderStateMixin {
  AliceHttpCall get call => widget.call;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget.core.brightness,
        primarySwatch: Colors.green,
      ),
      child: StreamBuilder<List<AliceHttpCall>>(
        stream: widget.core.callsSubject,
        initialData: <AliceHttpCall>[widget.call],
        builder: (BuildContext context, AsyncSnapshot<List<AliceHttpCall>> callsSnapshot) {
          if (callsSnapshot.hasData) {
            final AliceHttpCall? call = callsSnapshot.data?.firstWhereOrNull(
              (AliceHttpCall snapshotCall) => snapshotCall.id == widget.call.id,
            );
            if (call != null) {
              return _buildMainWidget();
            } else {
              return _buildErrorWidget();
            }
          } else {
            return _buildErrorWidget();
          }
        },
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: AliceConstants.lightRed,
          key: const Key('share_key'),
          onPressed: () async {
            unawaited(Share.share(await _getSharableResponseString(), subject: 'Request Details'));
          },
          child: const Icon(Icons.share),
        ),
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: AliceConstants.lightRed,
            tabs: _getTabBars(),
          ),
          title: const Text('Alice - HTTP Call Details'),
        ),
        body: TabBarView(
          children: _getTabBarViewList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(child: Text('Failed to load data'));
  }

  Future<String> _getSharableResponseString() async {
    return AliceSaveHelper.buildCallLog(widget.call);
  }

  List<Widget> _getTabBars() {
    final List<Widget> widgets = <Widget>[];
    widgets.add(const Tab(icon: Icon(Icons.info_outline), text: 'Overview'));
    widgets.add(const Tab(icon: Icon(Icons.arrow_upward), text: 'Request'));
    widgets.add(const Tab(icon: Icon(Icons.arrow_downward), text: 'Response'));
    widgets.add(
      const Tab(
        icon: Icon(Icons.warning),
        text: 'Error',
      ),
    );
    return widgets;
  }

  List<Widget> _getTabBarViewList() {
    final List<Widget> widgets = <Widget>[];
    widgets.add(AliceCallOverviewWidget(widget.call));
    widgets.add(AliceCallRequestWidget(widget.call));
    widgets.add(AliceCallResponseWidget(widget.call));
    widgets.add(AliceCallErrorWidget(widget.call));
    return widgets;
  }
}
