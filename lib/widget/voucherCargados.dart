import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/database_helper.dart';
import '../db/user.dart';
import '../db/voucher_dao.dart';
import '../utils/connectivity_service.dart' as my_connectivity_service;
import 'dart:async';

class VoucherCargados extends StatefulWidget {
  final my_connectivity_service.ConnectivityService connectivityService;

  VoucherCargados({required this.connectivityService});

  @override
  _VoucherCargadosState createState() => _VoucherCargadosState();
}

class _VoucherCargadosState extends State<VoucherCargados> {
  Future<List<dynamic>>? _vouchersFuture;
  Future<List<Voucher>>? _localVouchersFuture;
  int _visibleRecords = 8;
  String nombreChofer = '';
  String letraChofer = '';
  bool _showLocal = false;
  bool _isConnected = false;
  late StreamSubscription<bool> _connectivitySubscription;

@override
void initState() {
  super.initState();
  _loadChoferData();
  _connectivitySubscription = widget.connectivityService.connectionStatus.listen((isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  });
}

@override
void dispose() {
  _connectivitySubscription.cancel();
  super.dispose();
}

  Future<void> _loadChoferData() async {
    User? user = await DatabaseHelper().getLoggedInUser();
    if (user != null) {
      nombreChofer = user.username;
      letraChofer = user.letra;
      _vouchersFuture = fetchVouchers();
      _localVouchersFuture = fetchLocalVouchers();
      setState(() {});
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<List<dynamic>> fetchVouchers() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Sin conexión');
      }

      final response = await http.get(
        Uri.parse('https://newharvest.com.ar/vouchers/api/getVouchers.php'),
        headers: {
          'User': nombreChofer,
          'Letra': letraChofer,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        print(responseBody);
        return json.decode(responseBody);
      } else {
        throw Exception('Error al cargar los vouchers');
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<List<Voucher>> fetchLocalVouchers() async {
      List<Voucher> vouchers = await DatabaseHelper().getPendingVouchers();
      print('Vouchers locales obtenidos: ${vouchers.length}');
      return vouchers;
  }

  Future<void> _uploadLocalVouchers() async {
      List<Voucher> pendingVouchers = await DatabaseHelper().getPendingVouchers();
      print('Vouchers pendientes a subir: ${pendingVouchers.length}');
      for (Voucher voucher in pendingVouchers) {
          try {
              // Generar el nuevo ID en el formato X001, X002, etc.
              String nuevoId = await DatabaseHelper().generarSiguienteRemito(letraChofer);
              print('Subiendo voucher con ID local: ${voucher.id}, nuevo ID: $nuevoId');

              final url = Uri.parse("https://newharvest.com.ar/vouchers/api/guardarVoucher.php");

              var request = http.MultipartRequest('POST', url);
              request.fields['id_remito_v'] = nuevoId;
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

              var response = await request.send();

              if (response.statusCode == 200) {
                  var responseBody = await response.stream.bytesToString();
                  if (responseBody.startsWith('{')) {
                      final responseBodyJson = jsonDecode(responseBody);

                      if (responseBodyJson['status'] == 'success') {
                          // Eliminar el voucher local después de subirlo
                          await DatabaseHelper().deleteVoucher(voucher.id);
                          print('Voucher con ID local: ${voucher.id} subido y eliminado localmente.');
                      } else {
                          print('Error al guardar el voucher: ${responseBodyJson['message']}');
                      }
                  } else {
                      print('Respuesta inesperada del servidor: $responseBody');
                  }
              } else {
                  print('Error al enviar el voucher: ${response.reasonPhrase}');
              }
          } catch (e) {
              print('Error al subir el voucher: $e');
          }
      }
      setState(() {
          _localVouchersFuture = fetchLocalVouchers();
      });
  }

  Future<String> generarSiguienteRemito(String letraChofer) async {
    return await DatabaseHelper().generarSiguienteRemito(letraChofer);
  }


  Future<void> _editVoucher(dynamic voucher) async {
    final TextEditingController empresaController = TextEditingController(text: voucher['Empresa']);
    final TextEditingController pasajeroController = TextEditingController(text: voucher['nombre_pasajero']);
    final TextEditingController origenController = TextEditingController(text: voucher['Origen']);
    final TextEditingController horaOrigenController = TextEditingController(text: voucher['hora_origen']);
    final TextEditingController destinoController = TextEditingController(text: voucher['Destino']);
    final TextEditingController horaDestinoController = TextEditingController(text: voucher['hora_destino']);
    final TextEditingController fechaController = TextEditingController(text: voucher['Fecha']);
    final TextEditingController observacionesController = TextEditingController(text: voucher['observaciones']);
    final TextEditingController tiempoEsperaController = TextEditingController(text: voucher['tiempo_espera']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Voucher'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: empresaController,
                  decoration: InputDecoration(labelText: 'Empresa'),
                ),
                TextField(
                  controller: pasajeroController,
                  decoration: InputDecoration(labelText: 'Pasajero'),
                ),
                TextField(
                  controller: origenController,
                  decoration: InputDecoration(labelText: 'Origen'),
                ),
                TextField(
                  controller: horaOrigenController,
                  decoration: InputDecoration(labelText: 'Hora Origen'),
                ),
                TextField(
                  controller: destinoController,
                  decoration: InputDecoration(labelText: 'Destino'),
                ),
                TextField(
                  controller: horaDestinoController,
                  decoration: InputDecoration(labelText: 'Hora Destino'),
                ),
                TextField(
                  controller: fechaController,
                  decoration: InputDecoration(labelText: 'Fecha'),
                ),
                TextField(
                  controller: observacionesController,
                  decoration: InputDecoration(labelText: 'Observaciones'),
                ),
                TextField(
                  controller: tiempoEsperaController,
                  decoration: InputDecoration(labelText: 'Tiempo de Espera'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Guardar'),
              onPressed: () async {
                final voucherId = voucher['id_remito_v'];

                final response = await http.post(
                  Uri.parse('https://newharvest.com.ar/vouchers/api/editVoucher.php'),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'id_remito_v': voucherId,
                    'Empresa': empresaController.text,
                    'nombre_pasajero': pasajeroController.text,
                    'Origen': origenController.text,
                    'hora_origen': horaOrigenController.text,
                    'Destino': destinoController.text,
                    'hora_destino': horaDestinoController.text,
                    'Fecha': fechaController.text,
                    'observaciones': observacionesController.text,
                    'tiempo_espera': tiempoEsperaController.text,
                  }),
                );
                if (response.statusCode == 200) {
                  setState(() {
                    _vouchersFuture = fetchVouchers();
                  });
                  Navigator.of(context).pop();
                } else {
                  print('Error al editar el voucher');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteVoucher(dynamic voucher) async {
    final response = await http.post(
      Uri.parse('https://newharvest.com.ar/vouchers/api/deleteVoucher.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_remito_v': voucher['id_remito_v'],
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _vouchersFuture = fetchVouchers();
      });
    } else {
      print('Error al eliminar el voucher');
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud, color: Color.fromARGB(255, 80, 80, 80)),
          SizedBox(width: 70), 
          Switch(
            value: _showLocal,
            onChanged: (value) {
              setState(() {
                _showLocal = value;
                if (_showLocal) {
                  _localVouchersFuture = fetchLocalVouchers();
                } else {
                  _vouchersFuture = fetchVouchers();
                }
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Color.fromARGB(255, 156, 39, 176), 
            inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255), 
          ),
          SizedBox(width: 70), 
          Icon(Icons.phone_android, color: Color.fromARGB(255, 80, 80, 80)),
        ],
      ),
    ),
    body: _showLocal ? _buildLocalVouchers() : _buildServerVouchers(),
    floatingActionButton: _showLocal && _isConnected
        ? FutureBuilder<List<Voucher>>(
            future: _localVouchersFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return FloatingActionButton(
                  onPressed: _showUploadConfirmationDialog,
                  backgroundColor: Color.fromARGB(255, 156, 39, 176),
                  child: Icon(Icons.cloud_upload, color: Colors.white),
                  tooltip: 'Subir vouchers locales',
                );
              } else {
                return Container(); // No mostrar el botón si no hay vouchers locales
              }
            },
          )
        : null,
  );
}

Widget _buildServerVouchers() {
  return FutureBuilder<List<dynamic>>(
    future: _vouchersFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text('Sin conexión', style: TextStyle(fontSize: 24)),
            ],
          ),
        );
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No hay vouchers cargados'));
      } else {
        final vouchers = snapshot.data!;
        final visibleVouchers = vouchers.take(_visibleRecords).toList();
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Empresa")),
                      DataColumn(label: Text("Pasajero")),
                      DataColumn(label: Text("Origen")),
                      DataColumn(label: Text("Destino")),
                      DataColumn(label: Text("Fecha")),
                      DataColumn(label: Text("Observaciones")),
                      DataColumn(label: Text("Tiempo de espera")),
                      DataColumn(label: Text("Acciones")),
                    ],
                    rows: visibleVouchers.map((voucher) {
                      return DataRow(cells: [
                        DataCell(Text(voucher['id_remito_v'].toString())),
                        DataCell(Text(voucher['Empresa'].toString())),
                        DataCell(Text(voucher['nombre_pasajero'].toString())),
                        DataCell(Text('${voucher['Origen']} (${voucher['hora_origen']})')),
                        DataCell(Text('${voucher['Destino']} (${voucher['hora_destino']})')),
                        DataCell(Text(voucher['Fecha'].toString())),
                        DataCell(
                          voucher['observaciones'] == null 
                            ? Text("N/A") 
                            : Container(
                                width: 200,
                                child: Text(
                                  voucher['observaciones'].toString(),
                                  softWrap: true,
                                  maxLines: null,
                                ),
                              ),
                        ),
                        DataCell(
                            voucher['tiempo_espera'] == null
                            ? Text("N/A")
                            : Text(voucher['tiempo_espera'].toString())
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editVoucher(voucher),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Eliminar"),
                                      content: Text("¿Estás seguro de que quieres eliminar el registro (${voucher['id_remito_v']})?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("Cancelar"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteVoucher(voucher);
                                          },
                                          child: Text("Eliminar", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_visibleRecords < vouchers.length)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _visibleRecords += 8;
                      });
                    },
                    child: Text('Ver Más'),
                  ),
                if (_visibleRecords > 8)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _visibleRecords = 8;
                      });
                    },
                    child: Text('Ver Menos'),
                  ),
              ],
            ),
          ],
        );
      }
    },
  );
}

