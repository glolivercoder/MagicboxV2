import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:magicboxv2/screens/main_screen.dart';
import 'package:magicboxv2/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Variável global para controlar se estamos usando fallback em memória
bool useInMemoryDatabase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o sqflite para diferentes plataformas
  if (kIsWeb) {
    try {
      // Definir o caminho para os arquivos SQLite no ambiente web
      print('Inicializando SQLite para web...');
      
      // Inicialização específica para web usando sqflite_common_ffi_web
      databaseFactory = databaseFactoryFfiWeb;
      
      // Testar se o SQLite está funcionando corretamente
      final db = await openDatabase('test.db');
      await db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY)');
      await db.close();
      
      print('SQLite para web inicializado com sucesso!');
    } catch (e) {
      // Se falhar, usar dados em memória como fallback
      print('ERRO ao inicializar SQLite para web: $e');
      print('Usando fallback em memória para o banco de dados');
      useInMemoryDatabase = true;
    }
  } else {
    // Inicialização para desktop e mobile
    sqfliteFfiInit();
  }
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? true;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setBool('dark_mode', _isDarkMode),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicBoxV2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(toggleTheme: toggleTheme),
    );
  }
}


