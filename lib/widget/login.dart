import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Home.dart';
import '../utils/session_manager.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  final url = Uri.parse("http://10.0.2.2/newHarvestDes/Controller/loguear.php");

  final response = await http.post(
    url,
    body: {
      'user': _userController.text,
      'pass': _passwordController.text,
    },
  );

  if (response.statusCode == 200) {
    final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
    final data = jsonDecode(responseBody);
    if (data['success'] == true) {
      // Guardar la letra en la variable global
      SessionManager.letra = data['letra'];

      // Mostrar la letra en la terminal
      print("📢 Letra obtenida: ${SessionManager.letra}");

      // Mostrar mensaje en la pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Letra: ${SessionManager.letra}")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      print("❌ Credenciales incorrectas");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario o contraseña incorrectos")),
      );
    }
  } else {
    print("⚠️ Error en la conexión");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al conectar con el servidor")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/logo.png', height: 80),
            ),
            SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _userController,
                    decoration: InputDecoration(labelText: 'Usuario:'),
                    validator: (value) => value!.isEmpty ? 'Ingrese su usuario' : null,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Contraseña:'),
                    validator: (value) => value!.isEmpty ? 'Ingrese su contraseña' : null,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith(
                        (states) => states.contains(MaterialState.pressed)
                            ? Colors.purple[300]
                            : Colors.purple,
                      ),
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      ),
                    ),
                    child: Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}