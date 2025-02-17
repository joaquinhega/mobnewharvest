import 'package:flutter/material.dart';
import 'package:mobnewharvest/widget/logout.dart';
class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Cargados"),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
      ],
      onTap: (index) {
        if (index == 2){
          LogoutService.showLogoutDialog(context);
        }
      }
    );
  }
}