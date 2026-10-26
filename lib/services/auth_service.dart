import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Android Emulator acessa o Windows pelo endereço 10.0.2.2.
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const String tokenKey = 'vandala_token';

  static Future<Map<String, dynamic>> _enviar(
    String endpoint,
    Map<String, dynamic> dados,
  ) async {
    final resposta = await http
        .post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));

    final resultado = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final erros = resultado['errors'];

      if (erros is Map && erros.isNotEmpty) {
        final primeiro = erros.values.first;
        if (primeiro is List && primeiro.isNotEmpty) {
          throw Exception(primeiro.first.toString());
        }
      }

      throw Exception(
        resultado['mensagem']?.toString() ??
            'Não foi possível concluir a solicitação.',
      );
    }

    final token = resultado['token']?.toString();

    if (token != null && token.isNotEmpty) {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(tokenKey, token);
    }

    return resultado;
  }

  static Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) {
    return _enviar('cadastro', {
      'name': nome.trim(),
      'email': email.trim(),
      'password': senha,
      'password_confirmation': senha,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) {
    return _enviar('login', {'email': email.trim(), 'password': senha});
  }

  static Future<String?> obterToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString(tokenKey);
  }

  static Future<Map<String, dynamic>> obterUsuario() async {
    final token = await obterToken();

    if (token == null || token.isEmpty) {
      throw Exception('Você precisa entrar na sua conta.');
    }

    final resposta = await http
        .get(
          Uri.parse('$baseUrl/usuario'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('Sessão inválida ou expirada.');
    }

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final token = await obterToken();

    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } finally {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.remove(tokenKey);
    }
  }
}
