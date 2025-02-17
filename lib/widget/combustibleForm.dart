import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CombustibleForm extends StatefulWidget {
  @override
  _CombustibleFormState createState() => _CombustibleFormState();
}

class _CombustibleFormState extends State<CombustibleForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _remitoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _patenteController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  Future<void> _submitCombustible() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse("http://10.0.2.2/newHarvestDes/Controller/combustible.php");

    final response = await http.post(
      url,
      body: {
        'remito': _remitoController.text,
        'monto': _montoController.text,
        'patente': _patenteController.text,
        'fecha': _fechaController.text,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.statusCode == 200
            ? "✅ Combustible registrado correctamente"
            : "⚠️ Error al registrar combustible"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(controller: _remitoController, decoration: InputDecoration(labelText: "Número de Remito"), validator: _validateField),
            TextFormField(controller: _fechaController, decoration: InputDecoration(labelText: "Fecha"), validator: _validateField),
            TextFormField(controller: _montoController, decoration: InputDecoration(labelText: "Monto"), validator: _validateField, keyboardType: TextInputType.number),
            TextFormField(controller: _patenteController, decoration: InputDecoration(labelText: "Patente"), validator: _validateField),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitCombustible, child: Text("Enviar Combustible")),
          ],
        ),
      ),
    );
  }

  String? _validateField(String? value) => value == null || value.isEmpty ? "Campo obligatorio" : null;
}
