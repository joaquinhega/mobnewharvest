import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:mobnewharvest/widget/logout.dart';

class Footer extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  Footer({required this.onItemSelected, required this.selectedIndex});

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.white,
      color: Colors.purple,
      buttonBackgroundColor: Colors.purple,
      animationDuration: Duration(milliseconds: 300),
      height: 60,
      index: widget.selectedIndex,
      items: <Widget>[
        Icon(Icons.list, size: 30, color: Colors.black),
        Icon(Icons.home, size: 30, color: Colors.black),
        Icon(Icons.logout, size: 30, color: Colors.black),
      ],
      onTap: (index) {
        if (index == 2) {
          LogoutService.showLogoutDialog(context);
        } else {
          widget.onItemSelected(index);
        }
      },
    );
  }
}