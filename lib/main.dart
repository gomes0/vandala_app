import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const VandalaApp());
}

class VandalaApp extends StatelessWidget {
  const VandalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VÂNDALA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD90429),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TelaInicialAuth(),
    );
  }
}

class TelaInicialAuth extends StatefulWidget {
  const TelaInicialAuth({super.key});

  @override
  State<TelaInicialAuth> createState() => _TelaInicialAuthState();
}

class _TelaInicialAuthState extends State<TelaInicialAuth> {
  late Future<bool> _sessaoValida;

  @override
  void initState() {
    super.initState();
    _sessaoValida = _validarSessao();
  }

  Future<bool> _validarSessao() async {
    final token = await AuthService.obterToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await AuthService.obterUsuario();
      return true;
    } catch (_) {
      await AuthService.logout();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessaoValida,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD90429)),
            ),
          );
        }

        if (snapshot.hasError) {
          return const LoginPage();
        }

        if (snapshot.data == true) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}
