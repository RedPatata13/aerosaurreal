import 'package:flutter/material.dart';

class NotficationsPage extends StatelessWidget {
  const NotficationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Page Content')),
    );
  }
}
