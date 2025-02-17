import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart'; // Importa la pantalla de login

class LogoutService {
  static Future<void> _logout(BuildContext context) async {
    final url = Uri.parse("http://10.0.2.2/newHarvestDes/Controller/cerrarSesion.php");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("✅ Sesión cerrada correctamente");

        // Redirigir al usuario a la pantalla de Login y eliminar Home del historial
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false, // Elimina todas las pantallas anteriores del historial
        );
      } else {
        print("⚠️ Error al cerrar sesión");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión")),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
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
              onPressed: () => Navigator.pop(context), // Cierra la alerta
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra la alerta antes de ejecutar logout
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
