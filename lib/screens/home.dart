import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.token});

  final String token;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  bool _isScanning = false;
  String _statusMessage = 'Pressione o botão para escanear por beacons.';
  ProgressDialog? _progressDialog;

  final _beaconScanner = BeaconScanner(
    cpf: '',
  );

  @override
  void initState() {
    super.initState();
    _progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: false);
  }

  @override
  void dispose() {
    _beaconScanner.dispose();
    super.dispose();
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Procurando Beacon...';
    });

    try {
      await _beaconScanner.initializeScanning();
      _beaconScanner.startRanging(
        onBeaconFound: (beacon) async {
          setState(() {
            _statusMessage = 'Beacon encontrado com sucesso!';
          });
          _showLoadingModal();
          await _makeApiCall(beacon.proximityUUID, widget.token);
        },
        onRangingError: (error) {
          setState(() {
            _isScanning = false;
            _statusMessage = 'Erro ao escanear: $error';
          });
        },
      );
    } on PlatformException catch (error) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Erro na biblioteca: $error';
      });
    }
  }

  void _showLoadingModal() {
    _progressDialog!.show();
  }

  Future<void> _makeApiCall(String proximityUUID, String cpf) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.3.43:3000/school-call-student?id=$proximityUUID&cpf=$cpf'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'];

        setState(() {
          _statusMessage = 'Chamada enviada com sucesso!';
        });
        _progressDialog!.hide();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Retorno da Chamada'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        final error = jsonResponse['error'];
        _progressDialog!.hide();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Retorno da Chamada'),
              content: Text(error),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
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
            title: const Text('Erro'),
            content: const Text('Erro ao conectar ao servidor'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF182026);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marque sua presença!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all<Size>(const Size(300, 600)),
                backgroundColor: WidgetStateProperty.all<Color>(Colors.blue.shade300),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  const CircleBorder(),
                ),
              ),
              onPressed: _startScanning,
              child: const Text("Marcar Presença!"),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class Graph extends StatelessWidget {
  const Graph({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Segunda'),
              Text('Terça'),
              Text('Quarta'),
              Text('Quinta'),
              Text('Sexta'),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Bar(value: 2),
                    Text('2'),
                  ],
                ),
                Column(
                  children: [
                    Bar(value: 4),
                    Text('4'),
                  ],
                ),
                Column(
                  children: [
                    Bar(value: 3),
                    Text('3'),
                  ],
                ),
                Column(
                  children: [
                    Bar(value: 1),
                    Text('1'),
                  ],
                ),
                Column(
                  children: [
                    Bar(value: 2),
                    Text('2'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Bar extends StatelessWidget {
  final int value;

  const Bar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: value * 50,
      width: 30,
      color: Colors.blue,
    );
  }
}

class BeaconScanner {
  final String cpf;

  BeaconScanner({required this.cpf});

  StreamSubscription<RangingResult>? _streamSubscription;
  String _statusChamada = '';
  ProgressDialog? _progressDialog;

  Future<void> initializeScanning() async {
    try {
      await flutterBeacon.initializeScanning;
    } on PlatformException {
      print('Falha ao buscar por beacons, erro na biblioteca.');
    }
  }

  void startRanging({
    required Function(Beacon) onBeaconFound,
    required Function(String) onRangingError,
  }) {
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
          onRangingError('Não tem beacon perto.');
          _streamSubscription?.cancel();
        }

        for (var i = 0; i < result.beacons.length; i++) {
          final beacon = result.beacons[i];

          if (beacon.accuracy <= 10.01) {
            onBeaconFound(beacon);
            _streamSubscription?.cancel();
          } else {
            onRangingError(
                'Chegue mais perto do beacon. \n Você está a ${beacon.accuracy} de distância do beacon.');
          }
        }
      },
    );
  }

  void dispose() {
    _streamSubscription?.cancel();
  }
}
