import 'package:flutter/material.dart';
import 'package:mobnewharvest/utils/connectivity_service.dart' as my_connectivity_service;
import 'dart:async';
import 'Home.dart';
import 'footer.dart';
import 'header.dart';
import 'cargadosScreen.dart';

class Dashboard extends StatefulWidget {
  final my_connectivity_service.ConnectivityService connectivityService;

  Dashboard({required this.connectivityService});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 1;
  bool _isOffline = false;
  late StreamSubscription<bool> _connectivitySubscription;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      CargadosScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex, connectivityService: widget.connectivityService),
      HomeScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex),
    ]);

    _connectivitySubscription = widget.connectivityService.connectionStatus.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
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
    String appBarTitle = _selectedIndex == 0 ? "Registros Cargados" : "Formularios";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(title: appBarTitle, connectivityService: widget.connectivityService),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Footer(
        onItemSelected: _onItemSelected,
        selectedIndex: _selectedIndex,
        connectivityService: widget.connectivityService,
      ),
    );
  }
}