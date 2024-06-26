import 'package:flutter/material.dart';

class IdleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Idle Mode')),
      body: Center(child: Text('Device is in Idle Mode')),
    );
  }
}

class ChargingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Charging State')),
      body: Center(child: Text('Device is Charging')),
    );
  }
}

class DischargingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Discharging State')),
      body: Center(child: Text('Device is Discharging')),
    );
  }
}
