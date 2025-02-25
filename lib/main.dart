import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobnewharvest/widget/Home.dart';
import 'package:mobnewharvest/widget/dashboard.dart';
import 'package:mobnewharvest/widget/login.dart';
import 'db/database_helper.dart';
import 'db/user.dart';

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
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FutureBuilder<User?>(
        future: _getLoggedInUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return Dashboard();
          } else {
            return Login();
          }
        },
      ),
    );
  }

  Future<User?> _getLoggedInUser() async {
    return await DatabaseHelper().getLoggedInUser();
  }
}