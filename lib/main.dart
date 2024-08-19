import 'package:flutter/material.dart';
import 'package:tcc_attendance_app/screens/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AttendanceApp());
}

Future inicialization(BuildContext? context) async {
  await Future.delayed(const Duration(seconds: 2));
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(title: 'Login'),
    );
  }
}
