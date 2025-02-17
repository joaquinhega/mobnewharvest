import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';

import 'combustibleForm.dart';
import 'voucherForm.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isVoucherSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(),
      ),
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
      bottomNavigationBar: Footer(),
    );
  }
}
