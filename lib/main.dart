import 'package:flutter/material.dart';

// Phase 0: the domain layer is built and tested first.
// The real app shell arrives with the Phase 1 vertical slice.
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Rota'))),
    ),
  );
}
