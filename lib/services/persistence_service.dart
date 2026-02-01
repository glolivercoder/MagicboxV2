import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';
import 'package:magicboxv2/models/user.dart';
import 'package:magicboxv2/services/log_service.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;

  final LogService _logService = LogService.instance;

  PersistenceService._internal();

  // Chaves para armazenamento
  static const String _boxesKey = 'magicboxv2_boxes_persistent';
  static const String _itemsKey = 'magicboxv2_items_persistent';
  static const String _usersKey = 'magicboxv2_users_persistent';
  static const String _lastSyncKey = 'magicboxv2_last_sync';
  static const String _backupDirPrefKey = 'backup_directory_path';

  // Pasta de backups - pasta fixa na raiz do projeto
  static const String _backupFolderName = 'LogsMagicboxV2/backups';

  // Método para obter o diretório de backup
  Future<Directory> _getBackupDirectory() async {
    Directory backupDir;

    if (kIsWeb) {
      // No ambiente web, não podemos acessar o sistema de arquivos diretamente
      // Retornamos um diretório temporário que não será usado
      _logService.warning('Ambiente web detectado, backups serão armazenados em memória', category: 'backup');
      backupDir = Directory('web_backup_dir');
      return backupDir;
    }

    // Verificar se existe um diretório personalizado salvo nas preferências
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_backupDirPrefKey);

    if (customPath != null && customPath.isNotEmpty) {
      // Usar o diretório personalizado
      backupDir = Directory(customPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    }

    // Usar o diretório padrão
    try {
      // Em dispositivos móveis, usar o diretório de documentos
      if (Platform.isAndroid || Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        backupDir = Directory('${appDir.path}/$_backupFolderName');
      } else {
        // Em desktop, tentar usar o diretório raiz do aplicativo
        final appDir = await getApplicationDocumentsDirectory();
        final rootDir = Directory(appDir.path).parent.parent.parent.parent;
        backupDir = Directory('${rootDir.path}/$_backupFolderName');
      }

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      return backupDir;
    } catch (e) {
      _logService.error('Erro ao obter diretório de backup: $e', category: 'backup');
      
      // Fallback: usar o diretório temporário
      final tempDir = await getTemporaryDirectory();
      backupDir = Directory('${tempDir.path}/$_backupFolderName');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    }
  }

  // Salvar dados em SharedPreferences
  Future<bool> saveBoxes(List<Box> boxes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converter a lista de caixas para JSON
      final List<Map<String, dynamic>> boxesMap = boxes.map((box) => box.toMap()).toList();
      final String boxesJson = jsonEncode(boxesMap);
      
      // Salvar no SharedPreferences
      await prefs.setString(_boxesKey, boxesJson);
      
      // Atualizar timestamp de sincronização
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      _logService.info('${boxes.length} caixas salvas com sucesso', category: 'persistence');
      
      // Criar backup automático
      await _createBackup(boxes, [], []);
      
      return true;
    } catch (e) {
      _logService.error('Erro ao salvar caixas: $e', category: 'persistence');
      return false;
    }
  }

  Future<bool> saveItems(List<Item> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converter a lista de itens para JSON
      final List<Map<String, dynamic>> itemsMap = items.map((item) => item.toMap()).toList();
      final String itemsJson = jsonEncode(itemsMap);
      
      // Salvar no SharedPreferences
      await prefs.setString(_itemsKey, itemsJson);
      
      // Atualizar timestamp de sincronização
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      _logService.info('${items.length} itens salvos com sucesso', category: 'persistence');
      
      return true;
    } catch (e) {
      _logService.error('Erro ao salvar itens: $e', category: 'persistence');
      return false;
    }
  }

  Future<bool> saveUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converter a lista de usuários para JSON
      final List<Map<String, dynamic>> usersMap = users.map((user) => user.toMap()).toList();
      final String usersJson = jsonEncode(usersMap);
      
      // Salvar no SharedPreferences
      await prefs.setString(_usersKey, usersJson);
      
      // Atualizar timestamp de sincronização
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      _logService.info('${users.length} usuários salvos com sucesso', category: 'persistence');
      
      return true;
    } catch (e) {
      _logService.error('Erro ao salvar usuários: $e', category: 'persistence');
      return false;
    }
  }

  // Carregar dados do SharedPreferences
  Future<List<Box>> loadBoxes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? boxesJson = prefs.getString(_boxesKey);
      
      if (boxesJson == null || boxesJson.isEmpty) {
        _logService.info('Nenhuma caixa encontrada no armazenamento persistente', category: 'persistence');
        return [];
      }
      
      // Decodificar JSON para lista de mapas
      final List<dynamic> boxesList = jsonDecode(boxesJson);
      
      // Converter mapas para objetos Box
      final List<Box> boxes = boxesList.map((boxMap) => Box.fromMap(boxMap)).toList();
      
      _logService.info('${boxes.length} caixas carregadas com sucesso', category: 'persistence');
      
      return boxes;
    } catch (e) {
      _logService.error('Erro ao carregar caixas: $e', category: 'persistence');
      return [];
    }
  }

  Future<List<Item>> loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_itemsKey);
      
      if (itemsJson == null || itemsJson.isEmpty) {
        _logService.info('Nenhum item encontrado no armazenamento persistente', category: 'persistence');
        return [];
      }
      
      // Decodificar JSON para lista de mapas
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      
      // Converter mapas para objetos Item
      final List<Item> items = itemsList.map((itemMap) => Item.fromMap(itemMap)).toList();
      
      _logService.info('${items.length} itens carregados com sucesso', category: 'persistence');
      
      return items;
    } catch (e) {
      _logService.error('Erro ao carregar itens: $e', category: 'persistence');
      return [];
    }
  }

  Future<List<User>> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null || usersJson.isEmpty) {
        _logService.info('Nenhum usuário encontrado no armazenamento persistente', category: 'persistence');
        return [];
      }
      
      // Decodificar JSON para lista de mapas
      final List<dynamic> usersList = jsonDecode(usersJson);
      
      // Converter mapas para objetos User
      final List<User> users = usersList.map((userMap) => User.fromMap(userMap)).toList();
      
      _logService.info('${users.length} usuários carregados com sucesso', category: 'persistence');
      
      return users;
    } catch (e) {
      _logService.error('Erro ao carregar usuários: $e', category: 'persistence');
      return [];
    }
  }

  // Carregar todos os dados
  Future<Map<String, List<dynamic>>> loadAllData() async {
    final boxes = await loadBoxes();
    final items = await loadItems();
    final users = await loadUsers();
    
    return {
      'boxes': boxes,
      'items': items,
      'users': users,
    };
  }

  // Criar backup dos dados
  Future<bool> _createBackup(List<Box> boxes, List<Item> items, List<User> users) async {
    if (kIsWeb) {
      _logService.info('Backup não disponível no ambiente web', category: 'backup');
      return false;
    }
    
    try {
      final backupDir = await _getBackupDirectory();
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupFileName = 'magicbox_backup_$timestamp.json';
      
      // Preparar dados para backup
      final Map<String, dynamic> backupData = {
        'timestamp': now.toIso8601String(),
        'boxes': boxes.map((box) => box.toMap()).toList(),
        'items': items.map((item) => item.toMap()).toList(),
        'users': users.map((user) => user.toMap()).toList(),
      };
      
      // Converter para JSON
      final String backupJson = jsonEncode(backupData);
      
      // Salvar arquivo
      final File backupFile = File('${backupDir.path}/$backupFileName');
      await backupFile.writeAsString(backupJson);
      
      _logService.info('Backup criado com sucesso: $backupFileName', category: 'backup');
      
      // Limpar backups antigos (manter apenas os 10 mais recentes)
      await _cleanupOldBackups();
      
      return true;
    } catch (e) {
      _logService.error('Erro ao criar backup: $e', category: 'backup');
      return false;
    }
  }

  // Limpar backups antigos
  Future<void> _cleanupOldBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().toList();
      
      // Filtrar apenas arquivos de backup
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json') && file.path.contains('magicbox_backup_'))
          .toList();
      
      // Ordenar por data de modificação (mais recente primeiro)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Manter apenas os 10 mais recentes
      if (backupFiles.length > 10) {
        for (int i = 10; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
          _logService.info('Backup antigo removido: ${backupFiles[i].path}', category: 'backup');
        }
      }
    } catch (e) {
      _logService.error('Erro ao limpar backups antigos: $e', category: 'backup');
    }
  }

  // Listar backups disponíveis
  Future<List<Map<String, String>>> listBackups() async {
    if (kIsWeb) {
      return [];
    }
    
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().toList();
      
      // Filtrar apenas arquivos de backup
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json') && file.path.contains('magicbox_backup_'))
          .toList();
      
      // Ordenar por data de modificação (mais recente primeiro)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Converter para lista de mapas com informações do backup
      final backups = backupFiles.map((file) {
        final fileName = file.path.split('/').last;
        final dateStr = fileName.replaceAll('magicbox_backup_', '').replaceAll('.json', '');
        
        // Extrair data do nome do arquivo
        String formattedDate = '';
        if (dateStr.length >= 14) {
          final year = dateStr.substring(0, 4);
          final month = dateStr.substring(4, 6);
          final day = dateStr.substring(6, 8);
          final hour = dateStr.substring(9, 11);
          final minute = dateStr.substring(11, 13);
          
          formattedDate = '$day/$month/$year $hour:$minute';
        } else {
          formattedDate = file.lastModifiedSync().toString();
        }
        
        return {
          'path': file.path,
          'name': fileName,
          'date': formattedDate,
        };
      }).toList();
      
      return backups;
    } catch (e) {
      _logService.error('Erro ao listar backups: $e', category: 'backup');
      return [];
    }
  }

  // Restaurar dados de um backup
  Future<Map<String, List<dynamic>>?> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        _logService.error('Arquivo de backup não encontrado: $backupPath', category: 'backup');
        return null;
      }
      
      // Ler conteúdo do arquivo
      final String backupJson = await file.readAsString();
      
      // Decodificar JSON
      final Map<String, dynamic> backupData = jsonDecode(backupJson);
      
      // Extrair dados
      final List<dynamic> boxesData = backupData['boxes'] ?? [];
      final List<dynamic> itemsData = backupData['items'] ?? [];
      final List<dynamic> usersData = backupData['users'] ?? [];
      
      // Converter para objetos
      final List<Box> boxes = boxesData.map((boxMap) => Box.fromMap(boxMap)).toList();
      final List<Item> items = itemsData.map((itemMap) => Item.fromMap(itemMap)).toList();
      final List<User> users = usersData.map((userMap) => User.fromMap(userMap)).toList();
      
      _logService.info(
        'Backup restaurado com sucesso: ${boxes.length} caixas, ${items.length} itens, ${users.length} usuários',
        category: 'backup'
      );
      
      // Salvar dados restaurados
      await saveBoxes(boxes);
      await saveItems(items);
      await saveUsers(users);
      
      return {
        'boxes': boxes,
        'items': items,
        'users': users,
      };
    } catch (e) {
      _logService.error('Erro ao restaurar backup: $e', category: 'backup');
      return null;
    }
  }
}
