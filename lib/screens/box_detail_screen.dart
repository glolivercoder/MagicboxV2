import 'dart:io';
import 'package:flutter/material.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';
import 'package:magicboxv2/screens/object_recognition_screen.dart';
import 'package:magicboxv2/services/database_helper.dart';
import 'package:magicboxv2/services/gemini_service.dart';
import 'package:image_picker/image_picker.dart';

class BoxDetailScreen extends StatefulWidget {
  final Box box;

  const BoxDetailScreen({super.key, required this.box});

  @override
  State<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends State<BoxDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.box.id == null) {
        throw Exception('ID da caixa não pode ser nulo');
      }
      
      final items = await _databaseHelper.readItemsByBoxId(widget.box.id!);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _items = []; // Garantir que a lista está vazia em caso de erro
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar itens: $e')),
        );
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedCategory;
    List<String> categories = ['Diversos', 'Eletrônicos', 'Documentos', 'Roupas', 'Livros'];
    
    // Carregar categorias do banco de dados
    try {
      final boxes = await _databaseHelper.readAllBoxes();
      final dbCategories = boxes
          .map((box) => box.category)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();
      
      if (dbCategories.isNotEmpty) {
        categories = dbCategories;
      }
    } catch (e) {
      // Usar categorias padrão em caso de erro
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Novo Objeto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: () {
                                // Tirar foto
                                Navigator.pop(dialogContext);
                                _navigateToObjectRecognition();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.photo_library, color: Colors.white),
                              onPressed: () {
                                // Selecionar da galeria
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nome do objeto',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categoria (opcional)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: const Color(0xFF2E2E2E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Selecione uma categoria',
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    InkWell(
                      onTap: () {
                        // Adicionar nova categoria
                        _showAddCategoryDialog(context, (newCategory) {
                          if (newCategory.isNotEmpty && !categories.contains(newCategory)) {
                            setDialogState(() {
                              categories.add(newCategory);
                              selectedCategory = newCategory;
                            });
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, color: Colors.blue, size: 16),
                            SizedBox(width: 4),
                            Text('Nova categoria', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Caixa',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white30),
                        ),
                      ),
                      child: Text(
                        '${widget.box.name} (ID: ${widget.box.id})',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Descrição (opcional)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Cancelar', style: TextStyle(color: Colors.blue)),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Salvar'),
                          onPressed: () async {
                            // Validar campos
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nome do objeto é obrigatório')),
                              );
                              return;
                            }

                            // Criar novo item
                            final newItem = Item(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              category: selectedCategory ?? widget.box.category ?? 'Diversos',
                              boxId: widget.box.id!,
                              quantity: 1, // Padrão é 1
                              createdAt: DateTime.now().toIso8601String(),
                            );

                            try {
                              // Salvar no banco de dados
                              await _databaseHelper.createItem(newItem);
                              
                              // Fechar o diálogo
                              Navigator.of(dialogContext).pop();
                              
                              // Recarregar a lista de itens
                              await _loadItems();
                              
                              // Mostrar mensagem de sucesso
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Objeto adicionado com sucesso!')),
                                );
                              }
                            } catch (e) {
                              // Mostrar erro
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao adicionar objeto: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Método para adicionar nova categoria
  Future<void> _showAddCategoryDialog(BuildContext context, Function(String) onCategoryAdded) async {
    final TextEditingController categoryController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          title: const Text('Nova Categoria', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: categoryController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nome da categoria',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Adicionar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                final newCategory = categoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  onCategoryAdded(newCategory);
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _navigateToObjectRecognition() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectRecognitionScreen(
          imagePath: image.path,
          boxId: widget.box.id!,
          onItemAdded: () {
            _loadItems(); // Recarregar itens quando um novo for adicionado
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Objetos (${_items.length})'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {
              // Alternar entre visualização em lista e grade
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Editar caixa
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Abrir menu de adição de item
          _showAddOptions();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return _buildEmptyState();
    } else {
      return ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildItemCard(item);
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum objeto nesta caixa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Identificar com câmera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _navigateToObjectRecognition,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar manualmente'),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Identificar com câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToObjectRecognition();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Adicionar manualmente'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
          child: item.image != null
              ? ClipOval(
                  child: Image.file(
                    File(item.image!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.inventory,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: item.description != null && item.description!.isNotEmpty
            ? Text(item.description!)
            : null,
        trailing: Text(
          'Qtd: ${item.quantity}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        onTap: () {
          // Mostrar detalhes do item
        },
      ),
    );
  }
}
