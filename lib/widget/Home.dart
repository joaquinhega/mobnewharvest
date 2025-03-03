import 'package:flutter/material.dart';
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
          SizedBox(height: 20), 
          Container(
            width: 300, 
            height: 50, 
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 156, 39, 176), 
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isVoucherSelected ? 5 : 150, 
                  right: isVoucherSelected ? 150 : 5,
                  top: 3,
                  bottom: 3, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isVoucherSelected = true;
                          });
                        },
                        child: Center(
                          child: Text(
                            "Voucher",
                            style: TextStyle(
                              fontSize: 16,
                              color: isVoucherSelected
                                  ? Color.fromARGB(255, 156, 39, 176)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isVoucherSelected = false;
                          });
                        },
                        child: Center(
                          child: Text(
                            "Combustible",
                            style: TextStyle(
                              fontSize: 16,
                              color: !isVoucherSelected
                                  ? Color.fromARGB(255, 156, 39, 176)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: isVoucherSelected ? VoucherForm() : CombustibleForm(),
          ),
        ],
      ),
    );
  }
}
