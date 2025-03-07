import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import '../db/database_helper.dart';
import '../utils/connectivity_service.dart' as my_connectivity_service;

class LogoutService {
  static void showLogoutDialog(BuildContext context, my_connectivity_service.ConnectivityService connectivityService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cerrar sesión"),
          content: Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Cerrar sesión"),
              onPressed: () async {
                await DatabaseHelper().deleteUser();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Login(connectivityService: connectivityService)),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}