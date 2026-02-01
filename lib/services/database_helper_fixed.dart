import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';
import 'package:magicboxv2/models/user.dart';
import 'package:magicboxv2/services/log_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final LogService _logService = LogService.instance;

  DatabaseHelper._init();

  // Flag para controlar a inicialização do banco
  static bool _databaseInitializing = false;
  
  // Flag para controlar a inicialização de dados
  static bool _initialDataChecked = false;
  
  Future<Database> get database async {
    // Retornar o banco existente se já estiver inicializado
    if (_database != null) return _database!;
    
    // Evitar inicializações simultâneas
    if (_databaseInitializing) {
      // Aguardar até que a inicialização seja concluída por outra chamada
      while (_databaseInitializing && _database == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_database != null) return _database!;
    }
    
    // Marcar que estamos iniciando a inicialização
    _databaseInitializing = true;
    
    try {
      _logService.info('Inicializando banco de dados', category: 'database');
      
      // A inicialização do sqflite já foi feita no main.dart
      // Aqui apenas obtemos a conexão com o banco
      
      String path;
      
      if (kIsWeb) {
        // No ambiente web, usamos um nome simples
        path = 'magicbox.db';
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Em dispositivos móveis, usamos o diretório de documentos
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, 'magicbox.db');
      } else {
        // Em desktop, usamos o diretório padrão de bancos de dados
        final dbPath = await getDatabasesPath();
        path = join(dbPath, 'magicbox.db');
      }
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
      
      // Verificar se há dados iniciais e inserir se necessário
      await _ensureInitialData();
      
      // Finalizar a inicialização
      _databaseInitializing = false;
      return _database!;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao inicializar banco de dados: $e',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
      
      // Em caso de erro, criar banco em memória como fallback
      try {
        _database = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: _createDB,
        );
        
        // Inserir dados iniciais no banco em memória
        await _ensureInitialData();
      } catch (innerError) {
        _logService.error(
          'Erro ao criar banco em memória: $innerError',
          error: innerError,
          category: 'database',
        );
      }
      
      // Finalizar a inicialização mesmo em caso de erro
      _databaseInitializing = false;
      
      if (_database != null) {
        return _database!;
      } else {
        throw Exception('Falha ao inicializar banco de dados');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    _logService.info('Criando tabelas do banco de dados', category: 'database');
    
    // Criar tabela de caixas
    await db.execute('''
      CREATE TABLE boxes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        image TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        barcode_data_url TEXT
      )
    ''');
    
    // Criar tabela de itens
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        description TEXT,
        image TEXT,
        box_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (box_id) REFERENCES boxes (id) ON DELETE CASCADE
      )
    ''');
    
    // Criar tabela de usuários
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar TEXT,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    _logService.info('Tabelas criadas com sucesso', category: 'database');
  }

  Future<void> _ensureInitialData() async {
    if (_initialDataChecked) return;
    
    try {
      final db = await database;
      
      // Verificar se já existem usuários
      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users')
      );
      
      // Se não houver usuários, criar um usuário admin padrão
      if (userCount == 0) {
        _logService.info('Criando usuário admin padrão', category: 'database');
        
        await db.insert('users', {
          'name': 'Admin',
          'email': 'admin@magicbox.com',
          'is_admin': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      _initialDataChecked = true;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao verificar/inserir dados iniciais',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
    }
  }

  // CRUD para caixas
  Future<Box> createBox(Box box) async {
    final db = await database;
    final id = await db.insert('boxes', box.toMap());
    _logService.info('Caixa criada com ID: $id', category: 'database');
    return box.copyWith(id: id);
  }

  Future<Box?> readBox(int id) async {
    final db = await database;
    final maps = await db.query(
      'boxes',
      columns: ['id', 'name', 'category', 'description', 'image', 'created_at', 'updated_at', 'barcode_data_url'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Box.fromMap(maps.first);
    } else {
      _logService.warning('Caixa com ID $id não encontrada', category: 'database');
      return null;
    }
  }

  Future<List<Box>> readAllBoxes() async {
    final db = await database;
    final result = await db.query('boxes');
    return result.map((map) => Box.fromMap(map)).toList();
  }

  Future<List<Box>> searchBoxes(String query) async {
    final db = await database;
    final result = await db.query(
      'boxes',
      where: 'name LIKE ? OR category LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((map) => Box.fromMap(map)).toList();
  }

  Future<List<Box>> getBoxesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'boxes',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((map) => Box.fromMap(map)).toList();
  }

  Future<Box?> readBoxById(int id) async {
    return await readBox(id);
  }

  Future<int> updateBox(Box box) async {
    final db = await database;
    final result = await db.update(
      'boxes',
      box.toMap(),
      where: 'id = ?',
      whereArgs: [box.id],
    );
    _logService.info('Caixa atualizada com ID: ${box.id}', category: 'database');
    return result;
  }

  Future<int> deleteBox(int id) async {
    final db = await database;
    final result = await db.delete(
      'boxes',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('Caixa excluída com ID: $id', category: 'database');
    return result;
  }

  // CRUD para itens
  Future<Item> createItem(Item item) async {
    final db = await database;
    final id = await db.insert('items', item.toMap());
    _logService.info('Item criado com ID: $id', category: 'database');
    return item.copyWith(id: id);
  }

  Future<Item?> readItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'items',
      columns: ['id', 'name', 'category', 'description', 'image', 'box_id', 'quantity', 'created_at', 'updated_at'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    } else {
      _logService.warning('Item com ID $id não encontrado', category: 'database');
      return null;
    }
  }

  Future<List<Item>> readAllItems() async {
    final db = await database;
    final result = await db.query('items');
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<List<Item>> readItemsByBoxId(int boxId) async {
    final db = await database;
    final result = await db.query(
      'items',
      where: 'box_id = ?',
      whereArgs: [boxId],
    );
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final db = await database;
    final result = await db.query(
      'items',
      where: 'name LIKE ? OR category LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    final result = await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    _logService.info('Item atualizado com ID: ${item.id}', category: 'database');
    return result;
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    final result = await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('Item excluído com ID: $id', category: 'database');
    return result;
  }

  Future<int> deleteItemsByBoxId(int boxId) async {
    final db = await database;
    final result = await db.delete(
      'items',
      where: 'box_id = ?',
      whereArgs: [boxId],
    );
    _logService.info('Itens excluídos da caixa com ID: $boxId', category: 'database');
    return result;
  }

  // CRUD para usuários
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    _logService.info('Usuário criado com ID: $id', category: 'database');
    return user.copyWith(id: id);
  }

  Future<User?> readUser(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      columns: ['id', 'name', 'email', 'avatar', 'is_admin', 'created_at', 'updated_at'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      _logService.warning('Usuário com ID $id não encontrado', category: 'database');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      columns: ['id', 'name', 'email', 'avatar', 'is_admin', 'created_at', 'updated_at'],
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<User>> readAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final result = await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    _logService.info('Usuário atualizado com ID: ${user.id}', category: 'database');
    return result;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    final result = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('Usuário excluído com ID: $id', category: 'database');
    return result;
  }

  // Métodos de utilidade
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    if (_database != null) {
      await close();
    }

    if (kIsWeb) {
      // No ambiente web, não podemos excluir o banco diretamente
      _logService.warning('Exclusão de banco de dados não suportada no ambiente web', category: 'database');
      return;
    }

    try {
      String path;
      
      if (Platform.isAndroid || Platform.isIOS) {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, 'magicbox.db');
      } else {
        final dbPath = await getDatabasesPath();
        path = join(dbPath, 'magicbox.db');
      }
      
      await File(path).delete();
      _logService.info('Banco de dados excluído com sucesso', category: 'database');
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao excluir banco de dados',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
    }
  }
}
