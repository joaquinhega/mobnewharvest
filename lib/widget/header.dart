import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobnewharvest/utils/connectivity_service.dart' as my_connectivity_service;
import 'dart:async';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final my_connectivity_service.ConnectivityService connectivityService;

  Header({required this.title, required this.connectivityService});

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  late StreamSubscription<bool> _connectivitySubscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 212, 212, 212),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  !_isConnected
                      ? Icons.signal_wifi_off
                      : Icons.wifi,
                  color: !_isConnected
                      ? Colors.red
                      : Colors.green,
                ),
                SizedBox(width: 4.0),
                Text(
                  !_isConnected ? "Sin conexión" : "Conectado",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}