import 'package:flutter/material.dart';
import '../components/beacon_scanner.dart';

class Home extends StatelessWidget {
  const Home({super.key, required this.email, required this.token});

  final String email;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          Text("Welcome $email! Your token is $token. \nPresença semanal"),
          const Graph(),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BeaconScanner(title: "Procurando Beacon", cpf: email),
                    ));
              },
              child: const Text("Marcar Presença!"),
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
