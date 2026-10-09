import 'package:flutter/material.dart';

void main() {
  runApp(const TaxcyDriverApp());
}

/// Placeholder shell until the driver app is built in M1.8.
class TaxcyDriverApp extends StatelessWidget {
  const TaxcyDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Taxcy Driver',
      home: Scaffold(
        body: Center(
          child: Text('Taxcy Driver: the app is built in milestone M1.8.'),
        ),
      ),
    );
  }
}
