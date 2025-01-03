import 'dart:async';
import 'package:algo_safe/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatefulWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription =
        widget.result.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(List<List<int>> data) {
    return data.map((val) => getNiceHexArray(val)).join(', ').toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries
        .map((v) => '${v.key}: ${getNiceHexArray(v.value)}')
        .join(', ')
        .toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (widget.result.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.result.device.platformName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size.height * 0.02,
              fontWeight: FontWeight.w400
            ),
          ),
          // Text(
          //   widget.result.device.remoteId.str,
          //   style: TextStyle(fontSize: size.height * 0.0125),
          // )
        ],
      );
    } else {
      return Text(widget.result.device.remoteId.str);
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.mainColor_1,
        foregroundColor: Colors.white,
      ),
      onPressed:
          (widget.result.advertisementData.connectable) ? widget.onTap : null,
      child: isConnected ? const Text('OPEN') : const Text('CONNECT'),
    );
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // var adv = widget.result.advertisementData;
    return Card(
      margin: EdgeInsets.all(size.height * 0.01),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            SizedBox(
              width: size.width * 0.05,
            ),
            Container(
              alignment: Alignment.centerLeft,
              // color: Colors.red,
              height: size.height * 0.1,
              width: size.width * 0.25,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.035,),
                  Center(child: _buildTitle(context)),
                ],
              ),
            ),
            Spacer(),
            Container(
              // color: Colors.pink,
              height: size.height * 0.1,
              width: size.width * 0.3,
              child: Image.asset("assets/images/esp32.png"),
            ),
            Container(
              // color: Colors.pink,
              height: size.height * 0.1,
              width: size.width * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildConnectButton(context),
                ],
              ),
            ),
          ],
        ),
        //         _buildTitle(context),
        //         const SizedBox(height: 8.0),
        //         _buildConnectButton(context),
        //         if (adv.advName.isNotEmpty) _buildAdvRow(context, 'Name', adv.advName),
        //         if (adv.txPowerLevel != null) _buildAdvRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
        //         if ((adv.appearance ?? 0) > 0) _buildAdvRow(context, 'Appearance', '0x${adv.appearance!.toRadixString(16)}'),
        //         if (adv.msd.isNotEmpty) _buildAdvRow(context, 'Manufacturer Data', getNiceManufacturerData(adv.msd)),
        //         if (adv.serviceUuids.isNotEmpty) _buildAdvRow(context, 'Service UUIDs', getNiceServiceUuids(adv.serviceUuids)),
        //         if (adv.serviceData.isNotEmpty) _buildAdvRow(context, 'Service Data', getNiceServiceData(adv.serviceData)),
      ),
    );
  }
}
