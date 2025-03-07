import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _checkInternetConnection();
    });

    // Comprobar la conexión cada 10 segundos
    Timer.periodic(Duration(seconds: 10), (timer) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      print('Tiempo de respuesta: ${responseTime}ms');

      // Determinar la intensidad de la conexión
      bool isConnected = response.statusCode == 200 && responseTime <= 500;
      _connectionController.add(isConnected);
    } on TimeoutException catch (_) {
      _connectionController.add(false);
    } catch (e) {
      _connectionController.add(false);
    }
  }

  void dispose() {
    _connectionController.close();
  }
}