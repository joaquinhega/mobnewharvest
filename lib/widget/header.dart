import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  Header({required this.title});

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Icon(
                _connectionStatus == ConnectivityResult.none
                    ? Icons.signal_wifi_off
                    : Icons.wifi,
                color: _connectionStatus == ConnectivityResult.none
                    ? Colors.red
                    : Colors.green,
              ),
              SizedBox(width: 5),
              Text(
                _connectionStatus == ConnectivityResult.none ? "Sin conexión" : "Conectado",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
