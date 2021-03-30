import 'package:flutter/material.dart';
import '../services/globals.dart';

// Reusable confirm box, also used for the logout menu
class ConfirmAlertDialog extends StatelessWidget {

  // Declaring parameters
  String _title;
  String _content;
  String _first;
  String _second;
  Color _firstColor;
  Color _secondColor;
  Function _firstOnPressed;
  Function _secondOnPressed;

  ConfirmAlertDialog({String title, String content, Function firstOnPressed, Function secondOnPressed, String first = "Yes", String second = "No", Color firstColor = activeColor, Color secondColor = Colors.redAccent}){
    this._title = title;
    this._content = content;
    this._firstOnPressed = firstOnPressed;
    this._secondOnPressed = secondOnPressed;
    this._first = first;
    this._second = second;
    this._firstColor = firstColor;
    this._secondColor = secondColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: new Text(this._title),
      content: new Text(this._content),
      // Rounded borders
      shape:
      RoundedRectangleBorder(borderRadius: new BorderRadius.circular(15)),
      actions: <Widget>[
        new FlatButton(
          child: new Text(this._first),
          textColor: this._firstColor,
          onPressed: () {
            this._firstOnPressed();
          },
        ),
        new FlatButton(
          child: Text(this._second),
          textColor: this._secondColor,
          onPressed: () {
            this._secondOnPressed();
          },
        ),
      ],
    );
  }
}