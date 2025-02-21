import 'package:flutter/material.dart';

class Header extends StatelessWidget {
    final String title;

    Header({required this.title});

    @override
    Widget build(BuildContext context) {
        return AppBar(
            title: Text(title),
            centerTitle: true,
        );
    }
}
