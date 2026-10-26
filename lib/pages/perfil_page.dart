import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const fundo = Color(0xFF0D0D0D);
  static const superficie = Color(0xFF181818);
  static const vermelho = Color(0xFFD90429);
  static const branco = Color(0xFFF5F5F5);
  static const cinza = Color(0xFF9CA3AF);

  late Future<Map<String, dynamic>> usuarioFuture;
  bool saindo = false;

  @override
  void initState() {
    super.initState();
    usuarioFuture = AuthService.obterUsuario();
  }

  Future<void> sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: superficie,
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar sua conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: vermelho)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => saindo = true);

    try {
      await AuthService.logout();
    } catch (_) {
      // O token local também é removido pelo AuthService.logout().
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: branco,
        elevation: 0,
        title: const Text(
          'MEU PERFIL',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: usuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: vermelho),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: vermelho,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar seu perfil.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          usuarioFuture = AuthService.obterUsuario();
                        });
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dados = snapshot.data!;
          final usuario = dados['usuario'] is Map
              ? Map<String, dynamic>.from(dados['usuario'] as Map)
              : dados;

          final nome = usuario['name']?.toString() ?? 'Usuário';
          final email = usuario['email']?.toString() ?? '';
          final inicial = nome.trim().isNotEmpty
              ? nome.trim()[0].toUpperCase()
              : 'U';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: vermelho,
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: branco,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: branco,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: cinza),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CONTA VÂNDALA',
                      style: TextStyle(
                        color: vermelho,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'MINHA CONTA',
                style: TextStyle(
                  color: cinza,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _opcao(
                icone: Icons.person_outline,
                titulo: 'Informações pessoais',
                subtitulo: 'Nome e e-mail da sua conta',
                aoTocar: () => _mostrarInformacoes(nome, email),
              ),
              _opcao(
                icone: Icons.shopping_bag_outlined,
                titulo: 'Meus pedidos',
                subtitulo: 'Consulte suas compras',
                aoTocar: () => _avisar(
                  'O histórico será integrado ao Laravel na próxima etapa.',
                ),
              ),
              _opcao(
                icone: Icons.location_on_outlined,
                titulo: 'Meus endereços',
                subtitulo: 'Endereços para entrega',
                aoTocar: () => _avisar(
                  'O cadastro de endereços será implementado em seguida.',
                ),
              ),
              _opcao(
                icone: Icons.favorite_border,
                titulo: 'Favoritos',
                subtitulo: 'Seus produtos preferidos',
                aoTocar: () => _avisar(
                  'A lista de favoritos será implementada posteriormente.',
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: saindo ? null : sair,
                icon: saindo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout, color: vermelho),
                label: Text(
                  saindo ? 'Saindo...' : 'Sair da conta',
                  style: const TextStyle(color: vermelho),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: vermelho),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _opcao({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback aoTocar,
  }) {
    return Card(
      color: superficie,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: aoTocar,
        leading: Icon(icone, color: vermelho, size: 27),
        title: Text(
          titulo,
          style: const TextStyle(color: branco, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(color: cinza, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: cinza),
      ),
    );
  }

  void _mostrarInformacoes(String nome, String email) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: superficie,
        title: const Text('Informações pessoais'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nome', style: TextStyle(color: cinza)),
            const SizedBox(height: 4),
            Text(nome),
            const SizedBox(height: 16),
            const Text('E-mail', style: TextStyle(color: cinza)),
            const SizedBox(height: 4),
            Text(email),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: vermelho)),
          ),
        ],
      ),
    );
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }
}
