
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inventory_app/services/globals.dart';

class AppBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // All the icons in order, exported to a list type array
      items: [
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.users, size: 20),
            label: 'Students'),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.th, size: 20),
            label: 'Equipment'),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.calendarAlt, size: 20),
            label: 'Borrowed'),
      ].toList(),
      // setting the color of the active bar item
      fixedColor: activeColor,
      // setting the active bar item to the equipment one.
      currentIndex: 1,
      onTap: (int idx) {
        switch (idx) {
          case 0:
            Navigator.pushNamed(context, '/students');
            break;
          case 1:
            // Do nothing since we are in the equip screen
            break;
          case 2:
            Navigator.pushNamed(context, '/borrowed');
            break;
        }
      },
    );
  }
}