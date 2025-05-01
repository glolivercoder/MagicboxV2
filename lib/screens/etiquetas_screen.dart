import 'package:flutter/material.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/etiqueta.dart';
import 'package:magicboxv2/services/database_helper.dart';

class EtiquetasScreen extends StatefulWidget {
  const EtiquetasScreen({super.key});

  @override
  State<EtiquetasScreen> createState() => _EtiquetasScreenState();
}

class _EtiquetasScreenState extends State<EtiquetasScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Box> _boxes = [];
  List<Box> _selectedBoxes = [];
  List<Etiqueta> _modelosEtiquetas = [];
  Etiqueta? _selectedEtiqueta;
  String _tipoConteudo = 'ID e Nome';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initModelosEtiquetas();
  }

  void _initModelosEtiquetas() {
    // Modelos Pimaco predefinidos
    _modelosEtiquetas = [
      // 3 colunas (A4)
      Etiqueta(
        nome: 'Pimaco 6182',
        alturaCm: 2.54,
        larguraCm: 6.67,
        margemSuperiorCm: 1.27,
        margemInferiorCm: 1.27,
        margemEsquerdaCm: 0.47,
        margemDireitaCm: 0.47,
        espacoEntreEtiquetasCm: 0.0,
        etiquetasPorFolha: 33,
      ),
      Etiqueta(
        nome: 'Pimaco 6183',
        alturaCm: 2.54,
        larguraCm: 6.67,
        margemSuperiorCm: 1.27,
        margemInferiorCm: 1.27,
        margemEsquerdaCm: 0.47,
        margemDireitaCm: 0.47,
        espacoEntreEtiquetasCm: 0.0,
        etiquetasPorFolha: 33,
      ),
      
      // 2 colunas (A4)
      Etiqueta(
        nome: 'Pimaco 6180',
        alturaCm: 5.08,
        larguraCm: 10.16,
        margemSuperiorCm: 1.27,
        margemInferiorCm: 1.27,
        margemEsquerdaCm: 0.47,
        margemDireitaCm: 0.47,
        espacoEntreEtiquetasCm: 0.0,
        etiquetasPorFolha: 10,
      ),
      Etiqueta(
        nome: 'Pimaco 6082',
        alturaCm: 3.39,
        larguraCm: 10.16,
        margemSuperiorCm: 1.27,
        margemInferiorCm: 1.27,
        margemEsquerdaCm: 0.47,
        margemDireitaCm: 0.47,
        espacoEntreEtiquetasCm: 0.0,
        etiquetasPorFolha: 14,
      ),
    ];

    // Selecionar o primeiro modelo por padrão
    if (_modelosEtiquetas.isNotEmpty) {
      _selectedEtiqueta = _modelosEtiquetas.first;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final boxes = await _databaseHelper.readAllBoxes();
      setState(() {
        _boxes = boxes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar caixas: $e')),
        );
      }
    }
  }

  void _toggleBoxSelection(Box box) {
    setState(() {
      if (_selectedBoxes.contains(box)) {
        _selectedBoxes.remove(box);
      } else {
        _selectedBoxes.add(box);
      }
    });
  }

  void _selectAllBoxes() {
    setState(() {
      if (_selectedBoxes.length == _boxes.length) {
        _selectedBoxes.clear();
      } else {
        _selectedBoxes = List.from(_boxes);
      }
    });
  }

  void _showModeloEtiquetaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Modelo de Etiqueta'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ExpansionTile(
                title: const Text('3 colunas (A4)'),
                initiallyExpanded: true,
                children: _modelosEtiquetas
                    .where((e) => e.nome.contains('6182') || e.nome.contains('6183'))
                    .map((e) => RadioListTile<Etiqueta>(
                          title: Text(e.nome),
                          subtitle: Text('${e.etiquetasPorFolha} por folha (${e.larguraCm} x ${e.alturaCm} cm)'),
                          value: e,
                          groupValue: _selectedEtiqueta,
                          onChanged: (value) {
                            setState(() {
                              _selectedEtiqueta = value;
                              Navigator.pop(context);
                            });
                          },
                        ))
                    .toList(),
              ),
              ExpansionTile(
                title: const Text('2 colunas (A4)'),
                initiallyExpanded: true,
                children: _modelosEtiquetas
                    .where((e) => e.nome.contains('6180') || e.nome.contains('6082'))
                    .map((e) => RadioListTile<Etiqueta>(
                          title: Text(e.nome),
                          subtitle: Text('${e.etiquetasPorFolha} por folha (${e.larguraCm} x ${e.alturaCm} cm)'),
                          value: e,
                          groupValue: _selectedEtiqueta,
                          onChanged: (value) {
                            setState(() {
                              _selectedEtiqueta = value;
                              Navigator.pop(context);
                            });
                          },
                        ))
                    .toList(),
              ),
              ExpansionTile(
                title: const Text('Modelos Personalizados'),
                initiallyExpanded: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle),
                    title: const Text('Adicionar Modelo Personalizado'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddModeloPersonalizadoDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showAddModeloPersonalizadoDialog() {
    final nomeController = TextEditingController();
    final alturaController = TextEditingController(text: '5.0');
    final larguraController = TextEditingController(text: '10.0');
    final margemSuperiorController = TextEditingController(text: '1.0');
    final margemInferiorController = TextEditingController(text: '1.0');
    final margemEsquerdaController = TextEditingController(text: '0.5');
    final margemDireitaController = TextEditingController(text: '0.5');
    final espacoEntreEtiquetasController = TextEditingController(text: '0.2');
    final etiquetasPorFolhaController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Modelo Personalizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do modelo',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: larguraController,
                      decoration: const InputDecoration(
                        labelText: 'Largura (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: alturaController,
                      decoration: const InputDecoration(
                        labelText: 'Altura (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: etiquetasPorFolhaController,
                      decoration: const InputDecoration(
                        labelText: 'Etiquetas/folha',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: espacoEntreEtiquetasController,
                      decoration: const InputDecoration(
                        labelText: 'Espaçamento (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Margens (cm):'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: margemSuperiorController,
                      decoration: const InputDecoration(
                        labelText: 'Superior',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: margemInferiorController,
                      decoration: const InputDecoration(
                        labelText: 'Inferior',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: margemEsquerdaController,
                      decoration: const InputDecoration(
                        labelText: 'Esquerda',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: margemDireitaController,
                      decoration: const InputDecoration(
                        labelText: 'Direita',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final novoModelo = Etiqueta(
                  nome: nomeController.text.isNotEmpty ? nomeController.text : 'Personalizada',
                  alturaCm: double.parse(alturaController.text),
                  larguraCm: double.parse(larguraController.text),
                  margemSuperiorCm: double.parse(margemSuperiorController.text),
                  margemInferiorCm: double.parse(margemInferiorController.text),
                  margemEsquerdaCm: double.parse(margemEsquerdaController.text),
                  margemDireitaCm: double.parse(margemDireitaController.text),
                  espacoEntreEtiquetasCm: double.parse(espacoEntreEtiquetasController.text),
                  etiquetasPorFolha: int.parse(etiquetasPorFolhaController.text),
                  personalizada: true,
                );
                
                setState(() {
                  _modelosEtiquetas.add(novoModelo);
                  _selectedEtiqueta = novoModelo;
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modelo personalizado adicionado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao adicionar modelo: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog() {
    if (_selectedBoxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma caixa para gerar etiquetas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedEtiqueta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um modelo de etiqueta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview das Etiquetas'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: _buildEtiquetasPreview(),
              ),
              const SizedBox(height: 16),
              Text(
                'Etiquetas selecionadas: ${_selectedBoxes.length} de ${_boxes.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar geração de PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gerando PDF...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Gerar PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildEtiquetasPreview() {
    if (_selectedEtiqueta == null) {
      return const Center(child: Text('Selecione um modelo de etiqueta'));
    }

    // Calcular número de colunas com base no modelo
    int numColunas = 2;
    if (_selectedEtiqueta!.nome.contains('6182') || _selectedEtiqueta!.nome.contains('6183')) {
      numColunas = 3;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: numColunas,
        childAspectRatio: _selectedEtiqueta!.larguraCm / _selectedEtiqueta!.alturaCm,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedBoxes.length,
      itemBuilder: (context, index) {
        final box = _selectedBoxes[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simulação de código de barras
              Container(
                height: 30,
                color: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${box.formattedId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_tipoConteudo != 'Apenas ID') ...[
                const SizedBox(height: 4),
                Text(
                  box.name,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seleção de caixas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Selecione as caixas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  // Implementar busca de caixas
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        _boxes.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('Nenhuma caixa cadastrada'),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _boxes.length,
                                itemBuilder: (context, index) {
                                  final box = _boxes[index];
                                  return CheckboxListTile(
                                    title: Text(box.name),
                                    subtitle: Text('#${box.formattedId}'),
                                    value: _selectedBoxes.contains(box),
                                    onChanged: (value) {
                                      _toggleBoxSelection(box);
                                    },
                                  );
                                },
                              ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  _selectedBoxes.length == _boxes.length
                                      ? Icons.deselect
                                      : Icons.select_all,
                                ),
                                label: Text(
                                  _selectedBoxes.length == _boxes.length
                                      ? 'Desmarcar Todos'
                                      : 'Selecionar Todos',
                                ),
                                onPressed: _selectAllBoxes,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Configurações de etiqueta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: _showModeloEtiquetaDialog,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Modelo de Etiqueta',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedEtiqueta?.nome ?? 'Selecione um modelo',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Formato',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButton<String>(
                                  value: _tipoConteudo,
                                  isExpanded: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoConteudo = value!;
                                    });
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Apenas ID',
                                      child: Text('Apenas ID'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ID e Nome',
                                      child: Text('ID e Nome'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ID, Nome e Conteúdo',
                                      child: Text('ID, Nome e Conteúdo'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _selectedBoxes.isEmpty
                                  ? const Center(
                                      child: Text('Selecione caixas para visualizar o preview'),
                                    )
                                  : _buildEtiquetasPreview(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _showPreviewDialog,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Visualizar PDF Completo'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botões de ação
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir'),
                        onPressed: () {
                          // Implementar impressão
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Exportar'),
                        onPressed: () {
                          // Implementar exportação
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Modelo'),
                        onPressed: _showAddModeloPersonalizadoDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
