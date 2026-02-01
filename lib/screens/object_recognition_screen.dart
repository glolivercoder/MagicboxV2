import 'dart:io';
import 'package:flutter/material.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';
import 'package:magicboxv2/services/database_helper.dart';
import 'package:magicboxv2/services/gemini_service.dart';
import 'package:path_provider/path_provider.dart';

class ObjectRecognitionScreen extends StatefulWidget {
  final String imagePath;
  final int boxId;
  final Function? onItemAdded;
  
  const ObjectRecognitionScreen({
    super.key,
    required this.imagePath,
    required this.boxId,
    this.onItemAdded,
  });

  @override
  State<ObjectRecognitionScreen> createState() => _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  final GeminiService _geminiService = GeminiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  bool _isProcessing = true;
  String? _errorMessage;
  Map<String, dynamic>? _objectInfo;
  Box? _currentBox;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBoxInfo();
    _processImage();
  }

  Future<void> _loadBoxInfo() async {
    try {
      final box = await _databaseHelper.readBox(widget.boxId);
      setState(() {
        _currentBox = box;
        _selectedCategory = box?.category;
      });
    } catch (e) {
      print('Erro ao carregar informações da caixa: $e');
    }
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final File imageFile = File(widget.imagePath);
      
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }
      
      // Processar a imagem com o Gemini
      final result = await _geminiService.recognizeObject(imageFile.path);
      
      if (result != null) {
        setState(() {
          _objectInfo = result;
          _nameController.text = result['name'] ?? '';
          _descriptionController.text = result['description'] ?? '';
          _isProcessing = false;
        });
      } else {
        throw Exception('Não foi possível reconhecer o objeto');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Erro ao processar imagem: $e';
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Salvar a imagem localmente
      final String savedImagePath = await _saveImageLocally(widget.imagePath);
      
      // Criar o novo item
      final newItem = Item(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? _currentBox?.category ?? 'Diversos',
        boxId: widget.boxId,
        quantity: 1,
        image: savedImagePath,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Salvar no banco de dados
      final savedItem = await _databaseHelper.createItem(newItem);
      
      // Chamar o callback se fornecido
      if (widget.onItemAdded != null) {
        widget.onItemAdded!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Objeto adicionado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Erro ao salvar item: $e';
      });
    }
  }

  Future<String> _saveImageLocally(String imagePath) async {
    try {
      final File sourceFile = File(imagePath);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = '${appDir.path}/images/$fileName';
      
      // Garantir que o diretório existe
      final Directory imageDir = Directory('${appDir.path}/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // Copiar o arquivo
      final File targetFile = await sourceFile.copy(targetPath);
      return targetFile.path;
    } catch (e) {
      print('Erro ao salvar imagem: $e');
      return imagePath; // Retornar o caminho original em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificação de Objeto'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analisando imagem com IA...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagem capturada
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(widget.imagePath),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Informações do objeto
                        const Text(
                          'Objeto Identificado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nome
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do objeto *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nome é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Categoria
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            if (_currentBox?.category != null)
                              DropdownMenuItem(
                                value: _currentBox!.category,
                                child: Text(_currentBox!.category!),
                              ),
                            const DropdownMenuItem(
                              value: 'Diversos',
                              child: Text('Diversos'),
                            ),
                            const DropdownMenuItem(
                              value: 'Eletrônicos',
                              child: Text('Eletrônicos'),
                            ),
                            const DropdownMenuItem(
                              value: 'Documentos',
                              child: Text('Documentos'),
                            ),
                            const DropdownMenuItem(
                              value: 'Roupas',
                              child: Text('Roupas'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Descrição
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        
                        // Botões
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
