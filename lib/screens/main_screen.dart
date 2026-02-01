import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magicboxv2/screens/boxes_screen.dart';
import 'package:magicboxv2/screens/box_detail_screen.dart';
import 'package:magicboxv2/screens/box_id_recognition_screen.dart';
import 'package:magicboxv2/screens/items_screen.dart';
import 'package:magicboxv2/screens/etiquetas_screen.dart';
import 'package:magicboxv2/screens/users_screen.dart';
import 'package:magicboxv2/screens/settings_screen.dart';
import 'package:magicboxv2/services/database_helper.dart';
import 'package:magicboxv2/services/gemini_service.dart';
import 'package:magicboxv2/services/tts_service.dart';

class MainScreen extends StatefulWidget {
  final Function toggleTheme;

  const MainScreen({super.key, required this.toggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [];
  final List<String> _titles = ['Caixas', 'Itens', 'Início', 'Etiquetas', 'Usuários', 'Config'];

  @override
  void initState() {
    super.initState();
    // Inicializar as telas com GlobalKeys internamente
    final boxesScreen = BoxesScreen(key: GlobalKey<BoxesScreenState>());
    final itemsScreen = ItemsScreen(key: GlobalKey<ItemsScreenState>());
    
    _screens.addAll([
      boxesScreen,
      itemsScreen,
      const BoxIdRecognitionScreen(),
      const EtiquetasScreen(),
      const UsersScreen(),
      const SettingsScreen(),
    ]);
    _initializeTTS();
    _configureForMobile();
  }
  
  Future<void> _initializeTTS() async {
    // Inicializa o serviço de TTS
    await TTSService.instance.initialize();
  }
  
  void _configureForMobile() {
    // Verificar se estamos em um dispositivo móvel
    if (kIsWeb) return; // Pular configurações específicas para mobile se estiver na web
    
    // Configurações específicas para dispositivos Android
    if (Platform.isAndroid) {
      // Otimizações para Samsung M52 e dispositivos similares
      // Configurações de densidade de pixel e escala para telas de alta resolução
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Configurações de sistema UI para aproveitar melhor o espaço da tela
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      
      // Configurações específicas para o banco de dados em dispositivos Android
      _configureDatabaseForMobile();
    }
  }
  
  Future<void> _configureDatabaseForMobile() async {
    // Otimizações de banco de dados para dispositivos móveis
    try {
      // Usar diretório de armazenamento específico para Android
      final dbHelper = DatabaseHelper.instance;
      // Não há necessidade de otimizações específicas para mobile
      // O DatabaseHelper já lida com isso automaticamente
    } catch (e) {
      debugPrint('Erro ao configurar banco de dados para mobile: $e');
    }
  }

  // Método para navegar para a tela de reconhecimento de ID manuscrito
  Future<void> _navigateToHandwrittenIdRecognition() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null && mounted) {
        // Mostrar diálogo de carregamento
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analisando imagem...'),
              ],
            ),
          ),
        );
        
        // Processar a imagem com a Gemini para reconhecer o ID manuscrito
        final geminiService = GeminiService();
        final result = await geminiService.recognizeHandwrittenId(image);
        
        // Fechar o diálogo de carregamento
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        if (result != null && mounted) {
          // Navegar para a tela de detalhes da caixa se o ID for reconhecido
          final databaseHelper = DatabaseHelper.instance;
          final box = await databaseHelper.readBoxById(result);
          
          if (box != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoxDetailScreen(box: box),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Caixa com ID $result não encontrada')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível reconhecer o ID na imagem')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar a imagem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2),
            ),
            const SizedBox(width: 8),
            const Text('MagicBox'),
          ],
        ),
        actions: [
          // Scanner QR - Atalho para a tela "Ler ID"
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler QR Code',
            onPressed: () {
              setState(() {
                _currentIndex = 2; // Índice da tela BoxIdRecognitionScreen
              });
            },
          ),
          // Reconhecimento de ID manuscrito por Gemini
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Reconhecer ID manuscrito',
            onPressed: () {
              _navigateToHandwrittenIdRecognition();
            },
          ),
          // Impressão - Atalho para a tela "Etiquetas"
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Etiquetas',
            onPressed: () {
              setState(() {
                _currentIndex = 3; // Índice da tela EtiquetasScreen
              });
            },
          ),
          // Configurações - Atalho para a tela "Config"
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              setState(() {
                _currentIndex = 5; // Índice da tela SettingsScreen
              });
            },
          ),
          // Alternar tema
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            tooltip: 'Alternar tema',
            onPressed: () {
              widget.toggleTheme();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Caixas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Itens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Ler ID',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print),
            label: 'Etiquetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // Implementar adição de caixa ou item
                if (_currentIndex == 0) {
                  // Adicionar caixa - chamar o método da tela de caixas
                  final boxesScreen = _screens[0] as BoxesScreen;
                  final state = boxesScreen.key as GlobalKey<BoxesScreenState>;
                  state.currentState?.showAddBoxDialog();
                } else if (_currentIndex == 1) {
                  // Adicionar item - chamar o método da tela de itens
                  final itemsScreen = _screens[1] as ItemsScreen;
                  final state = itemsScreen.key as GlobalKey<ItemsScreenState>;
                  state.currentState?.showAddItemDialog();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
