import 'package:flutter/material.dart';

class AliceAlertHelper {
  AliceAlertHelper._();

  ///Helper method used to open alarm with given title and description.
  static void showAlert(
    BuildContext context,
    String title,
    String description, {
    String firstButtonTitle = 'Accept',
    String? secondButtonTitle,
    VoidCallback? firstButtonAction,
    VoidCallback? secondButtonAction,
    Brightness? brightness,
  }) {
    final List<Widget> actions = <Widget>[];
    actions.add(
      ElevatedButton(
        child: Text(firstButtonTitle),
        onPressed: () {
          firstButtonAction?.call();

          Navigator.of(context).pop();
        },
      ),
    );
    if (secondButtonTitle != null) {
      actions.add(
        ElevatedButton(
          child: Text(secondButtonTitle),
          onPressed: () {
            if (secondButtonAction != null) {
              secondButtonAction();
            }
            Navigator.of(context).pop();
          },
        ),
      );
    }
    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return Theme(
          data: ThemeData(
            brightness: brightness ?? Brightness.light,
          ),
          child: AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: actions,
          ),
        );
      },
    );
  }
}
