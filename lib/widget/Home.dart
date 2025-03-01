import 'package:flutter/material.dart';
import 'header.dart';
import 'voucherForm.dart';
import 'combustibleForm.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  HomeScreen({required this.onItemSelected, required this.selectedIndex});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              Padding(padding: EdgeInsets.all(10), child: Text("Voucher")),
              Padding(padding: EdgeInsets.all(10), child: Text("Combustible")),
            ],
          ),
          Expanded(
            child: isVoucherSelected ? VoucherForm() : CombustibleForm(),
          ),
        ],
      ),
    );
  }
}