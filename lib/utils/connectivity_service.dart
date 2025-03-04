import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../db/database_helper.dart';
import '../db/combustible_dao.dart';

class ConnectivityService {
    final Connectivity _connectivity = Connectivity();

    ConnectivityService() {
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
          if (result != ConnectivityResult.none) {
              _uploadPendingCombustibles();
          }
        });
    }

    Future<void> _uploadPendingCombustibles() async {
        List<Combustible> pendingCombustibles = await DatabaseHelper().getPendingCombustibles();
        for (Combustible combustible in pendingCombustibles) {
            final url = Uri.parse("https://newharvest.com.ar/vouchers/api/guardarCombustible.php");

            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                    'id_remito': combustible.id,
                    'monto': combustible.monto,
                    'patente': combustible.patente,
                    'fecha': combustible.fecha,
                    'nombre': combustible.nombre,
                }),
            );

            if (response.statusCode == 200) {
                final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
                final responseBodyJson = jsonDecode(responseBody);

                if (responseBodyJson['status'] == 'success') {
                    await DatabaseHelper().deleteCombustible(combustible.id!);
                } else {
                    print('Error al guardar el combustible: ${responseBodyJson['message']}');
                }
            } else {
                print('Error al enviar el combustible: ${response.body}');
            }
        }
    }
}