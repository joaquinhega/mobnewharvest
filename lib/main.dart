import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobnewharvest/widget/Home.dart';
import 'package:mobnewharvest/widget/dashboard.dart';
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
            locale: const Locale('es', 'ES'), 
            supportedLocales: const [
              Locale('es', 'ES'), 
              Locale('en', 'US'), 
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Login(),
        );
    }
}
