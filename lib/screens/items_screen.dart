import 'dart:io';
import 'package:flutter/material.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';
import 'package:magicboxv2/screens/object_recognition_screen.dart';
import 'package:magicboxv2/services/database_helper.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  
  // Criar uma factory para obter uma instância com GlobalKey
  static ItemsScreen create() {
    return ItemsScreen(key: GlobalKey<ItemsScreenState>());
  }

  @override
  State<ItemsScreen> createState() => ItemsScreenState();
}

class ItemsScreenState extends State<ItemsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  List<Box> _boxes = [];
  Map<int, Box> _boxesMap = {};
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final boxes = await _databaseHelper.readAllBoxes();
      final items = await _databaseHelper.readAllItems();
      
      // Criar mapa de caixas para acesso rápido
      final boxesMap = <int, Box>{};
      for (final box in boxes) {
        if (box.id != null) {
          boxesMap[box.id!] = box;
        }
      }
      
      setState(() {
        _boxes = boxes;
        _boxesMap = boxesMap;
        _items = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _items.where((item) {
        // Filtrar por categoria se uma estiver selecionada
        if (_selectedCategory != null && _selectedCategory != 'Todas') {
          if (item.category != _selectedCategory) {
            return false;
          }
        }

        // Filtrar por texto de busca
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              (item.category?.toLowerCase().contains(query) ?? false) ||
              (item.description?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _navigateToObjectRecognition() async {
    if (_boxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário criar uma caixa antes de adicionar itens'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectRecognitionScreen(boxes: _boxes),
      ),
    );
    
    if (result != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar itens',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Filtro de categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildCategoryChip('Todas', _selectedCategory == 'Todas'),
                _buildCategoryChip('Eletrônicos', _selectedCategory == 'Eletrônicos'),
                _buildCategoryChip('Ferramentas manuais', _selectedCategory == 'Ferramentas manuais'),
                _buildCategoryChip('Ferramentas elétricas', _selectedCategory == 'Ferramentas elétricas'),
                _buildCategoryChip('Informática', _selectedCategory == 'Informática'),
                _buildCategoryChip('Diversos', _selectedCategory == 'Diversos'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de itens
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(child: Text('Nenhum item encontrado'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final box = _boxesMap[item.boxId];
                          return _buildItemCard(item, box);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToObjectRecognition,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Reconhecer objeto',
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          _selectCategory(selected ? category : null);
        },
      ),
    );
  }

  Widget _buildItemCard(Item item, Box? box) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do item
            if (item.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.image!),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image),
              ),
            const SizedBox(width: 16),
            
            // Informações do item
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.category!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (box != null)
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Caixa: ${box.name} (#${box.formattedId})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Menu de opções
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // Implementar edição de item
                } else if (value == 'delete') {
                  // Implementar exclusão de item
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Excluir'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> showAddItemDialog() async {
    if (_boxes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma caixa disponível para adicionar itens')),
        );
      }
      return;
    }
    
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    String selectedCategory = 'Diversos';
    Box? selectedBox = _boxes.first;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Item',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Ferramentas', child: Text('Ferramentas')),
                    DropdownMenuItem(value: 'Eletrônicos', child: Text('Eletrônicos')),
                    DropdownMenuItem(value: 'Documentos', child: Text('Documentos')),
                    DropdownMenuItem(value: 'Diversos', child: Text('Diversos')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Box>(
                  value: selectedBox,
                  decoration: const InputDecoration(
                    labelText: 'Caixa',
                    border: OutlineInputBorder(),
                  ),
                  items: _boxes.map((box) => DropdownMenuItem<Box>(
                    value: box,
                    child: Text('${box.name} (#${box.formattedId})'),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedBox = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome do item é obrigatório')),
                  );
                  return;
                }
                
                if (selectedBox == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione uma caixa')),
                  );
                  return;
                }
                
                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quantidade inválida')),
                  );
                  return;
                }
                
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'category': selectedCategory,
                  'description': descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  'boxId': selectedBox!.id,
                  'quantity': quantity,
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      final now = DateTime.now().toIso8601String();
      final newItem = Item(
        name: result['name'],
        category: result['category'],
        description: result['description'],
        boxId: result['boxId'],
        quantity: result['quantity'],
        createdAt: now,
      );
      
      try {
        await _databaseHelper.createItem(newItem);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item criado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar item: $e')),
          );
        }
      }
    }
  }
}
