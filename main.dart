import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const servidor = 'http://localhost/sistema_trufas';

String dinheiro(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

void main() {
  runApp(const MaterialApp(
    home: TelaInicial(),
    debugShowCheckedModeBanner: false,
  ));
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  bool cadastro = false;
  String perfil = 'produtor';

  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();

  @override
  void initState() {
    super.initState();
    verificarLogin();
  }

  Future<void> verificarLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt('id');
    final nomeSalvo = prefs.getString('nome');
    final perfilSalvo = prefs.getString('perfil');

    if (!mounted) return;

    if (id != null && nomeSalvo != null && perfilSalvo != null) {
      abrirTela(nomeSalvo, perfilSalvo);
    }
  }

  void abrirTela(String nomeUsuario, String perfilUsuario) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPerfil(
          nome: nomeUsuario,
          perfil: perfilUsuario,
        ),
      ),
    );
  }

  void mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> entrar() async {
    if (email.text.isEmpty || senha.text.isEmpty) {
      mensagem('Preencha todos os campos');
      return;
    }

    try {
      final resposta = await http.post(
        Uri.parse('$servidor/login.php'),
        body: {
          'email': email.text,
          'senha': senha.text,
        },
      );

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      if (dados['sucesso'] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('id', int.parse('${dados['id']}'));
        await prefs.setString('nome', dados['nome']);
        await prefs.setString('perfil', dados['perfil']);

        if (!mounted) return;

        abrirTela(dados['nome'], dados['perfil']);
      } else {
        mensagem('E-mail ou senha incorretos');
      }
    } catch (e) {
      if (!mounted) return;
      mensagem('Erro ao conectar com servidor');
    }
  }

  Future<void> cadastrar() async {
    if (nome.text.isEmpty || email.text.isEmpty || senha.text.isEmpty) {
      mensagem('Preencha todos os campos');
      return;
    }

    try {
      final resposta = await http.post(
        Uri.parse('$servidor/cadastro.php'),
        body: {
          'nome': nome.text,
          'email': email.text,
          'senha': senha.text,
          'perfil': perfil,
        },
      );

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      mensagem(dados['mensagem']);

      if (dados['mensagem'] == 'Cadastro realizado') {
        nome.clear();
        email.clear();
        senha.clear();

        setState(() {
          cadastro = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      mensagem('Erro ao conectar com servidor');
    }
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cadastro ? 'Cadastro' : 'Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (cadastro)
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: senha,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            if (cadastro)
              DropdownButton<String>(
                value: perfil,
                items: const [
                  DropdownMenuItem(
                    value: 'produtor',
                    child: Text('Produtor'),
                  ),
                  DropdownMenuItem(
                    value: 'vendedor',
                    child: Text('Vendedor'),
                  ),
                ],
                onChanged: (valor) {
                  setState(() {
                    perfil = valor!;
                  });
                },
              ),
            ElevatedButton(
              onPressed: cadastro ? cadastrar : entrar,
              child: Text(cadastro ? 'Cadastrar' : 'Entrar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cadastro = !cadastro;
                });
              },
              child: Text(
                cadastro ? 'Voltar ao Login' : 'Criar Conta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelaPerfil extends StatelessWidget {
  final String nome;
  final String perfil;

  const TelaPerfil({
    super.key,
    required this.nome,
    required this.perfil,
  });

  Future<void> sair(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('id');
    await prefs.remove('nome');
    await prefs.remove('perfil');

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaInicial(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Área do $perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bem-vindo, $nome!'),
              Text('Perfil: $perfil'),
              if (perfil == 'produtor') const FormularioProducao(),
              if (perfil == 'vendedor') const ListaProducoes(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => sair(context),
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioProducao extends StatefulWidget {
  const FormularioProducao({super.key});

  @override
  State<FormularioProducao> createState() => _FormularioProducaoState();
}

class _FormularioProducaoState extends State<FormularioProducao> {
  final quantidade = TextEditingController();
  final valor = TextEditingController();

  final double comissao = 0.10;

  int get qtd => int.tryParse(quantidade.text) ?? 0;

  double get preco => double.tryParse(valor.text.replaceAll(',', '.')) ?? 0;

  double get total => qtd * preco;

  double get valorFinal => total - (total * comissao);

  Future<void> salvarProducao() async {
    if (qtd <= 0 || preco <= 0) {
      mostrar('Informe quantidade e valor válidos');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id');

    if (!mounted) return;

    if (id == null) {
      mostrar('Faça login novamente');
      return;
    }

    try {
      final resposta = await http.post(
        Uri.parse('$servidor/producao.php'),
        body: {
          'produtor_id': '$id',
          'quantidade': '$qtd',
          'valor': preco.toStringAsFixed(2),
        },
      );

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      mostrar(dados['mensagem']);

      if (dados['mensagem'] == 'Produção cadastrada') {
        quantidade.clear();
        valor.clear();
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      mostrar('Erro ao salvar produção');
    }
  }

  void mostrar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  void dispose() {
    quantidade.dispose();
    valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Registrar Produção',
            style: TextStyle(fontSize: 22),
          ),
          TextField(
            controller: quantidade,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade de trufas',
            ),
            onChanged: (texto) => setState(() {}),
          ),
          TextField(
            controller: valor,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor unitário',
            ),
            onChanged: (texto) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Comissão: ${(comissao * 100).toStringAsFixed(0)}%'),
          Text('Total: ${dinheiro(total)}'),
          Text('Após comissão: ${dinheiro(valorFinal)}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: salvarProducao,
            child: const Text('Salvar Produção'),
          ),
        ],
      ),
    );
  }
}

class ListaProducoes extends StatefulWidget {
  const ListaProducoes({super.key});

  @override
  State<ListaProducoes> createState() => _ListaProducoesState();
}

class _ListaProducoesState extends State<ListaProducoes> {
  List<Map<String, dynamic>> producoes = [];

  final Map<int, TextEditingController> quantidades = {};

  bool carregando = true;
  bool comprando = false;

  @override
  void initState() {
    super.initState();
    carregarProducoes();
  }

  void mostrar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> carregarProducoes() async {
    try {
      final resposta = await http.get(
        Uri.parse('$servidor/listar_producoes.php'),
      );

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      final lista = List<Map<String, dynamic>>.from(dados);

      for (final p in lista) {
        final id = int.parse('${p['id']}');

        quantidades.putIfAbsent(
          id,
          () => TextEditingController(),
        );
      }

      setState(() {
        producoes = lista;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      mostrar('Erro ao carregar produções');
    }
  }

  Future<void> comprar(int producaoId, int estoque) async {
    if (comprando) return;

    final controle = quantidades[producaoId];
    final quantidade = int.tryParse(controle?.text ?? '') ?? 0;

    if (quantidade <= 0) {
      mostrar('Informe uma quantidade válida');
      return;
    }

    if (quantidade > estoque) {
      mostrar('Estoque insuficiente');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final vendedorId = prefs.getInt('id');

    if (!mounted) return;

    if (vendedorId == null) {
      mostrar('Faça login novamente');
      return;
    }

    setState(() {
      comprando = true;
    });

    try {
      final resposta = await http.post(
        Uri.parse('$servidor/comprar.php'),
        body: {
          'vendedor_id': '$vendedorId',
          'producao_id': '$producaoId',
          'quantidade': '$quantidade',
        },
      );

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      if (dados['mensagem'] == 'Compra realizada') {
        final total = double.parse('${dados['total']}');

        mostrar('Compra realizada! Total: ${dinheiro(total)}');

        controle?.clear();
        await carregarProducoes();
      } else {
        mostrar('${dados['mensagem']}');
      }
    } catch (e) {
      if (!mounted) return;
      mostrar('Erro ao realizar compra');
    } finally {
      if (mounted) {
        setState(() {
          comprando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controle in quantidades.values) {
      controle.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Produções disponíveis',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 20),
          if (carregando) const CircularProgressIndicator(),
          if (!carregando && producoes.isEmpty)
            const Text('Nenhuma produção disponível'),
          for (final p in producoes)
            Builder(
              builder: (context) {
                final id = int.parse('${p['id']}');
                final estoque = int.parse('${p['estoque']}');
                final preco = double.parse('${p['valor_unitario']}');

                final quantidade = int.tryParse(
                      quantidades[id]?.text ?? '',
                    ) ??
                    0;

                final subtotal = quantidade * preco;
                final comissao = subtotal * 0.10;
                final total = subtotal + comissao;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text('Produtor: ${p['produtor']}'),
                        Text('Estoque: $estoque'),
                        Text('Valor unitário: ${dinheiro(preco)}'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: quantidades[id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade para comprar',
                          ),
                          onChanged: (texto) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 10),
                        Text('Subtotal: ${dinheiro(subtotal)}'),
                        Text('Comissão (10%): ${dinheiro(comissao)}'),
                        Text('Total: ${dinheiro(total)}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed:
                              comprando ? null : () => comprar(id, estoque),
                          child: const Text('Comprar Trufas'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: carregando || comprando ? null : carregarProducoes,
            child: const Text('Atualizar Produções'),
          ),
        ],
      ),
    );
  }
}
