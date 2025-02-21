import 'package:flutter/material.dart';
import 'Home.dart';
import 'footer.dart';
import 'voucherForm.dart';
import 'cargados.dart';

class Dashboard extends StatefulWidget {
    @override
    _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
    int _selectedIndex = 1; 
    void _onItemSelected(int index) {
        setState(() {
            _selectedIndex = index;
        });
    }

    final List<Widget> _pages = [];

    @override
    void initState() {
        super.initState();
        _pages.addAll([
            CargadosScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex),
            HomeScreen(onItemSelected: _onItemSelected, selectedIndex: _selectedIndex),
        ]);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: Footer(
                onItemSelected: _onItemSelected,
                selectedIndex: _selectedIndex,
            ),
        );
    }
}