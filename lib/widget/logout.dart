import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import '../db/database_helper.dart';

class LogoutService {
  static Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context); 
    final scaffoldMessenger = ScaffoldMessenger.of(context); 

    final url = Uri.parse("http://10.0.2.2/newHarvestDes/Controller/cerrarSesion.php");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print("✅ Sesión cerrada correctamente");

        await DatabaseHelper().deleteUser();

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Sesión cerrada correctamente")),
        );

        await Future.delayed(Duration(seconds: 1));

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      } else {
        print("⚠️ Error al cerrar sesión");
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión")),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("No se pudo conectar al servidor")),
      );
    }
  }

  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cerrar Sesión"),
          content: Text("¿Estás seguro de que quieres cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              child: Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}