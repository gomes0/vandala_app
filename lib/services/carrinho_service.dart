import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CarrinhoService {
  static Future<Map<String, dynamic>> _requisicao(
    String metodo,
    String endpoint, {
    Map<String, dynamic>? dados,
  }) async {
    final token = await AuthService.obterToken();

    if (token == null || token.isEmpty) {
      throw Exception('Faça login para acessar seu carrinho.');
    }

    final uri = Uri.parse('${AuthService.baseUrl}/$endpoint');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late http.Response resposta;

    switch (metodo) {
      case 'GET':
        resposta = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'POST':
        resposta = await http
            .post(uri, headers: headers, body: jsonEncode(dados ?? {}))
            .timeout(const Duration(seconds: 15));
        break;

      case 'PUT':
        resposta = await http
            .put(uri, headers: headers, body: jsonEncode(dados ?? {}))
            .timeout(const Duration(seconds: 15));
        break;

      case 'DELETE':
        resposta = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      default:
        throw Exception('Método HTTP não suportado: $metodo');
    }

    Map<String, dynamic> resultado;

    try {
      final corpo = jsonDecode(resposta.body);

      if (corpo is Map<String, dynamic>) {
        resultado = corpo;
      } else {
        throw Exception('Resposta inesperada da API.');
      }
    } on FormatException {
      throw Exception(
        'A API retornou uma resposta inválida '
        '(HTTP ${resposta.statusCode}).',
      );
    }

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
            'Erro na API (HTTP ${resposta.statusCode}).',
      );
    }

    return resultado;
  }

  // Consulta o carrinho do usuário autenticado.
  static Future<Map<String, dynamic>> buscarCarrinho() {
    return _requisicao('GET', 'carrinho');
  }

  // Adiciona um produto.
  static Future<Map<String, dynamic>> adicionarItem({
    required int produtoId,
    int quantidade = 1,
    int? corId,
    int? tamanhoId,
  }) {
    return _requisicao(
      'POST',
      'carrinho/itens',
      dados: {
        'produto_id': produtoId,
        'quantidade': quantidade,
        if (corId != null) 'cor_id': corId,
        if (tamanhoId != null) 'tamanho_id': tamanhoId,
      },
    );
  }

  // Atualiza a quantidade de um item do carrinho.
  static Future<Map<String, dynamic>> atualizarItem({
    required int itemId,
    required int quantidade,
  }) {
    return _requisicao(
      'PUT',
      'carrinho/itens/$itemId',
      dados: {'quantidade': quantidade},
    );
  }

  // Remove um item do carrinho.
  static Future<Map<String, dynamic>> removerItem({required int itemId}) {
    return _requisicao('DELETE', 'carrinho/itens/$itemId');
  }
}
