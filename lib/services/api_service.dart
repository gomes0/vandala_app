import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<List<dynamic>> buscarProdutos() async {
    final resposta = await http
        .get(Uri.parse('$baseUrl/produtos'))
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao buscar produtos: ${resposta.statusCode}');
    }

    return jsonDecode(resposta.body) as List<dynamic>;
  }

  static Future<List<dynamic>> buscarCategorias() async {
    final resposta = await http
        .get(Uri.parse('$baseUrl/categorias'))
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception('Erro ao buscar categorias: ${resposta.statusCode}');
    }

    return jsonDecode(resposta.body) as List<dynamic>;
  }
}
