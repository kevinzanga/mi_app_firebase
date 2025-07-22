import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      debugShowCheckedModeBanner: false,
      home: const AuthExample(),
    );
  }
}

class AuthExample extends StatefulWidget {
  const AuthExample({super.key});

  @override
  State<AuthExample> createState() => _AuthExampleState();
}

class _AuthExampleState extends State<AuthExample> {
  String _status = 'Not signed in';
  String _mensajeApi = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = currentUser;
      _status = currentUser != null ? 'Sesión activa' : 'Not signed in';
    });
  }

  Future<void> _signInAnonymously() async {
    if (_user != null) {
      setState(() => _status = 'Ya estás autenticado');
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _user = cred.user;
        _status = 'Signed in anonymously';
        _mensajeApi = '';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _obtenerSaludo() async {
    if (_user == null) {
      setState(() {
        _mensajeApi = 'Debes iniciar sesión primero.';
      });
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.9:3000/saludo'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mensajeApi = data['mensaje'];
        });
      } else {
        setState(() {
          _mensajeApi =
              'Error en la respuesta del servidor: ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _mensajeApi = 'Servidor no accesible: tiempo de espera agotado.';
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
      _status = 'Not signed in';
      _mensajeApi = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signInAnonymously,
              child: const Text('Login anónimo'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _obtenerSaludo,
              child: const Text('Obtener saludo'),
            ),
            const SizedBox(height: 24),
            if (_user != null)
              ElevatedButton(
                onPressed: _signOut,
                child: const Text('Cerrar sesión'),
              ),
            const SizedBox(height: 32),
            Text(
              _mensajeApi,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_user != null)
              Text('UID: ${_user!.uid}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
