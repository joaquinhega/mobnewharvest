import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';

class VoucherForm extends StatefulWidget {
    @override
    _VoucherFormState createState() => _VoucherFormState();
}

class _VoucherFormState extends State<VoucherForm> {
    final _formKey = GlobalKey<FormState>();
    int _currentStep = 0;

    final TextEditingController fechaController = TextEditingController();
    final TextEditingController empresaController = TextEditingController();
    final TextEditingController origenController = TextEditingController();
    final TextEditingController horaOrigenController = TextEditingController();
    final TextEditingController destinoController = TextEditingController();
    final TextEditingController horaDestinoController = TextEditingController();
    final TextEditingController tiempoEsperaController = TextEditingController();
    final TextEditingController observacionesController = TextEditingController();
    final TextEditingController nombrePasajeroController = TextEditingController();

    final SignatureController _signatureController = SignatureController(
        penStrokeWidth: 2,
        penColor: Colors.black,
        exportBackgroundColor: Colors.white,
    );

    @override
    void dispose() {
        _signatureController.dispose();
        super.dispose();
    }

    void _clearSignature() {
        _signatureController.clear();
    }

    void _nextStep() {
        if (_currentStep == 0 && _formKey.currentState!.validate()) {
            setState(() => _currentStep = 1);
        }
    }

    void _previousStep() {
        setState(() => _currentStep = 0);
    }

    Future<String> generarSiguienteRemito(String letraChofer) async {
        String? ultimoRemito = await obtenerUltimoRemito(letraChofer);

        if (ultimoRemito != null && ultimoRemito.length > 1) {
            String numeroParte = ultimoRemito.substring(1);
            if (RegExp(r'^\d+$').hasMatch(numeroParte)) {
            int numero = int.parse(numeroParte);
            String nuevoRemito = letraChofer + (numero + 1).toString().padLeft(3, '0'); 
            
            return nuevoRemito;
            } else {
            throw FormatException('Formato de remito incorrecto: $ultimoRemito');
            }
        } else {
            return letraChofer + '001';
        }
    }

