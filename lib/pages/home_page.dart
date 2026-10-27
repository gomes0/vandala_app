import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/carrinho_service.dart';
import 'perfil_page.dart';
import 'produto_detalhes_page.dart';
import 'package:flutter/services.dart';
import '../widgets/imagem_com_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _ItemCarrinho {
  final Produto produto;
  int quantidade;
  int? itemCarrinhoId;

  _ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.itemCarrinhoId,
  });
}

class _HomePageState extends State<HomePage> {
  final List<_ItemCarrinho> carrinho = [];
  final Set<int> produtosCarregando = {};

  bool carregandoInicial = true;

  late Future<List<dynamic>> produtosFuture;
  late Future<List<dynamic>> categoriasFuture;

  int? categoriaSelecionadaId;

  final TextEditingController pesquisaController = TextEditingController();
  String termoPesquisa = '';

  int paginaSelecionada = 0;
  bool consultandoCarrinho = false;

  static const fundo = Color(0xFF0D0D0D);
  static const superficie = Color(0xFF181818);
  static const vermelho = Color(0xFFD90429);
  static const branco = Color(0xFFF5F5F5);
  static const cinza = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    carregarDados();
    inicializarApp();
    carregarCarrinhoDaApi();
  }

  Future<void> executarAcaoCarrinho(
    int produtoId,
    Future<void> Function() acao,
  ) async {
    if (produtosCarregando.contains(produtoId)) return;

    setState(() {
      produtosCarregando.add(produtoId);
    });

    try {
      await acao();
    } catch (e) {
      debugPrint('Erro ao atualizar carrinho: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o carrinho.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          produtosCarregando.remove(produtoId);
        });
      }
    }
  }

  Future<void> inicializarApp() async {
    try {
      await Future.wait([produtosFuture, categoriasFuture]);
    } catch (e) {
      debugPrint('Erro ao inicializar o aplicativo: $e');
    } finally {
      if (mounted) {
        setState(() {
          carregandoInicial = false;
        });
      }
    }
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  void carregarDados() {
    produtosFuture = ApiService.buscarProdutos();
    categoriasFuture = ApiService.buscarCategorias();
  }

  // =========================================================
  // FILTRAR PRODUTOS POR CATEGORIA E PESQUISA
  // =========================================================

  List<Produto> filtrarProdutos(List<Produto> produtos) {
    final termo = termoPesquisa.trim().toLowerCase();

    return produtos.where((produto) {
      final correspondePesquisa =
          termo.isEmpty ||
          produto.nome.toLowerCase().contains(termo) ||
          produto.descricao.toLowerCase().contains(termo) ||
          (produto.categoria ?? '').toLowerCase().contains(termo);

      // O modelo Produto precisa disponibilizar categoriaId.
      // A comparação por nome abaixo mantém compatibilidade
      // com modelos que possuem apenas o nome da categoria.
      final correspondeCategoria =
          categoriaSelecionadaId == null ||
          _categoriaIdDoProduto(produto) == categoriaSelecionadaId;

      return correspondePesquisa && correspondeCategoria;
    }).toList();
  }

  int? _categoriaIdDoProduto(Produto produto) {
    // Compatibilidade sem exigir categoriaId no modelo Produto.
    // O ID da categoria é obtido pelo nome usando os dados da API.
    return _idsCategoriaPorNome[(produto.categoria ?? '').trim().toLowerCase()];
  }

  final Map<String, int> _idsCategoriaPorNome = {};

  Widget _barraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: TextField(
        controller: pesquisaController,
        onChanged: (valor) {
          setState(() => termoPesquisa = valor);
        },
        style: const TextStyle(color: branco),
        cursorColor: vermelho,
        decoration: InputDecoration(
          hintText: 'Buscar produtos...',
          hintStyle: const TextStyle(color: cinza),
          prefixIcon: const Icon(Icons.search, color: vermelho),
          suffixIcon: termoPesquisa.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpar pesquisa',
                  onPressed: () {
                    pesquisaController.clear();
                    setState(() => termoPesquisa = '');
                  },
                  icon: const Icon(Icons.close, color: branco),
                )
              : null,
          filled: true,
          fillColor: superficie,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: vermelho, width: 1.5),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CARRINHO: CARREGAR DADOS DA API
  // =========================================================

  Future<void> carregarCarrinhoDaApi() async {
    try {
      final resposta = await CarrinhoService.buscarCarrinho();

      final dadosCarrinho = resposta['carrinho'];
      final List<dynamic> itensApi = dadosCarrinho?['itens'] ?? [];

      final List<_ItemCarrinho> itensCarregados = [];

      for (final item in itensApi) {
        final dadosProduto = item['produto'];
        if (dadosProduto == null) continue;

        final produto = Produto.fromJson(
          Map<String, dynamic>.from(dadosProduto),
        );

        itensCarregados.add(
          _ItemCarrinho(
            produto: produto,
            quantidade: int.tryParse(item['quantidade'].toString()) ?? 1,
            itemCarrinhoId: int.tryParse(item['id'].toString()),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        carrinho
          ..clear()
          ..addAll(itensCarregados);
      });

      debugPrint('Carrinho carregado: ${itensCarregados.length} itens');
      debugPrint('Subtotal: ${resposta['subtotal']}');
    } catch (e) {
      debugPrint('Erro ao carregar carrinho: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar o carrinho: $e'),
          backgroundColor: vermelho,
        ),
      );
    }
  }

  // =========================================================
  // TESTAR A API
  // =========================================================

  Future<void> testarApiCarrinho() async {
    if (consultandoCarrinho) return;

    setState(() => consultandoCarrinho = true);

    try {
      final token = await AuthService.obterToken();

      debugPrint('Token encontrado: ${token != null && token.isNotEmpty}');

      final resultado = await CarrinhoService.buscarCarrinho();

      debugPrint('===== JSON DO CARRINHO =====');
      debugPrint(const JsonEncoder.withIndent('  ').convert(resultado));

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: superficie,
          title: const Text('Resposta da API', style: TextStyle(color: branco)),
          content: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(resultado),
              style: const TextStyle(color: branco, fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR', style: TextStyle(color: vermelho)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erro ao consultar carrinho: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao consultar carrinho: $e'),
          backgroundColor: vermelho,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => consultandoCarrinho = false);
      }
    }
  }

  // =========================================================
  // ATUALIZAR
  // =========================================================

  Future<void> atualizar() async {
    setState(carregarDados);

    try {
      await Future.wait([produtosFuture, categoriasFuture]);
    } catch (_) {
      // Os erros são apresentados na tela.
    }
  }

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

  int get quantidadeCarrinho =>
      carrinho.fold(0, (total, item) => total + item.quantidade);

  double get subtotal => carrinho.fold(
    0.0,
    (total, item) => total + item.produto.preco * item.quantidade,
  );

  // =========================================================
  // ADICIONAR AO CARRINHO
  // =========================================================

  Future<void> adicionarAoCarrinho(
    Produto produto, {
    int quantidade = 1,
  }) async {
    try {
      final resposta = await CarrinhoService.adicionarItem(
        produtoId: produto.id,
        quantidade: quantidade,
      );

      debugPrint('Produto adicionado: $resposta');

      await carregarCarrinhoDaApi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${produto.nome} adicionado ao carrinho.'),
          backgroundColor: const Color.fromARGB(255, 236, 236, 236),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VER CARRINHO',
            textColor: vermelho,
            onPressed: () {
              setState(() => paginaSelecionada = 1);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível adicionar: $e'),
          backgroundColor: vermelho,
        ),
      );
    }
  }

  void abrirDetalhesProduto(Produto produto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoDetalhesPage(
          produto: produto,
          onAdicionar: (quantidade) {
            return adicionarAoCarrinho(produto, quantidade: quantidade);
          },
        ),
      ),
    );
  }

  // =========================================================
  // ALTERAR QUANTIDADE
  // =========================================================

  Future<void> alterarQuantidade(int indice, int variacao) async {
    if (indice < 0 || indice >= carrinho.length) return;

    final item = carrinho[indice];
    final novaQuantidade = item.quantidade + variacao;
    final itemId = item.itemCarrinhoId;

    if (itemId == null) {
      await carregarCarrinhoDaApi();
      return;
    }

    try {
      if (novaQuantidade <= 0) {
        await CarrinhoService.removerItem(itemId: itemId);
      } else {
        await CarrinhoService.atualizarItem(
          itemId: itemId,
          quantidade: novaQuantidade,
        );
      }

      await carregarCarrinhoDaApi();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível atualizar a quantidade: $e'),
          backgroundColor: vermelho,
        ),
      );
    }
  }

  Future<void> removerItem(int indice) async {
    if (indice < 0 || indice >= carrinho.length) return;

    final item = carrinho[indice];
    final nome = item.produto.nome;
    final itemId = item.itemCarrinhoId;

    if (itemId == null) {
      await carregarCarrinhoDaApi();
      return;
    }

    try {
      await CarrinhoService.removerItem(itemId: itemId);
      await carregarCarrinhoDaApi();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nome removido do carrinho.'),
          backgroundColor: const Color.fromARGB(255, 236, 236, 236),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível remover o produto: $e'),
          backgroundColor: vermelho,
        ),
      );
    }
  }

  // =========================================================
  // INTERFACE PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: branco,
        elevation: 0,
        title: const Text(
          'VÂNDALA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Consultar API do carrinho',
            onPressed: consultandoCarrinho ? null : testarApiCarrinho,
            icon: consultandoCarrinho
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: vermelho,
                    ),
                  )
                : const Icon(Icons.cloud_sync),
          ),
          if (paginaSelecionada == 0)
            IconButton(
              tooltip: 'Atualizar produtos',
              onPressed: atualizar,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),

      body: carregandoInicial
          ? _telaLoading()
          : IndexedStack(
              index: paginaSelecionada,
              children: [
                _construirInicio(),
                _construirCarrinho(),
                const PerfilPage(),
              ],
            ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: superficie,
        indicatorColor: vermelho.withValues(alpha: 0.18),
        selectedIndex: paginaSelecionada,
        onDestinationSelected: (indice) {
          setState(() => paginaSelecionada = indice);

          if (indice == 1) {
            carregarCarrinhoDaApi();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: vermelho),
            label: 'Início',
          ),
          NavigationDestination(
            icon: carrinho.isEmpty
                ? const Icon(Icons.shopping_cart_outlined)
                : Badge(
                    label: Text('$quantidadeCarrinho'),
                    backgroundColor: vermelho,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
            selectedIcon: const Icon(Icons.shopping_cart, color: vermelho),
            label: 'Carrinho',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: vermelho),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INÍCIO: CATEGORIAS E PRODUTOS
  // =========================================================

  Widget _construirInicio() {
    return RefreshIndicator(
      onRefresh: atualizar,
      color: vermelho,
      backgroundColor: superficie,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          _banner(),
          _barraPesquisa(),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Text(
              'EXPLORE POR CATEGORIA',
              style: TextStyle(
                color: branco,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: FutureBuilder<List<dynamic>>(
              future: categoriasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: vermelho),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Não foi possível carregar as categorias.',
                      style: TextStyle(color: cinza),
                    ),
                  );
                }

                final categorias = snapshot.data ?? [];

                if (categorias.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma categoria disponível.',
                      style: TextStyle(color: cinza),
                    ),
                  );
                }

                // Prepara o mapeamento de nome para ID.
                _idsCategoriaPorNome.clear();
                for (final item in categorias) {
                  final id = int.tryParse(item['id'].toString());
                  final nome = (item['nome'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

                  if (id != null && nome.isNotEmpty) {
                    _idsCategoriaPorNome[nome] = id;
                  }
                }

                final categoriaAtualExiste = categorias.any(
                  (item) =>
                      int.tryParse(item['id'].toString()) ==
                      categoriaSelecionadaId,
                );

                if (categoriaSelecionadaId != null && !categoriaAtualExiste) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => categoriaSelecionadaId = null);
                    }
                  });
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categorias.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final bool todas = index == 0;
                    final categoria = todas ? null : categorias[index - 1];
                    final int? id = todas
                        ? null
                        : int.tryParse(categoria['id'].toString());

                    final selecionada = categoriaSelecionadaId == id;

                    return ChoiceChip(
                      label: Text(
                        todas
                            ? 'Todas'
                            : categoria['nome']?.toString() ?? 'Categoria',
                      ),
                      selected: selecionada,
                      onSelected: (_) {
                        setState(() {
                          categoriaSelecionadaId = id;
                        });
                      },
                      backgroundColor: superficie,
                      selectedColor: vermelho,
                      labelStyle: TextStyle(
                        color: selecionada ? branco : cinza,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selecionada ? vermelho : const Color(0xFF333333),
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
            child: Text(
              'DESTAQUES',
              style: TextStyle(
                color: branco,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ),

          FutureBuilder<List<dynamic>>(
            future: produtosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: CircularProgressIndicator(color: vermelho),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _mensagemErro();
              }

              final todosProdutos = (snapshot.data ?? [])
                  .map(
                    (item) => Produto.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList();

              final produtos = filtrarProdutos(todosProdutos);

              if (produtos.isEmpty) {
                final temFiltro =
                    termoPesquisa.trim().isNotEmpty ||
                    categoriaSelecionadaId != null;

                return Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 55, color: cinza),
                      const SizedBox(height: 12),
                      Text(
                        temFiltro
                            ? 'Nenhum produto encontrado com os filtros selecionados.'
                            : 'Nenhum produto ativo encontrado.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: cinza, fontSize: 14),
                      ),
                      if (temFiltro) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            pesquisaController.clear();
                            setState(() {
                              termoPesquisa = '';
                              categoriaSelecionadaId = null;
                            });
                          },
                          child: const Text(
                            'LIMPAR FILTROS',
                            style: TextStyle(color: vermelho),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: produtos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.52,
                ),
                itemBuilder: (context, index) {
                  return _cardProduto(produtos[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TELA DO CARRINHO
  // =========================================================

  Widget _construirCarrinho() {
    if (carrinho.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 76, color: cinza),
              const SizedBox(height: 20),
              const Text(
                'SEU CARRINHO ESTÁ VAZIO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: branco,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Explore a VÂNDALA e encontre sua próxima peça favorita.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cinza),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => paginaSelecionada = 0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vermelho,
                  foregroundColor: branco,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('EXPLORAR PRODUTOS'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'MEU CARRINHO',
                  style: TextStyle(
                    color: branco,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '$quantidadeCarrinho '
                '${quantidadeCarrinho == 1 ? 'item' : 'itens'}',
                style: const TextStyle(color: cinza),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: carrinho.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, indice) {
              final item = carrinho[indice];
              final caminho = item.produto.caminhoImagem;
              final chaveCarrinho = item.itemCarrinhoId ?? item.produto.id;
              final carregando = produtosCarregando.contains(chaveCarrinho);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: superficie,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF292929)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 85,
                        height: 105,
                        child: caminho == null
                            ? _imagemIndisponivel()
                            : ImagemComLoading(
                                url: urlImagem(caminho),
                                fit: BoxFit.cover,
                                placeholder: _imagemIndisponivel(),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.produto.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: branco,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatarPreco(item.produto.preco),
                            style: const TextStyle(
                              color: vermelho,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _botaoQuantidade(
                                icone: Icons.remove,
                                carregando: carregando,
                                aoTocar: () {
                                  executarAcaoCarrinho(chaveCarrinho, () async {
                                    await alterarQuantidade(indice, -1);
                                  });
                                },
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  '${item.quantidade}',
                                  style: const TextStyle(
                                    color: branco,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              _botaoQuantidade(
                                icone: Icons.add,
                                carregando: carregando,
                                aoTocar: () {
                                  executarAcaoCarrinho(chaveCarrinho, () async {
                                    await alterarQuantidade(indice, 1);
                                  });
                                },
                              ),

                              const Spacer(),

                              if (carregando)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: vermelho,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Remover produto',
                                  onPressed: () {
                                    executarAcaoCarrinho(
                                      chaveCarrinho,
                                      () async {
                                        await removerItem(indice);
                                      },
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: vermelho,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: const BoxDecoration(
            color: superficie,
            border: Border(top: BorderSide(color: Color(0xFF333333))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(color: cinza, fontSize: 16),
                    ),
                    Text(
                      formatarPreco(subtotal),
                      style: const TextStyle(
                        color: branco,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Frete e pagamento serão calculados na finalização.',
                  style: TextStyle(color: cinza, fontSize: 11),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A finalização da compra será integrada ao Laravel na próxima etapa.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vermelho,
                      foregroundColor: branco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'FINALIZAR COMPRA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _botaoQuantidade({
    required IconData icone,
    required VoidCallback aoTocar,
    bool carregando = false,
  }) {
    return InkWell(
      onTap: carregando ? null : aoTocar,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF444444)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: carregando
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    color: vermelho,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icone, color: branco, size: 18),
        ),
      ),
    );
  }
  // =========================================================
  // BANNER
  // =========================================================

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF351018), Color(0xFF181818)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF48212A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTILO QUE\nNÃO SEGUE REGRAS.',
            style: TextStyle(
              color: branco,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Descubra sua próxima peça favorita.',
            style: TextStyle(color: cinza, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: vermelho,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'EXPLORE A VÂNDALA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD DO PRODUTO
  // =========================================================

  Widget _cardProduto(Produto produto) {
    final caminho = produto.caminhoImagem;

    return InkWell(
      onTap: () => abrirDetalhesProduto(produto),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        decoration: BoxDecoration(
          color: superficie,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF292929)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: caminho == null
                    ? _imagemIndisponivel()
                    : ImagemComLoading(
                        url: urlImagem(caminho),
                        fit: BoxFit.cover,
                        placeholder: _imagemIndisponivel(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (produto.categoria != null)
                    Text(
                      produto.categoria!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: cinza,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    produto.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: branco,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatarPreco(produto.preco),
                    style: const TextStyle(
                      color: branco,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => adicionarAoCarrinho(produto),
                      icon: const Icon(Icons.add_shopping_cart, size: 17),
                      label: const Text(
                        'ADICIONAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vermelho,
                        foregroundColor: branco,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagemIndisponivel() {
    return Container(
      color: const Color(0xFF222222),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: cinza, size: 40),
      ),
    );
  }

  Widget _mensagemErro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: vermelho, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar os produtos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: branco),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: atualizar,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _telaLoading() {
    return Container(
      color: fundo,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'VÂNDALA',
              style: TextStyle(
                color: branco,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: vermelho,
                backgroundColor: superficie,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'PREPARANDO SEU ESTILO...',
              style: TextStyle(
                color: cinza,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