Widget _buildLocalVouchers() {
  return FutureBuilder<List<Voucher>>(
    future: _localVouchersFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No hay vouchers cargados'));
      } else {
        final vouchers = snapshot.data!;
        final visibleVouchers = vouchers.take(_visibleRecords).toList();
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Empresa")),
                      DataColumn(label: Text("Pasajero")),
                      DataColumn(label: Text("Origen")),
                      DataColumn(label: Text("Destino")),
                      DataColumn(label: Text("Fecha")),
                      DataColumn(label: Text("Observaciones")),
                      DataColumn(label: Text("Tiempo de espera")),
                    ],
                    rows: visibleVouchers.map((voucher) {
                      return DataRow(cells: [
                        DataCell(Text(voucher.id)),
                        DataCell(Text(voucher.empresa)),
                        DataCell(Text(voucher.nombrePasajero)),
                        DataCell(Text('${voucher.origen} (${voucher.horaOrigen})')),
                        DataCell(Text('${voucher.destino} (${voucher.horaDestino})')),
                        DataCell(Text(voucher.fecha)),
                        DataCell(
                          voucher.observaciones == null 
                            ? Text("N/A") 
                            : Container(
                                width: 200,
                                child: Text(
                                  voucher.observaciones!,
                                  softWrap: true,
                                  maxLines: null,
                                ),
                              ),
                        ),
                        DataCell(
                            voucher.tiempoEspera == null
                            ? Text("N/A")
                            : Text(voucher.tiempoEspera!)
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_visibleRecords < vouchers.length)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _visibleRecords += 8;
                      });
                    },
                    child: Text('Ver Más'),
                  ),
                if (_visibleRecords > 8)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _visibleRecords = 8;
                      });
                    },
                    child: Text('Ver Menos'),
                  ),
              ],
            ),
            if (vouchers.isNotEmpty && _isConnected)
              FloatingActionButton(
                onPressed: _showUploadConfirmationDialog,
                backgroundColor: Color.fromARGB(255, 156, 39, 176),
                child: Icon(Icons.cloud_upload, color: Colors.white),
                tooltip: 'Subir vouchers locales',
              ),
          ],
        );
      }
    },
  );
}

Future<void> _showUploadConfirmationDialog() async {
  List<Voucher> pendingVouchers = await DatabaseHelper().getPendingVouchers();
  int count = pendingVouchers.length;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmación'),
        content: Text('Estás por cargar $count vouchers. ¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _uploadLocalVouchers();
            },
            child: Text('Aceptar'),
          ),
        ],
      );
    },
  );
}
}