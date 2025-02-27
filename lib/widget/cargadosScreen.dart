import 'package:flutter/material.dart';
import 'voucherCargados.dart';
import 'combustibleCargados.dart';

class CargadosScreen extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  CargadosScreen({required this.onItemSelected, required this.selectedIndex});

  @override
  _CargadosScreenState createState() => _CargadosScreenState();
}

class _CargadosScreenState extends State<CargadosScreen> {
  bool isVoucherSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [isVoucherSelected, !isVoucherSelected],
            onPressed: (index) {
              setState(() {
                isVoucherSelected = index == 0;
              });
            },
            children: [
              Padding(padding: EdgeInsets.all(10), child: Text("Vouchers")),
              Padding(padding: EdgeInsets.all(10), child: Text("Combustibles")),
            ],
          ),
          Expanded(
            child: isVoucherSelected ? VoucherCargados() : CombustibleCargados(),
          ),
        ],
      ),
    );
  }
}