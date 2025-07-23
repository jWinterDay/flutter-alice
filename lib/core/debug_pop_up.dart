import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/page/alice_stats_screen.dart';

import 'alice_core.dart';
import 'expandable_fab.dart';

class DebugPopUp extends StatefulWidget {
  ///class widget to show overlay bubble describes the number request count and is a place to navigate to alice inspector.
  ///[onClicked] call back when user clicked in debug point
  ///[callsSubscription] the stream to listen how many request in app
  const DebugPopUp({
    super.key,
    required this.onClicked,
    required this.callsSubscription,
    required this.aliceCore,
  });
  final VoidCallback onClicked;
  final Stream<List<AliceHttpCall>> callsSubscription;
  final AliceCore aliceCore;

  @override
  State createState() => _DebugPopUpState();
}

class _DebugPopUpState extends State<DebugPopUp> {
  Offset _offset = Offset.zero;
  final double _expandedDistance = 100.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Size size = MediaQuery.of(context).size;
    final double rightSide = _expandedDistance + kToolbarHeight + 20;
    _offset = Offset(
      size.width - rightSide,
      size.height / 2 - _expandedDistance,
    );
  }

  @override
  Widget build(BuildContext context) {
    //wrap with SafeArea to support edge screen
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) {
                _offset += details.delta;
                setState(() {});
              },
              child: _buildDraggyWidget(
                widget.onClicked,
                widget.callsSubscription,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggyWidget(
    VoidCallback onClicked,
    Stream<List<AliceHttpCall>> stream,
  ) {
    return ExpandableFab(
      distance: _expandedDistance,
      bigButton: Opacity(
        opacity: 0.6,
        child: FloatingActionButton(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          onPressed: onClicked,
          mini: true,
          enableFeedback: true,
          child: StreamBuilder<List<AliceHttpCall>>(
            initialData: const <AliceHttpCall>[],
            stream: stream,
            builder: (_, AsyncSnapshot<List<AliceHttpCall>> sns) {
              final int counter = min(sns.data?.length ?? 0, 99);
              return Text('$counter');
            },
          ),
        ),
      ),
      children: <Widget>[
        ActionButton(
          onPressed: () => widget.aliceCore.removeCalls(),
          icon: const Icon(Icons.delete, color: Colors.white),
        ),
        ActionButton(
          onPressed: _showStatsScreen,
          icon: const Icon(Icons.insert_chart, color: Colors.white),
        ),
      ],
    );
  }

  void _showStatsScreen() {
    unawaited(
      Navigator.push(
        widget.aliceCore.getContext()!,
        MaterialPageRoute<dynamic>(
          builder: (_) => AliceStatsScreen(widget.aliceCore),
        ),
      ),
    );
  }
}
