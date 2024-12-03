import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/requirement_state_controller.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.id, required this.token});

  final int id;
  final String token;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isScanning = false;
  bool _hasCalledApi = false;
  String _statusMessage = 'Pressione o botão para escanear por beacons.';
  final RequirementStateController _requirementController =
      Get.put(RequirementStateController());
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _setupBeaconScanning();
  }

  void _setupBeaconScanning() {
    print('Setting up beacon scanning...');
    _requirementController.beacons.listen((beacons) {
      print('Beacon listener triggered. Found ${beacons.length} beacons');
      if (beacons.isNotEmpty && !_hasCalledApi) {
        print('Processing beacons...');
        for (var beacon in beacons) {
          print(
              'UUID: ${beacon.proximityUUID}, RSSI: ${beacon.rssi}, Distância: ${beacon.accuracy}m');
        }

        final beacon = beacons.first;
        if (mounted) {
          print('Found valid beacon, preparing API call...');
          print('Using token: ${widget.token}');
          setState(() {
            _statusMessage = 'Beacon encontrado com sucesso!';
            _hasCalledApi = true;
          });
          _makeApiCall(beacon.proximityUUID, widget.id);
          _requirementController.stopStreamRanging();
          _scanTimer?.cancel();
          setState(() {
            _isScanning = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _requirementController.stopStreamRanging();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _startScanning() async {
    print('Starting scan process...');
    setState(() {
      _isScanning = true;
      _hasCalledApi = false;
      _statusMessage = 'Procurando Beacon...';
    });

    try {
      print('Initializing beacon scanning...');
      _requirementController.startScanning();

      // Stop scanning after 10 seconds
      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 10), () {
        print('Scan timeout reached');
        _requirementController.stopStreamRanging();
        setState(() {
          _isScanning = false;
          _statusMessage =
              'Scan finalizado. Pressione para escanear novamente.';
        });
      });
    } on PlatformException catch (error) {
      print('Platform Exception during scan: $error');
      setState(() {
        _isScanning = false;
        _hasCalledApi = false;
        _statusMessage = 'Erro na biblioteca: $error';
      });
    }
  }

  Future<void> _makeApiCall(String proximityUUID, int id) async {
    print('\n=== Making API Call ===');
    print('UUID: $proximityUUID');
    print('Student ID: $id');
    print('Token: ${widget.token}');

    try {
      final url =
          Uri.parse('https://tcc-attendance-api.onrender.com/school-call');
      print('API URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': widget.token,
        },
        body: json.encode({
          'studentId': id,
          'proximityUUID': proximityUUID,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response token: ${widget.token}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('API call successful');
        setState(() {
          _statusMessage = 'Chamada enviada com sucesso!';
        });
      } else {
        print('API call failed with status ${response.statusCode}');
        final errorData = json.decode(response.body);
        setState(() {
          _statusMessage = 'Erro: ${errorData['message'] ?? 'Unknown error'}';
        });
      }
    } catch (error) {
      print('API call error: $error');
      setState(() {
        _statusMessage = 'Erro na comunicação: $error';
      });
    }
    print('=== API Call Complete ===\n');
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF182026);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Marque sua presença!'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
        backgroundColor: backgroundColor,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Fixed size container for the button
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.blue.shade300),
                        shape: WidgetStateProperty.all<OutlinedBorder>(
                          const CircleBorder(),
                        ),
                      ),
                      onPressed: _isScanning ? null : _startScanning,
                      child: const Text(
                        "Marcar Presença!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
