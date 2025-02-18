import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    final url = Uri.parse("http://10.0.2.2/newHarvestDes/Model/guardar_combustible.php");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_remito': remitoController.text,
        'monto': montoController.text,
        'patente': patenteController.text,
        'fecha': fechaController.text,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
      final responseBodyJson = jsonDecode(responseBody);

      if (responseBodyJson['status'] == 'success') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Éxito'),
              content: Text(responseBodyJson['message']),
              actions: <Widget>[
                TextButton(
                  child: Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error al guardar el combustible: ${responseBodyJson['message']}'),
              actions: <Widget>[
                TextButton(
                  child: Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error al enviar el combustible: ${response.body}'),
            actions: <Widget>[
              TextButton(
                child: Text('Aceptar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: remitoController,
              decoration: InputDecoration(
                labelText: "Número de Remito",
                prefixIcon: Icon(Icons.receipt),
              ),
              validator: _validateField,
            ),
            TextFormField(
              controller: fechaController,
              decoration: InputDecoration(
                labelText: "Fecha",
                prefixIcon: Icon(Icons.calendar_month),
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
              validator: _validateField,
            ),
            TextFormField(
              controller: montoController,
              decoration: InputDecoration(
                labelText: "Monto",
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: _validateField,
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: patenteController,
              decoration: InputDecoration(
                labelText: "Patente",
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: _validateField,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _clearForm,
                  child: Text("Limpiar"),
                ),
                ElevatedButton(
                  onPressed: _submitCombustible,
                  child: Text("Enviar Combustible"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateField(String? value) {
    return (value == null || value.isEmpty) ? 'Campo obligatorio' : null;
  }
}