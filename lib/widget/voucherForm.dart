import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart'; 
import '../db/database_helper.dart';
import '../db/user.dart';
import '../db/voucher_dao.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  String letraChofer = '';
  String? signaturePath;

  @override
  void initState() {
    super.initState();
    _loadLetraChofer();
  }

  Future<void> _loadLetraChofer() async {
    User? user = await DatabaseHelper().getLoggedInUser();
    if (user != null) {
      setState(() {
        letraChofer = user.letra;
      });
    }
  }

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
      if (_formKey.currentState!.validate()) {
        if (_signatureController.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debe firmar')),
          );
          return;
        }
        setState(() => _currentStep = 2);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<String> generarSiguienteRemito() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.none) {
      // Si no hay conexión, generar un ID temporal incremental
      String? ultimoRemito = await obtenerUltimoRemitoLocal();
      if (ultimoRemito != null) {
        int numero = int.parse(ultimoRemito) + 1;
        return numero.toString();
      } else {
        return '1'; // Comienza con 1 si no hay remitos registrados
      }
    } else {
      // Si hay conexión, obtener el último remito desde el servidor
      String? ultimoRemito = await obtenerUltimoRemito(letraChofer);
      if (ultimoRemito != null && ultimoRemito.length > 1) {
        String numeroParte = ultimoRemito.substring(1);
        if (RegExp(r'^\d+$').hasMatch(numeroParte)) {
          int numero = int.parse(numeroParte);
          String nuevoRemito = (numero + 1).toString().padLeft(3, '0');
          return letraChofer + nuevoRemito; // Devuelve la letra del chofer con el número incrementado
        } else {
          throw FormatException('Formato de remito incorrecto: $ultimoRemito');
        }
      } else {
        return letraChofer + '001';
      }
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
          if (data != null && data.containsKey('ultimo_remito')) {
            return data['ultimo_remito'];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
  }
  
  Future<String?> obtenerUltimoRemitoLocal() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'vouchers', // Asegúrate de que la tabla es 'vouchers'
        orderBy: 'id DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        final lastVoucher = result.first;
        String lastRemito = lastVoucher['id'].toString(); // Convertir a String
        return lastRemito; 
      }
      return null; // Si no hay remitos registrados, retorna null
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveSignature() async {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null) {
        await file.writeAsBytes(signatureBytes);
        setState(() {
          signaturePath = path;
        });
      }
    }

  Future<void> _submitForm() async {
      if (nombrePasajeroController.text.isEmpty) {
        return;
      }

      String siguienteRemito = await generarSiguienteRemito();

      await _saveSignature();

      final voucher = Voucher(
        id: siguienteRemito,  
        empresa: empresaController.text,
        nombrePasajero: nombrePasajeroController.text,
        origen: origenController.text,
        horaOrigen: horaOrigenController.text,
        destino: destinoController.text,
        horaDestino: horaDestinoController.text,
        fecha: fechaController.text,
        observaciones: observacionesController.text,
        tiempoEspera: tiempoEsperaController.text,
        signaturePath: signaturePath,
      );

      final voucherJson = jsonEncode(voucher.toMap());

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        try {
          await DatabaseHelper().insertVoucher(voucher);
          _showDialog('Éxito', 'Voucher guardado localmente.');
        } catch (e) {
          print('Error al guardar el voucher localmente: $e');
        }
      } else {
        final url = Uri.parse('http://10.0.2.2/newHarvestDes/api/guardarVoucher.php');

        var request = http.MultipartRequest('POST', url);
        request.fields['id_remito_v'] = voucher.id;
        request.fields['Empresa'] = voucher.empresa;
        request.fields['nombre_pasajero'] = voucher.nombrePasajero;
        request.fields['Origen'] = voucher.origen;
        request.fields['hora_origen'] = voucher.horaOrigen;
        request.fields['Destino'] = voucher.destino;
        request.fields['hora_destino'] = voucher.horaDestino;
        request.fields['Fecha'] = voucher.fecha;
        request.fields['observaciones'] = voucher.observaciones ?? '';
        request.fields['tiempo_espera'] = voucher.tiempoEspera ?? '';

        if (voucher.signaturePath != null) {
          var signatureFile = await http.MultipartFile.fromPath('signature', voucher.signaturePath!);
          request.files.add(signatureFile);
        }

        try {
          var response = await request.send();
          if (response.statusCode == 200) {
            var responseBody = await response.stream.bytesToString();
            final responseBodyJson = jsonDecode(responseBody);

            if (responseBodyJson['status'] == 'success') {
              _showDialog('Éxito', responseBodyJson['message'], reset: true);
            } else {
              _showDialog('Error', 'Error al guardar el voucher: ${responseBodyJson['message']}');
            }
          } else {
            _showDialog('Error', 'Error al enviar el voucher: ${response.reasonPhrase}');
          }
        } catch (e) {
          _showDialog('Error', 'Error de conexión: $e');
        }
      }
    }

  void _showDialog(String title, String message, {bool reset = false}) {
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
                if (reset) _resetForm(); 
              },
            ),
          ],
        );
      },
    );
  }

  void _clearAllFields() {
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

  void _resetForm() {
    _clearAllFields();
    setState(() {
      _currentStep = 0;
    });
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
                  onPressed: _clearAllFields,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 134, 134, 134),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Limpiar', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 123, 31, 162),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Siguiente', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ] else if (_currentStep == 1) ...[
            _buildStep2(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 134, 134, 134),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Volver', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _clearSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 80, 80, 80),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Limpiar Firma', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 123, 31, 162),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Siguiente', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ] else if (_currentStep == 2) ...[
            _buildStep3(),
            SizedBox(height: 20), // Margen entre la firma y los botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 134, 134, 134),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Volver', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 123, 31, 162),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16)),
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
              labelText: "Tiempo de Espera *",
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
              labelText: "Observaciones *",
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nombrePasajeroController,
            decoration: InputDecoration(
              labelText: "Nombre del Pasajero",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
          SizedBox(height: 45),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Firma: ",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 270,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Signature(controller: _signatureController, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

Widget _buildStep3() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Fecha: ${fechaController.text}"),
      Text("Origen: ${origenController.text}"),
      Text("Hora Origen: ${horaOrigenController.text}"),
      Text("Destino: ${destinoController.text}"),
      Text("Hora Destino: ${horaDestinoController.text}"),
      Text("Tiempo de Espera: ${tiempoEsperaController.text}"),
      Text("Observaciones: ${observacionesController.text}"),
      Text("Nombre del Pasajero: ${nombrePasajeroController.text}"),
      Text("Empresa: ${empresaController.text}"),
      SizedBox(height: 20),
      Container(
        height: 270,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AbsorbPointer( // Evita que se pueda editar la firma
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    ],
  );
}


  String? _validateField(String? value) {
    return (value == null || value.isEmpty) ? 'Campo obligatorio' : null;
  }
}