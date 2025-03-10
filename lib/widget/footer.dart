import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:mobnewharvest/widget/logout.dart';
import '../utils/connectivity_service.dart' as my_connectivity_service;

class Footer extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final my_connectivity_service.ConnectivityService connectivityService;

  Footer({required this.onItemSelected, required this.selectedIndex, required this.connectivityService});

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.white,
      color: Color.fromARGB(255, 156, 39, 176),
      buttonBackgroundColor: const Color.fromARGB(255, 156, 39, 176),
      animationDuration: Duration(milliseconds: 300),
      height: 70,
      index: widget.selectedIndex,
      items: <Widget>[
        Icon(Icons.list, size: 30, color: const Color.fromARGB(255, 255, 255, 255)),
        Icon(Icons.home, size: 30, color: const Color.fromARGB(255, 255, 255, 255)),
        Icon(Icons.logout, size: 30, color: const Color.fromARGB(255, 255, 255, 255)),
      ],
      onTap: (index) {
        if (index == 2) {
          LogoutService.showLogoutDialog(context, widget.connectivityService);
        } else {
          widget.onItemSelected(index);
        }
      },
    );
  }
}