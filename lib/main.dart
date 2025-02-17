import 'package:flutter/material.dart';
import 'package:mobnewharvest/widget/Home.dart';
import 'widget/login.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Vouchers',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: Login(),
    );
  }
}