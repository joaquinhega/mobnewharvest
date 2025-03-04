import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../db/database_helper.dart';
import '../db/user.dart';
import '../db/combustible_dao.dart';

class CombustibleCargados extends StatefulWidget {
  @override
  _CombustibleCargadosState createState() => _CombustibleCargadosState();
}

class _CombustibleCargadosState extends State<CombustibleCargados> {
  Future<List<dynamic>>? _remitosFuture;
  Future<List<Combustible>>? _localRemitosFuture;
  int _visibleRecords = 8;
  String nombreChofer = '';
  bool _showLocal = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadNombreChofer();
    _checkConnectivity();
  }

  Future<void> _loadNombreChofer() async {
    User? user = await DatabaseHelper().getLoggedInUser();
    if (user != null) {
      nombreChofer = user.nombre;
      _remitosFuture = fetchRemitos();
      _localRemitosFuture = fetchLocalRemitos();
      setState(() {});
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

Future<List<dynamic>> fetchRemitos() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('Sin conexión');
    }

    final response = await http.get(
      Uri.parse('https://newharvest.com.ar/vouchers/api/getRemitos.php'),
      headers: {
        'Nombre': nombreChofer,
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body.trim();
      return json.decode(responseBody);
    } else {
      throw Exception('Error al cargar los remitos');
    }
  } catch (e) {
    return Future.error(e);
  }
}

  Future<List<Combustible>> fetchLocalRemitos() async {
    return await DatabaseHelper().getPendingCombustibles();
  }

  Future<void> _uploadLocalRemitos() async {
    List<Combustible> pendingCombustibles = await DatabaseHelper().getPendingCombustibles();
    for (Combustible combustible in pendingCombustibles) {
      try {
        final url = Uri.parse("https://newharvest.com.ar/vouchers//api/guardarCombustible.php");

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_remito_c': combustible.id,
            'monto': combustible.monto,
            'patente': combustible.patente,
            'fecha': combustible.fecha,
            'nombre': combustible.nombre,
          }),
        );

        if (response.statusCode == 200) {
          final responseBody = response.body.trim();
          if (responseBody.startsWith('{')) {
            final responseBodyJson = jsonDecode(responseBody);

            if (responseBodyJson['status'] == 'success') {
              await DatabaseHelper().deleteCombustible(combustible.id);
            } else {
              print('Error al guardar el combustible: ${responseBodyJson['message']}');
            }
          } else {
            print('Respuesta inesperada del servidor: $responseBody');
          }
        } else {
          print('Error al enviar el combustible: ${response.body}');
        }
      } catch (e) {
        print('Error al subir el combustible: $e');
      }
    }
    setState(() {
      _localRemitosFuture = fetchLocalRemitos();
    });
  }

  Future<void> _editRemito(dynamic remito) async {
    final TextEditingController montoController = TextEditingController(text: remito['Monto'].toString());
    final TextEditingController fechaController = TextEditingController(text: remito['Fecha'].toString());
    final TextEditingController patenteController = TextEditingController(text: remito['patente'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Remito'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: montoController,
                  decoration: InputDecoration(labelText: 'Monto'),
                ),
                TextField(
                  controller: fechaController,
                  decoration: InputDecoration(labelText: 'Fecha'),
                ),
                TextField(
                  controller: patenteController,
                  decoration: InputDecoration(labelText: 'Patente'),
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
                final remitoId = remito['id_remito_c'];

                final response = await http.post(
                  Uri.parse('https://newharvest.com.ar/vouchers/api/editRemito.php'),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'id_remito_c': remitoId,
                    'Monto': montoController.text,
                    'Fecha': fechaController.text,
                    'patente': patenteController.text,
                  }),
                );
                if (response.statusCode == 200) {
                  setState(() {
                    _remitosFuture = fetchRemitos();
                  });
                  Navigator.of(context).pop();
                } else {
                  print('Error al editar el remito');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteRemito(dynamic remito) async {
    final response = await http.post(
      Uri.parse('https://newharvest.com.ar/vouchers/api/deleteRemito.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_remito_c': remito['id_remito_c'],
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _remitosFuture = fetchRemitos();
      });
    } else {
      print('Error al eliminar el remito');
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
                  _localRemitosFuture = fetchLocalRemitos();
                } else {
                  _remitosFuture = fetchRemitos();
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
    body: _showLocal ? _buildLocalRemitos() : _buildServerRemitos(),
    floatingActionButton: _showLocal && _isConnected
        ? FutureBuilder<List<Combustible>>(
            future: _localRemitosFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return FloatingActionButton(
                  onPressed: _showUploadConfirmationDialog,
                  backgroundColor: Color.fromARGB(255, 156, 39, 176),
                  child: Icon(Icons.cloud_upload, color: Colors.white),
                  tooltip: 'Subir remitos locales',
                );
              } else {
                return Container(); // No mostrar el botón si no hay remitos locales
              }
            },
          )
        : null,
  );
}

  Widget _buildServerRemitos() {
    return FutureBuilder<List<dynamic>>(
      future: _remitosFuture,
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
          return Center(child: Text('No hay remitos cargados'));
        } else {
          final remitos = snapshot.data!;
          final visibleRemitos = remitos.take(_visibleRecords).toList();
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
                        DataColumn(label: Text("Monto")),
                        DataColumn(label: Text("Fecha")),
                        DataColumn(label: Text("Patente")),
                        DataColumn(label: Text("Acciones")),
                      ],
                      rows: visibleRemitos.map((remito) {
                        return DataRow(cells: [
                          DataCell(Text(remito['id_remito_c'].toString())),
                          DataCell(Text(remito['Monto'].toString())),
                          DataCell(Text(remito['Fecha'].toString())),
                          DataCell(Text(remito['patente'].toString())),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editRemito(remito),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Eliminar"),
                                        content: Text("¿Estás seguro de que quieres eliminar el registro (${remito['id_remito_c']})?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text("Cancelar"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteRemito(remito);
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
                  if (_visibleRecords < remitos.length)
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

  Widget _buildLocalRemitos() {
    return FutureBuilder<List<Combustible>>(
      future: _localRemitosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay remitos cargados'));
        } else {
          final remitos = snapshot.data!;
          final visibleRemitos = remitos.take(_visibleRecords).toList();
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
                        DataColumn(label: Text("Monto")),
                        DataColumn(label: Text("Fecha")),
                        DataColumn(label: Text("Patente")),
                        DataColumn(label: Text("Nombre")),
                      ],
                      rows: visibleRemitos.map((remito) {
                        return DataRow(cells: [
                          DataCell(Text(remito.id)),
                          DataCell(Text(remito.monto.toString())),
                          DataCell(Text(remito.fecha)),
                          DataCell(Text(remito.patente)),
                          DataCell(Text(remito.nombre)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_visibleRecords < remitos.length)
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

  Future<void> _showUploadConfirmationDialog() async {
    List<Combustible> pendingCombustibles = await DatabaseHelper().getPendingCombustibles();
    int count = pendingCombustibles.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text('Estás por cargar $count remitos. ¿Estás seguro?'),
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
                _uploadLocalRemitos();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
