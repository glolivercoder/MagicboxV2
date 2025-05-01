import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';
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

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      _logService.info('Inicializando banco de dados', category: 'database');
      
      // Inicialização simplificada para todas as plataformas
      if (kIsWeb) {
        // Configuração web usando databaseFactoryFfi
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _database = await openDatabase(
          'magicbox.db',
          version: 1,
          onCreate: _createDB,
        );
      } else {
        // Configuração para dispositivos móveis e desktop
        String path;
        if (Platform.isAndroid || Platform.isIOS) {
          // Usar getApplicationDocumentsDirectory para mobile
          final documentsDirectory = await getApplicationDocumentsDirectory();
          path = join(documentsDirectory.path, 'magicbox.db');
        } else {
          // Usar getDatabasesPath para desktop
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          final dbPath = await getDatabasesPath();
          path = join(dbPath, 'magicbox.db');
        }
        
        _database = await openDatabase(
          path,
          version: 1,
          onCreate: _createDB,
        );
      }
      
      // Verificar se há dados iniciais e inserir se necessário
      await _ensureInitialData();
      
      return _database!;
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao inicializar banco de dados, usando banco em memória',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
      
      // Em caso de erro, criar banco em memória como fallback
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB,
      );
      
      // Inserir dados iniciais no banco em memória
      await _ensureInitialData();
      
      return _database!;
    }
  }
  
  // Garantir que os dados iniciais existam
  Future<void> _ensureInitialData() async {
    try {
      if (_database == null) {
        _logService.error('Banco de dados não inicializado', category: 'database');
        return;
      }
      
      final db = _database!;
      
      // Verificar se já existem caixas no banco
      final existingBoxes = await db.query('boxes');
      
      if (existingBoxes.isEmpty) {
        _logService.info('Nenhuma caixa encontrada, inserindo dados iniciais', category: 'database');
        await _insertInitialData(db);
        _logService.info('Dados iniciais inseridos com sucesso', category: 'database');
      } else {
        _logService.info('Dados iniciais já existem (${existingBoxes.length} caixas encontradas)', category: 'database');
      }
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao verificar dados iniciais',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      avatar TEXT,
      isAdmin INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE boxes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      image TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT,
      barcodeDataUrl TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      category TEXT,
      box_id INTEGER,
      quantity INTEGER DEFAULT 1,
      created_at TEXT,
      FOREIGN KEY (box_id) REFERENCES boxes (id) ON DELETE CASCADE
    )
    ''');

    _logService.info('Database created successfully', category: 'database');
    
    // Inserir dados iniciais
    await _insertInitialData(db);
  }

  // Método para inserir dados iniciais no banco de dados
  Future<void> _insertInitialData(Database db) async {
    try {
      _logService.info('Inserindo dados iniciais no banco de dados', category: 'database');
      
      final existingBoxes = await db.query('boxes');
      if (existingBoxes.isNotEmpty) {
        _logService.info('Dados iniciais já existem, pulando inserção', category: 'database');
        return;
      }
      
      // Inserir caixa padrão "Itens diversos"
      final now = DateTime.now().toIso8601String();
      
      final boxId = await db.rawInsert(
        'INSERT INTO boxes (name, description, category, created_at) VALUES (?, ?, ?, ?)',
        ['Itens diversos', 'Caixa para itens diversos', 'Diversos', now]
      );
      
      _logService.info('Caixa inicial criada com ID: $boxId', category: 'database');
      
      // Inserir alguns itens de exemplo na caixa
      final item1Id = await db.rawInsert(
        'INSERT INTO items (name, description, category, box_id, quantity, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['Caneta azul', 'Caneta esferográfica azul', 'Diversos', boxId, 1, now]
      );
      
      final item2Id = await db.rawInsert(
        'INSERT INTO items (name, description, category, box_id, quantity, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        ['Bloco de notas', 'Bloco de notas pequeno', 'Diversos', boxId, 1, now]
      );
      
      _logService.info('Itens iniciais criados com IDs: $item1Id, $item2Id', category: 'database');
      _logService.info('Dados iniciais inseridos com sucesso', category: 'database');
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao inserir dados iniciais',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
      // Tentar novamente com uma abordagem alternativa em caso de erro
      try {
        final boxMap = {
          'name': 'Itens diversos',
          'description': 'Caixa para itens diversos',
          'category': 'Diversos',
          'created_at': DateTime.now().toIso8601String(),
        };
        
        final boxId = await db.insert('boxes', boxMap);
        
        final item1Map = {
          'name': 'Caneta azul',
          'description': 'Caneta esferográfica azul',
          'category': 'Diversos',
          'box_id': boxId,
          'quantity': 1,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        final item2Map = {
          'name': 'Bloco de notas',
          'description': 'Bloco de notas pequeno',
          'category': 'Diversos',
          'box_id': boxId,
          'quantity': 1,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        await db.insert('items', item1Map);
        await db.insert('items', item2Map);
        
        _logService.info('Dados iniciais inseridos com abordagem alternativa', category: 'database');
      } catch (e2) {
        _logService.error('Falha na segunda tentativa de inserir dados iniciais: $e2', category: 'database');
      }
    }
  }
  
  // CRUD para Boxes
  Future<Box> createBox(Box box) async {
    final db = await database;
    final id = await db.insert('boxes', box.toMap());
    _logService.info('Box created with ID: $id', category: 'database');
    return box.copyWith(id: id);
  }

  Future<Box?> readBox(int id) async {
    final db = await database;
    final maps = await db.query(
      'boxes',
      columns: ['id', 'name', 'category', 'description', 'image', 'createdAt', 'updatedAt', 'barcodeDataUrl'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Box.fromMap(maps.first);
    } else {
      _logService.warning('Box with ID $id not found', category: 'database');
      return null;
    }
  }

  Future<List<Box>> readAllBoxes() async {
    final db = await database;
    final result = await db.query('boxes', orderBy: 'id ASC');
    return result.map((map) => Box.fromMap(map)).toList();
  }

  Future<List<Box>> searchBoxes(String query) async {
    final db = await database;
    final result = await db.query(
      'boxes',
      where: 'name LIKE ? OR description LIKE ? OR category LIKE ? OR id LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'id ASC',
    );
    return result.map((map) => Box.fromMap(map)).toList();
  }

  Future<List<Box>> getBoxesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'boxes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'id ASC',
    );
    return result.map((map) => Box.fromMap(map)).toList();
  }
  
  Future<Box?> readBoxById(int id) async {
    return readBox(id);
  }

  Future<int> updateBox(Box box) async {
    final db = await database;
    final result = await db.update(
      'boxes',
      box.toMap(),
      where: 'id = ?',
      whereArgs: [box.id],
    );
    _logService.info('Box updated with ID: ${box.id}', category: 'database');
    return result;
  }

  Future<int> deleteBox(int id) async {
    final db = await database;
    final result = await db.delete(
      'boxes',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('Box deleted with ID: $id', category: 'database');
    return result;
  }

  // CRUD para Items
  Future<Item> createItem(Item item) async {
    final db = await database;
    final id = await db.insert('items', item.toMap());
    _logService.info('Item created with ID: $id', category: 'database');
    return item.copyWith(id: id);
  }

  Future<Item?> readItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'items',
      columns: ['id', 'name', 'category', 'description', 'image', 'boxId', 'createdAt', 'updatedAt'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    } else {
      _logService.warning('Item with ID $id not found', category: 'database');
      return null;
    }
  }

  Future<List<Item>> readAllItems() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'id ASC');
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<List<Item>> getItemsByBoxId(int boxId) async {
    final db = await database;
    final result = await db.query(
      'items',
      where: 'boxId = ?',
      whereArgs: [boxId],
      orderBy: 'id ASC',
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
    _logService.info('Item updated with ID: ${item.id}', category: 'database');
    return result;
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    final result = await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('Item deleted with ID: $id', category: 'database');
    return result;
  }

  // CRUD para Users
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    _logService.info('User created with ID: $id', category: 'database');
    return user.copyWith(id: id);
  }

  Future<User?> readUser(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      columns: ['id', 'name', 'email', 'avatar', 'isAdmin', 'createdAt', 'updatedAt'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      _logService.warning('User with ID $id not found', category: 'database');
      return null;
    }
  }

  Future<List<User>> readAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'id ASC');
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
    _logService.info('User updated with ID: ${user.id}', category: 'database');
    return result;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    final result = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logService.info('User deleted with ID: $id', category: 'database');
    return result;
  }

  // Métodos de fechamento
  Future close() async {
    final db = await instance.database;
    db.close();
    _logService.info('Database closed', category: 'database');
  }
  
  /// Otimiza o banco de dados para dispositivos móveis
  /// Especialmente para Samsung M52 e dispositivos similares
  Future<void> optimizeForMobile() async {
    if (!Platform.isAndroid) return;
    
    try {
      final db = await database;
      
      // Configurar pragmas para otimização em dispositivos Android
      await db.execute('PRAGMA synchronous = NORMAL'); // Reduz sincronização com disco
      await db.execute('PRAGMA journal_mode = WAL'); // Write-Ahead Logging para melhor performance
      await db.execute('PRAGMA cache_size = 10000'); // Aumentar cache para dispositivos com mais RAM
      await db.execute('PRAGMA temp_store = MEMORY'); // Armazenar tabelas temporárias na memória
      await db.execute('PRAGMA mmap_size = 30000000'); // Usar mmap para dispositivos com mais RAM
      
      // Criar índices para consultas frequentes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_boxes_category ON boxes(category)'); 
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_boxId ON items(boxId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_category ON items(category)');
      
      _logService.info('Banco de dados otimizado para dispositivos móveis', category: 'database');
    } catch (e, stackTrace) {
      _logService.error(
        'Erro ao otimizar banco de dados para dispositivos móveis',
        error: e,
        stackTrace: stackTrace,
        category: 'database',
      );
    }
  }
}
