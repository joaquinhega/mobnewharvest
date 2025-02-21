import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'header.dart';
import '../utils/session_manager.dart';

class CargadosScreen extends StatefulWidget {
    final Function(int) onItemSelected;
    final int selectedIndex;

    CargadosScreen({required this.onItemSelected, required this.selectedIndex});

    @override
    _CargadosScreenState createState() => _CargadosScreenState();
}

class _CargadosScreenState extends State<CargadosScreen> {
    late Future<List<dynamic>> _vouchersFuture;

    @override
    void initState() {
        super.initState();
        _vouchersFuture = fetchVouchers();
    }

    Future<List<dynamic>> fetchVouchers() async {
        final user = await SessionManager.user;
        final letra = await SessionManager.letra;

        final response = await http.get(
            Uri.parse('http://10.0.2.2/newHarvestDes/api/getVouchers.php'),
            headers: {
                'User': user ?? '',
                'Letra': letra ?? '',
            },
        );

        if (response.statusCode == 200) {
            final responseBody = response.body.trim();
            print(responseBody);
            return json.decode(responseBody);
        } else {
            throw Exception('Error al cargar los vouchers');
        }
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
                                    Uri.parse('http://10.0.2.2/newHarvestDes/api/editVoucher.php'),
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
            Uri.parse('http://10.0.2.2/newHarvestDes/api/deleteVoucher.php'),
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
            appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Header(title: "Vouchers Cargados"),
            ),
            body: FutureBuilder<List<dynamic>>(
                future: _vouchersFuture,
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No hay vouchers cargados'));
                    } else {
                        final vouchers = snapshot.data!;
                        return SingleChildScrollView(
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
                                rows: vouchers.map((voucher) {
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
                        );
                    }
                },
            ),
        );
    }
}