import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/database_helper.dart';
import '../db/user.dart';
import '../db/combustible_dao.dart';

class CombustibleForm extends StatefulWidget {
  @override
  _CombustibleFormState createState() => _CombustibleFormState();
}

class _CombustibleFormState extends State<CombustibleForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController remitoController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  final TextEditingController patenteController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();

  String nombreChofer = '';

  @override
  void initState() {
    super.initState();
    _loadNombreChofer();
  }

  Future<void> _loadNombreChofer() async {
    User? user = await DatabaseHelper().getLoggedInUser();
    if (user != null) {
      setState(() {
        nombreChofer = user.nombre;
      });
    }
  }

  @override
  void dispose() {
    remitoController.dispose();
    montoController.dispose();
    patenteController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> _submitCombustible() async {
    if (!_formKey.currentState!.validate()) return;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // No hay conexión a Internet, guardar en la base de datos local
      final combustible = Combustible(
        id: remitoController.text,
        fecha: fechaController.text,
        monto: double.parse(montoController.text),
        patente: patenteController.text,
        nombre: nombreChofer,
      );
      await DatabaseHelper().insertCombustible(combustible);
      _showDialog('Éxito', 'Combustible guardado localmente.');
    } else {
      // Hay conexión a Internet, enviar al servidor
      final url = Uri.parse("https://newharvest.com.ar/vouchers/api/guardarCombustible.php");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_remito_c': remitoController.text,
          'monto': montoController.text,
          'patente': patenteController.text,
          'fecha': fechaController.text,
          'nombre': nombreChofer,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
        final responseBodyJson = jsonDecode(responseBody);

        if (responseBodyJson['status'] == 'success') {
          _showDialog('Éxito', responseBodyJson['message']);
        } else {
          _showDialog('Error', 'Error al guardar el combustible: ${responseBodyJson['message']}');
        }
      } else {
        _showDialog('Error', 'Error al enviar el combustible: ${response.body}');
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Éxito') {
                  _resetForm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    remitoController.clear();
    montoController.clear();
    patenteController.clear();
    fechaController.clear();
  }

  void _clearForm() {
    remitoController.clear();
    montoController.clear();
    patenteController.clear();
    fechaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: remitoController,
                      decoration: InputDecoration(
                        labelText: 'Número de Remito',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese el número de remito' : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: fechaController,
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('es', 'ES'),
                        );
                        if (pickedDate != null) {
                          String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          fechaController.text = formattedDate;
                        }
                      },
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese la fecha' : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: montoController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese el monto' : null,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: patenteController,
                      decoration: InputDecoration(
                        labelText: 'Patente',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese la patente' : null,
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _clearForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 134, 134, 134),
                            padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Limpiar',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        ElevatedButton(
                          onPressed: _submitCombustible,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 123, 31, 162),
                            padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Enviar Combustible',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40), // Espacio inferior
            ],
          ),
        ),
      ),
    );
  }

  String? _validateField(String? value) {
    return (value == null || value.isEmpty) ? 'Campo obligatorio' : null;
  }
}