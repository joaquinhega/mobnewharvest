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
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
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
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
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
      final url = Uri.parse('http://10.0.2.2/newHarvestDes/api/RemitoV.php');
      final bodyData = jsonEncode({'letra_chofer': letraChofer});

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );

      if (response.statusCode == 200) {
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
        print("⚠️ Error en la respuesta del servidor: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error al obtener el último remito: $e");
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
    print("📋 Letra del chofer: $letraChofer");

    String siguienteRemito = await generarSiguienteRemito(letraChofer);
    print("📋 Siguiente remito: $siguienteRemito");

    final signatureBytes = await _signatureController.toPngBytes();
    String? signatureBase64;

    if (signatureBytes != null) {
      signatureBase64 = 'data:image/png;base64,' + base64Encode(signatureBytes);
    }

    final data = {
      'id_remito': siguienteRemito,
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

    print("📤 Enviando datos: $data");

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/newHarvestDes/api/guardarVoucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print("📥 Respuesta del servidor: ${response.body}");

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
                content: Text('Error al guardar el voucher: ${responseBodyJson['message']}'),
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
              content: Text('Error al enviar el voucher: ${response.body}'),
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

  void _clearForm() {
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
  }
@override
Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children: [
                    if (_currentStep == 0) ...[
                        _buildStep1(),
                        SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                ElevatedButton(
                                    onPressed: _clearForm,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
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
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 30),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                        ),
                                    ),
                                    child: Text('Siguiente',
                                        style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                            ],
                        ),
                    ] else if (_currentStep == 1) ...[
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
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 30),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                        ),
                                    ),
                                    child: Text('Siguiente',
                                        style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                            ],
                        ),
                    ] else if (_currentStep == 2) ...[
                        _buildStep3(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                TextButton(
                                    onPressed: _previousStep,
                                    child: Text("Volver", style: TextStyle(color: Colors.blue)),
                                ),
                                ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 30),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                        ),
                                    ),
                                    child: Text('Confirmar',
                                        style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                            ],
                        ),
                    ],
                ],
            ),
        ),
    );
}
Widget _buildStep1() {
    return Form(
        key: _formKey,
        child: Column(
            children: [
                TextFormField(
                    controller: fechaController,
                    decoration: InputDecoration(
                        labelText: "Fecha",
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
                    validator: _validateField,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: empresaController,
                    decoration: InputDecoration(
                        labelText: "Empresa",
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    validator: _validateField,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: origenController,
                    decoration: InputDecoration(
                        labelText: "Origen",
                        prefixIcon: Icon(Icons.where_to_vote_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    validator: _validateField,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: horaOrigenController,
                    decoration: InputDecoration(
                        labelText: "Hora Origen",
                        prefixIcon: Icon(Icons.access_time_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    validator: _validateField,
                    keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: destinoController,
                    decoration: InputDecoration(
                        labelText: "Destino",
                        prefixIcon: Icon(Icons.where_to_vote_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    validator: _validateField,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: horaDestinoController,
                    decoration: InputDecoration(
                        labelText: "Hora Destino",
                        prefixIcon: Icon(Icons.access_time_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    validator: _validateField,
                    keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: tiempoEsperaController,
                    decoration: InputDecoration(
                        labelText: "Tiempo de Espera(min)(*)",
                        prefixIcon: Icon(Icons.watch_off),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                    keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),
                TextFormField(
                    controller: observacionesController,
                    decoration: InputDecoration(
                        labelText: "Observaciones(*)",
                        prefixIcon: Icon(Icons.subject),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ],
        ),
    );
}

Widget _buildStep2() {
    return Column(
        children: [
            TextFormField(
                controller: nombrePasajeroController,
                decoration: InputDecoration(
                    labelText: "Nombre del Pasajero",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                    ),
                ),
                validator: _validateField,
            ),
            SizedBox(height: 70),
            Container(
                height: 270,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                ),
                child: Signature(controller: _signatureController, backgroundColor: Colors.white),
            ),
        ],
    );
}

Widget _buildStep3() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text("Fecha: ${fechaController.text}"),
            Text("Empresa: ${empresaController.text}"),
            Text("Origen: ${origenController.text}"),
            Text("Hora Origen: ${horaOrigenController.text}"),
            Text("Destino: ${destinoController.text}"),
            Text("Hora Destino: ${horaDestinoController.text}"),
            Text("Tiempo de Espera: ${tiempoEsperaController.text}"),
            Text("Observaciones: ${observacionesController.text}"),
            Text("Nombre del Pasajero: ${nombrePasajeroController.text}"),
            SizedBox(height: 20),
            Container(
                height: 270,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                ),
                child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                ),
            ),
        ],
    );
}
  String? _validateField(String? value) {
    return (value == null || value.isEmpty) ? 'Campo obligatorio' : null;
  }
}