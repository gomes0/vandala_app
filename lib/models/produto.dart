class Produto {
  final int id;
  final String nome;
  final String descricao;
  final double preco;
  final String? imagem;
  final String? categoria;
  final List<String> imagens;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.imagem,
    this.categoria,
    this.imagens = const [],
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    final listaImagens =
        (json['imagens'] as List<dynamic>?)
            ?.map((item) {
              return item['caminho']?.toString() ?? '';
            })
            .where((caminho) => caminho.isNotEmpty)
            .toList() ??
        <String>[];

    return Produto(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? 'Produto',
      descricao: json['descricao']?.toString() ?? '',
      preco: double.tryParse(json['preco'].toString()) ?? 0,
      imagem: json['imagem']?.toString(),
      categoria: json['categoria']?['nome']?.toString(),
      imagens: listaImagens,
    );
  }

  String? get caminhoImagem {
    if (imagens.isNotEmpty) {
      return imagens.first;
    }

    if (imagem != null && imagem!.isNotEmpty) {
      return imagem;
    }

    return null;
  }
}
