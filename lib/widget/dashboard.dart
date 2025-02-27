import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'Home.dart';
import 'footer.dart';
import 'header.dart';
import 'cargadosScreen.dart'; // Asegúrate de importar el archivo correcto

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 1;
  bool _isOffline = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      CargadosScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex),
      HomeScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex),
    ]);

    _checkInitialConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _selectedIndex == 0 ? "Vouchers Cargados" : "Formularios";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(title: appBarTitle),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Footer(
        onItemSelected: _onItemSelected,
        selectedIndex: _selectedIndex,
      ),
    );
  }
}