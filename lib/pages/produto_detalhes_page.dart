import 'package:flutter/material.dart';
import '../models/produto.dart';

class ProdutoDetalhesPage extends StatefulWidget {
  final Produto produto;
  final Future<void> Function(int quantidade) onAdicionar;

  const ProdutoDetalhesPage({
    super.key,
    required this.produto,
    required this.onAdicionar,
  });

  @override
  State<ProdutoDetalhesPage> createState() => _ProdutoDetalhesPageState();
}

class _ProdutoDetalhesPageState extends State<ProdutoDetalhesPage> {
  static const fundo = Color(0xFF0D0D0D);
  static const superficie = Color(0xFF181818);
  static const vermelho = Color(0xFFD90429);
  static const branco = Color(0xFFF5F5F5);
  static const cinza = Color(0xFF9CA3AF);

  int imagemSelecionada = 0;
  int quantidade = 1;

  String formatarPreco(double preco) {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String urlImagem(String caminho) {
    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }

    final caminhoLimpo = caminho.startsWith('/')
        ? caminho.substring(1)
        : caminho;

    return 'http://10.0.2.2:8000/$caminhoLimpo';
  }

  List<String> get imagens {
    final produto = widget.produto;

    if (produto.imagens.isNotEmpty) {
      return produto.imagens;
    }

    if (produto.imagem != null && produto.imagem!.isNotEmpty) {
      return [produto.imagem!];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;
    final listaImagens = imagens;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: branco,
        elevation: 0,
        title: const Text(
          'DETALHES DO PRODUTO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Imagens do produto
          SizedBox(
            height: 380,
            child: listaImagens.isEmpty
                ? _imagemIndisponivel()
                : PageView.builder(
                    itemCount: listaImagens.length,
                    onPageChanged: (indice) {
                      setState(() {
                        imagemSelecionada = indice;
                      });
                    },
                    itemBuilder: (context, indice) {
                      return Image.network(
                        urlImagem(listaImagens[indice]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _imagemIndisponivel(),
                      );
                    },
                  ),
          ),

          // Indicadores das imagens
          if (listaImagens.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  listaImagens.length,
                  (indice) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: imagemSelecionada == indice ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: imagemSelecionada == indice
                          ? vermelho
                          : const Color(0xFF555555),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (produto.categoria != null)
                  Text(
                    produto.categoria!.toUpperCase(),
                    style: const TextStyle(
                      color: vermelho,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                const SizedBox(height: 10),

                Text(
                  produto.nome,
                  style: const TextStyle(
                    color: branco,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  formatarPreco(produto.preco),
                  style: const TextStyle(
                    color: vermelho,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'DESCRIÇÃO',
                  style: TextStyle(
                    color: branco,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  produto.descricao.trim().isEmpty
                      ? 'Nenhuma descrição disponível para este produto.'
                      : produto.descricao,
                  style: const TextStyle(
                    color: cinza,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),

                const SizedBox(height: 28),

                const Divider(color: Color(0xFF333333)),

                const SizedBox(height: 18),

                const Text(
                  'QUANTIDADE',
                  style: TextStyle(
                    color: branco,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _botaoQuantidade(
                      icone: Icons.remove,
                      habilitado: quantidade > 1,
                      aoTocar: () {
                        if (quantidade > 1) {
                          setState(() => quantidade--);
                        }
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        '$quantidade',
                        style: const TextStyle(
                          color: branco,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    _botaoQuantidade(
                      icone: Icons.add,
                      habilitado: true,
                      aoTocar: () {
                        setState(() => quantidade++);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // O botão adiciona a quantidade selecionada.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onAdicionar(quantidade),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'ADICIONAR AO CARRINHO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vermelho,
                      foregroundColor: branco,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Center(
                  child: Text(
                    'VÂNDALA — ESTILO QUE NÃO SEGUE REGRAS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cinza,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoQuantidade({
    required IconData icone,
    required bool habilitado,
    required VoidCallback aoTocar,
  }) {
    return InkWell(
      onTap: habilitado ? aoTocar : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: superficie,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Icon(icone, color: habilitado ? branco : cinza),
      ),
    );
  }

  Widget _imagemIndisponivel() {
    return Container(
      color: superficie,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: cinza,
        size: 65,
      ),
    );
  }
}
