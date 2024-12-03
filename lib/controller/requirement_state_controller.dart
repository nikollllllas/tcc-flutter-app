import 'dart:async';
import 'dart:io';
import 'package:flutter_beacon/flutter_beacon.dart' as beacon;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class RequirementStateController extends GetxController {
  var bluetoothState = beacon.BluetoothState.stateOff.obs;
  var authorizationStatus = beacon.AuthorizationStatus.notDetermined.obs;
  var locationService = false.obs;
  StreamSubscription<beacon.RangingResult>? streamRanging;
  final beacons = <beacon.Beacon>[].obs;
  final _startBroadcasting = false.obs;
  final _startScanning = false.obs;
  final _pauseScanning = false.obs;

  bool get bluetoothEnabled =>
      bluetoothState.value == beacon.BluetoothState.stateOn;
  bool get authorizationStatusOk =>
      authorizationStatus.value == beacon.AuthorizationStatus.allowed ||
      authorizationStatus.value == beacon.AuthorizationStatus.always;
  bool get locationServiceEnabled => locationService.value;

  @override
  void onInit() {
    super.onInit();
    initializeBeacon();
  }

  Future<bool> _requestLocationPermission() async {
    // Check current permission status
    PermissionStatus locationStatus = await Permission.locationWhenInUse.status;

    // If permission is permanently denied, open settings
    if (locationStatus.isPermanentlyDenied) {
      print("Location permission permanently denied. Opening settings...");
      await AppSettings.openAppSettings(type: AppSettingsType.location);
      return false;
    }

    // Request permission if not granted
    if (!locationStatus.isGranted && !locationStatus.isLimited) {
      locationStatus = await Permission.locationWhenInUse.request();
    }

    // Check final permission status
    if (!locationStatus.isGranted && !locationStatus.isLimited) {
      print("Location permission denied");
      return false;
    }

    // Check if location service is enabled
    if (!await Permission.location.serviceStatus.isEnabled) {
      print("Location services disabled. Opening location settings...");
      await AppSettings.openAppSettings(type: AppSettingsType.location);
      return false;
    }

    return true;
  }

  Future<void> initializeBeacon() async {
    try {
      if (Platform.isAndroid) {
        // Request location permissions first
        if (!await _requestLocationPermission()) {
          print("Location permissions not granted or services disabled");
          return;
        }

        // Request Bluetooth permissions
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();

        if (bluetoothScan.isDenied || bluetoothConnect.isDenied) {
          print("Bluetooth permissions denied");
          return;
        }

        // Turn on Bluetooth if it's off
        if (!await blue_plus.FlutterBluePlus.isSupported) {
          print("Bluetooth not supported on this device");
          return;
        }

        if (await blue_plus.FlutterBluePlus.adapterState.first !=
            blue_plus.BluetoothAdapterState.on) {
          print("Turning on Bluetooth...");
          await blue_plus.FlutterBluePlus.turnOn();
        }

        await beacon.flutterBeacon.requestAuthorization;
      }

      await beacon.flutterBeacon.initializeScanning;

      // Monitor bluetooth state
      blue_plus.FlutterBluePlus.adapterState
          .listen((blue_plus.BluetoothAdapterState state) {
        print("Bluetooth adapter state: $state");
        bluetoothState.value = state == blue_plus.BluetoothAdapterState.on
            ? beacon.BluetoothState.stateOn
            : beacon.BluetoothState.stateOff;
      });

      // Monitor authorization status
      beacon.flutterBeacon.authorizationStatusChanged().listen(
        (beacon.AuthorizationStatus status) {
          print("Authorization status: $status");
          authorizationStatus.value = status;
        },
      );

      locationService.value =
          await beacon.flutterBeacon.checkLocationServicesIfEnabled;
      print("Location services: ${locationService.value}");
    } catch (e) {
      print("Error initializing beacon: $e");
    }
  }

  void startScanning() async {
    try {
      if (!await _requestLocationPermission()) {
        print("Location permission not granted or services disabled");
        return;
      }

      if (await blue_plus.FlutterBluePlus.adapterState.first !=
          blue_plus.BluetoothAdapterState.on) {
        print("Bluetooth is not enabled");
        await blue_plus.FlutterBluePlus.turnOn();
        return;
      }

      await stopStreamRanging();

      _startScanning.value = true;
      _pauseScanning.value = false;

      print("Starting beacon scan...");

      final regions = <beacon.Region>[
        beacon.Region(
          identifier: 'All Beacons',
          proximityUUID: '702F0AFC-B84B-4F2E-BC8A-B0808FC98C8C',
          major: null,
          minor: null,
        ),
      ];

      try {
        await beacon.flutterBeacon.initializeScanning;
        print("Scanning initialized successfully");
      } catch (e) {
        print("Error initializing scanning: $e");
        return;
      }

      streamRanging = beacon.flutterBeacon.ranging(regions).listen(
        (beacon.RangingResult result) {
          print("Scanning... Found ${result.beacons.length} beacons");

          if (result.beacons.isNotEmpty) {
            for (var beacon in result.beacons) {
              print(
                  'Found Beacon -> UUID: ${beacon.proximityUUID}, Major: ${beacon.major}, Minor: ${beacon.minor}, RSSI: ${beacon.rssi}, Distance: ${beacon.accuracy}m');
            }
            beacons.assignAll(result.beacons);
          }
        },
        onError: (error) {
          print('Ranging error: $error');
          stopStreamRanging();
        },
        cancelOnError: false,
      );

      // Set a timer to stop scanning after 30 seconds if no beacons are found
      Timer(const Duration(seconds: 10), () {
        if (beacons.isEmpty) {
          print("No beacons found after 10 seconds");
          stopStreamRanging();
        }
      });
    } catch (e) {
      print("Error in startScanning: $e");
      await stopStreamRanging();
    }
  }

  void pauseScanning() {
    _startScanning.value = false;
    _pauseScanning.value = true;
    stopStreamRanging();
  }

  Future<void> stopStreamRanging() async {
    _startScanning.value = false;
    try {
      await streamRanging?.cancel();
      print("Scanning stopped");
    } catch (e) {
      print('Error stopping ranging: $e');
    }
  }

  void updateBluetoothState(beacon.BluetoothState state) {
    bluetoothState.value = state;
  }

  void updateAuthorizationStatus(beacon.AuthorizationStatus status) {
    authorizationStatus.value = status;
  }

  void updateLocationService(bool flag) {
    locationService.value = flag;
  }

  Stream<bool> get startBroadcastStream => _startBroadcasting.stream;
  Stream<bool> get startStream => _startScanning.stream;
  Stream<bool> get pauseStream => _pauseScanning.stream;

  @override
  void onClose() {
    stopStreamRanging();
    super.onClose();
  }
}
