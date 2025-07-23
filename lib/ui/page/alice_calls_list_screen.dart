import 'package:flutter/material.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/helper/alice_alert_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_menu_item.dart';
import 'package:flutter_alice/ui/page/alice_call_details_screen.dart';
import 'package:flutter_alice/ui/utils/alice_constants.dart';
import 'package:flutter_alice/ui/widget/alice_call_list_item_widget.dart';

import 'alice_stats_screen.dart';

class AliceCallsListScreen extends StatefulWidget {
  const AliceCallsListScreen(this._aliceCore, {super.key});
  final AliceCore _aliceCore;

  @override
  State createState() => _AliceCallsListScreenState();
}

class _AliceCallsListScreenState extends State<AliceCallsListScreen> {
  _AliceCallsListScreenState() {
    _menuItems.add(AliceMenuItem('Delete', Icons.delete));
    _menuItems.add(AliceMenuItem('Stats', Icons.insert_chart));
    _menuItems.add(AliceMenuItem('Save', Icons.save));
  }
  AliceCore get aliceCore => widget._aliceCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController = TextEditingController();
  final List<AliceMenuItem> _menuItems = <AliceMenuItem>[];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget._aliceCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
          actions: <Widget>[
            _buildSearchButton(),
            _buildMenuButton(),
          ],
        ),
        body: _buildCallsListWrapper(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: _onSearchClicked,
    );
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = '';
      }
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<AliceMenuItem>(
      onSelected: _onMenuItemSelected,
      itemBuilder: (BuildContext context) {
        return _menuItems.map((AliceMenuItem item) {
          return PopupMenuItem<AliceMenuItem>(
            value: item,
            child: Row(
              children: <Widget>[
                Icon(
                  item.iconData,
                  color: AliceConstants.lightRed,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                ),
                Text(item.title),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return const Text('Alice - Inspector');
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search http request...',
        hintStyle: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
        // border: InputBorder,
      ),
      style: const TextStyle(fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(AliceMenuItem menuItem) {
    if (menuItem.title == 'Delete') {
      _showRemoveDialog();
    }
    if (menuItem.title == 'Stats') {
      _showStatsScreen();
    }
  }

  Widget _buildCallsListWrapper() {
    return StreamBuilder<List<AliceHttpCall>>(
      stream: aliceCore.callsSubject,
      builder: (BuildContext context, AsyncSnapshot<List<AliceHttpCall>> snapshot) {
        List<AliceHttpCall> calls = snapshot.data ?? <AliceHttpCall>[];
        final String query = _queryTextEditingController.text.trim();

        if (query.isNotEmpty) {
          calls =
              calls.where((AliceHttpCall call) => call.endpoint.toLowerCase().contains(query.toLowerCase())).toList();
        }

        if (calls.isNotEmpty) {
          return _buildCallsListWidget(calls);
        } else {
          return _buildEmptyWidget();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              color: AliceConstants.orange,
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no calls to show',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '• Check if you send any http request',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '• Check your Alice configuration',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '• Check search filters',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsListWidget(List<AliceHttpCall> calls) {
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (BuildContext context, int index) {
        return AliceCallListItemWidget(
          calls[index],
          index: calls.length - index - 1,
          _onListItemClicked,
        );
      },
    );
  }

  void _onListItemClicked(AliceHttpCall call) {
    Navigator.push(
      widget._aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (BuildContext context) => AliceCallDetailsScreen(call, widget._aliceCore),
      ),
    );
  }

  void _showRemoveDialog() {
    AliceAlertHelper.showAlert(
      context,
      'Delete calls',
      'Do you want to delete http calls?',
      firstButtonTitle: 'No',
      firstButtonAction: () => <dynamic, dynamic>{},
      secondButtonTitle: 'Yes',
      secondButtonAction: _removeCalls,
    );
  }

  void _removeCalls() {
    aliceCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push(
      aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (BuildContext context) => AliceStatsScreen(widget._aliceCore),
      ),
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }
}
