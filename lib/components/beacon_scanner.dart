import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class BeaconScanner extends StatefulWidget {
  const BeaconScanner({super.key, required this.title, required this.cpf});

  final String title;
  final String cpf;
  @override
  _BeaconScannerState createState() => _BeaconScannerState();
}

class _BeaconScannerState extends State<BeaconScanner> {
  StreamSubscription<RangingResult>? _streamSubscription;
  String _statusChamada = '';
  ProgressDialog? _progressDialog;

  @override
  void initState() {
    super.initState();
    _initializeScanning();
    _progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: false);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeScanning() async {
    try {
      await flutterBeacon.initializeScanning;
    } on PlatformException {
      print('Falha ao buscar por beacons, erro na biblioteca.');
    }
  }

  void _startRanging() {
    final regions = <Region>[];

    if (Platform.isIOS) {
      regions.add(
        Region(
          identifier: 'Apple Airlocate',
          proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        ),
      );
    } else {
      regions.add(Region(identifier: 'iBeacon'));
    }

    _streamSubscription = flutterBeacon.ranging(regions).listen(
      (RangingResult result) async {
        if (result.beacons.isEmpty) {
          setState(() {
            _statusChamada = 'Não tem beacon perto.';
          });
          _streamSubscription?.cancel();
        }

        for (var i = 0; i < result.beacons.length; i++) {
          final beacon = result.beacons[i];

          setState(() {
            if (beacon.accuracy <= 10.01) {
              _statusChamada = 'Beacon localizado com sucesso';
              _streamSubscription?.cancel();
              _showLoadingModal();
              _makeApiCall(beacon.proximityUUID);
            } else {
              _statusChamada =
                  'Chegue mais perto do beacon. \n Você está a ${beacon.accuracy} de distância do beacon.';
            }
          });
        }
      },
    );
  }

  void _showLoadingModal() {
    _progressDialog!.show();
  }

  Future<void> _makeApiCall(String proximityUUID) async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.3.43:3000/school-call-student?id=$proximityUUID&cpf=${widget.cpf}'));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'];

        setState(() {
          _statusChamada = 'Chamada enviada com sucesso';
        });
        _progressDialog!.hide();
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Retorno da Chamada'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        final error = jsonResponse['error'];
        _progressDialog!.hide();
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Retorno da Chamada'),
              content: Text(error),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      _progressDialog!.hide();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Erro ao conectar ao servidor'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Aperte o botão para começar a escanear.',
            ),
            Text(
              _statusChamada,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startRanging,
        tooltip: 'Começar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
