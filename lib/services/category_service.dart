import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magicboxv2/services/log_service.dart';

class CategoryService {
  static final CategoryService instance = CategoryService._internal();
  
  factory CategoryService() => instance;
  
  CategoryService._internal();
  
  final LogService _logService = LogService.instance;
  final String _categoriesKey = 'magicbox_categories';
  
  // Categorias padrão
  final List<String> _defaultCategories = [
    'Diversos',
    'Ferramentas',
    'Eletrônicos',
    'Documentos',
  ];
  
  // Método para obter todas as categorias
  Future<List<String>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = prefs.getStringList(_categoriesKey);
      
      if (categories == null || categories.isEmpty) {
        // Se não houver categorias salvas, retornar as categorias padrão
        await saveCategories(_defaultCategories);
        return _defaultCategories;
      }
      
      return categories;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao obter categorias',
        error: e,
        stackTrace: stackTrace,
        category: 'category_service',
      );
      // Em caso de erro, retornar as categorias padrão
      return _defaultCategories;
    }
  }
  
  // Método para adicionar uma nova categoria
  Future<bool> addCategory(String category) async {
    try {
      if (category.trim().isEmpty) {
        return false;
      }
      
      final categories = await getCategories();
      
      // Verificar se a categoria já existe (ignorando maiúsculas/minúsculas)
      if (categories.any((c) => c.toLowerCase() == category.trim().toLowerCase())) {
        return false;
      }
      
      // Adicionar a nova categoria
      categories.add(category.trim());
      
      // Salvar a lista atualizada
      final result = await saveCategories(categories);
      
      if (result) {
        _logService.info(
          'Nova categoria adicionada: $category',
          category: 'category_service',
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao adicionar categoria',
        error: e,
        stackTrace: stackTrace,
        category: 'category_service',
      );
      return false;
    }
  }
  
  // Método para remover uma categoria
  Future<bool> removeCategory(String category) async {
    try {
      final categories = await getCategories();
      
      // Não permitir remover categorias padrão
      if (_defaultCategories.contains(category)) {
        _logService.warning(
          'Tentativa de remover categoria padrão: $category',
          category: 'category_service',
        );
        return false;
      }
      
      // Remover a categoria
      final removed = categories.remove(category);
      
      if (!removed) {
        return false;
      }
      
      // Salvar a lista atualizada
      final result = await saveCategories(categories);
      
      if (result) {
        _logService.info(
          'Categoria removida: $category',
          category: 'category_service',
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao remover categoria',
        error: e,
        stackTrace: stackTrace,
        category: 'category_service',
      );
      return false;
    }
  }
  
  // Método para salvar a lista de categorias
  Future<bool> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setStringList(_categoriesKey, categories);
      
      return result;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao salvar categorias',
        error: e,
        stackTrace: stackTrace,
        category: 'category_service',
      );
      return false;
    }
  }
}
