import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';


class PermissionService {
  static final PermissionService _permissions = PermissionService._internal();

  factory PermissionService() {
    return _permissions;
  }

  PermissionService._internal();

  static Future<bool> checkSystemOverlayPermission() async {
    return await Permission.systemAlertWindow.status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    return await Permission.locationAlways.status.isGranted;
  }

  static Future<bool> checkBluetoothPermission() async {
    return await Permission.bluetooth.status.isGranted;
  }

  static Future<bool> requestSystemOverLayPermission() async {
    PermissionStatus status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  static Future<bool> requestBluetoothPermission(context) async {
    if (Platform.isIOS) {
      PermissionStatus permission = await Permission.bluetooth.request();
      if (PermissionStatus.granted == permission) {
        return true;
      } else {
        return await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              content: Text(
                    'App wants your bluetooth to be turn ON to enable scanning of beacon around you to enhance your navigation experience.'
              ),
              actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text("Continue"),
                    onPressed: () {
                      AppSettings.openAppSettings();
                      Navigator.pop(context, true);
                    },
                  ),
                  CupertinoDialogAction(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
              ],
            ));
      }
    }
    return true;
  }
}