    Future<String?> obtenerUltimoRemito(String letraChofer) async {
        try {
            final url = Uri.parse('http://10.0.2.2/newHarvestDes/Model/RemitoV.php');
            final bodyData = jsonEncode({'letra_chofer': letraChofer});

            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: bodyData,
            );

            print("📥 Respuesta recibida: ${response.body}");
            print("🔢 Código de estado HTTP: ${response.statusCode}");

            if (response.statusCode == 200) {
            // Limpiar la respuesta para obtener solo el JSON
            final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
            final data = jsonDecode(responseBody);
            print("📊 Datos decodificados: $data");

            if (data != null && data.containsKey('ultimo_remito')) {
                print("✅ Último remito obtenido: ${data['ultimo_remito']}");
                return data['ultimo_remito'];
            } else {
                print("⚠️ Respuesta sin 'ultimo_remito': ${response.body}");
                return null;
            }
            } else {
            print("❌ Error HTTP: ${response.statusCode} - ${response.body}");
            return null;
            }
        } catch (e) {
            print("❌ Excepción al obtener último remito: $e");
            return null;
        }
    }

    Future<void> _submitForm() async {
        if (nombrePasajeroController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Debe ingresar el nombre del pasajero')),
            );
            return;
        }

        String letraChofer = '${SessionManager.letra}'; 
        String siguienteRemito = await generarSiguienteRemito(letraChofer);

        final signatureBytes = await _signatureController.toPngBytes();
        String? signatureBase64;

        if (signatureBytes != null) {
            signatureBase64 = 'data:image/png;base64,' + base64Encode(signatureBytes);
        }

         final data = {
            'remito': siguienteRemito,
            'fecha': fechaController.text,
            'empresa': empresaController.text,
            'origen': origenController.text,
            'hora_origen': horaOrigenController.text,
            'destino': destinoController.text,
            'hora_destino': horaDestinoController.text,
            'tiempo_espera': tiempoEsperaController.text,
            'observaciones': observacionesController.text,
            'nombre_pasajero': nombrePasajeroController.text,
            'signature': signatureBase64,
        };

        try {
            final response = await http.post(
                Uri.parse('http://10.0.2.2/newHarvestDes/Model/guardar_voucher.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
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
                                    Navigator.of(context).pop(); // Cierra el dialog
                                    _resetForm(); // Reinicia el formulario
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
                                content: Text('Error al guardar el voucher: ${responseBodyJson['message']}'),
                                actions: <Widget>[
                                    TextButton(
                                        child: Text('Aceptar'),
                                        onPressed: () {
                                            Navigator.of(context).pop(); // Cierra el dialog
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
                            content: Text('Error al enviar el voucher: ${response.body}'),
                            actions: <Widget>[
                                TextButton(
                                    child: Text('Aceptar'),
                                    onPressed: () {
                                        Navigator.of(context).pop(); // Cierra el dialog
                                    },
                                ),
                            ],
                        );
                    },
                );
            }
        } catch (e) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text('Error'),
                        content: Text('Error de conexión: $e'),
                        actions: <Widget>[
                            TextButton(
                                child: Text('Aceptar'),
                                onPressed: () {
                                    Navigator.of(context).pop(); // Cierra el dialog
                                },
                            ),
                        ],
                    );
                },
            );
        }
    }

    void _resetForm() {
        fechaController.clear();
        empresaController.clear();
        origenController.clear();
        horaOrigenController.clear();
        destinoController.clear();
        horaDestinoController.clear();
        tiempoEsperaController.clear();
        observacionesController.clear();
        nombrePasajeroController.clear();
        _signatureController.clear();

        setState(() {
            _currentStep = 0;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children: [
                    if (_currentStep == 0) ...[
                        _buildStep1(),
                        SizedBox(height: 20),
                        ElevatedButton(
                        onPressed: _nextStep,
                        child: Text("Siguiente"),
                        ),
                    ] else ...[
                        _buildStep2(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                TextButton(
                                    onPressed: _previousStep,
                                    child: Text("Volver", style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                    onPressed: _clearSignature,
                                    child: Text("Limpiar Firma", style: TextStyle(color: Colors.red)),
                                ),
                                ElevatedButton(
                                    onPressed: _submitForm,
                                    child: Text("Enviar Voucher"),
                                ),
                            ],
                        ),
                    ],
                ],
            ),
        );
    }

    Widget _buildStep1() {
        return Form(
            key: _formKey,
            child: Column(
                children: [
                    TextFormField(controller: fechaController, decoration: InputDecoration(labelText: "Fecha"), validator: _validateField),
                    TextFormField(controller: empresaController, decoration: InputDecoration(labelText: "Empresa"), validator: _validateField),
                    TextFormField(controller: origenController, decoration: InputDecoration(labelText: "Origen"), validator: _validateField),
                    TextFormField(controller: horaOrigenController, decoration: InputDecoration(labelText: "Hora Origen"), validator: _validateField),
                    TextFormField(controller: destinoController, decoration: InputDecoration(labelText: "Destino"), validator: _validateField),
                    TextFormField(controller: horaDestinoController, decoration: InputDecoration(labelText: "Hora Destino"), validator: _validateField),
                    TextFormField(controller: tiempoEsperaController, decoration: InputDecoration(labelText: "Tiempo de Espera")),
                    TextFormField(controller: observacionesController, decoration: InputDecoration(labelText: "Observaciones")),
                ],
            ),
        );
    }

    Widget _buildStep2() {
        return Column(
            children: [
                TextFormField(controller: nombrePasajeroController, decoration: InputDecoration(labelText: "Nombre del Pasajero"), validator: _validateField),
                SizedBox(height: 20),
                Container(
                    height: 200,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Signature(controller: _signatureController, backgroundColor: Colors.white),
                ),
            ],
        );
    }

    String? _validateField(String? value) {
        return (value == null || value.isEmpty) ? 'Campo obligatorio' : null;
    }
}