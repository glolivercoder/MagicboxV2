import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magicboxv2/services/log_service.dart';
import 'package:magicboxv2/models/box.dart';
import 'package:magicboxv2/models/item.dart';

class TTSService {
  // Singleton pattern
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  static TTSService get instance => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  final LogService _logService = LogService.instance;
  
  bool _isInitialized = false;
  bool _ttsEnabled = true;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
      
      if (_ttsEnabled) {
        final language = prefs.getString('ttsLanguage') ?? 'pt-BR';
        final rate = prefs.getDouble('ttsRate') ?? 0.5;
        final pitch = prefs.getDouble('ttsPitch') ?? 1.0;
        final voice = prefs.getString('ttsVoice') ?? '';
        
        await _flutterTts.setLanguage(language);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        
        if (voice.isNotEmpty) {
          await _flutterTts.setVoice({"name": voice});
        }
        
        // Configurar callbacks para log
        _flutterTts.setStartHandler(() {
          _logService.info('TTS: Iniciou leitura');
        });
        
        _flutterTts.setCompletionHandler(() {
          _logService.info('TTS: Completou leitura');
        });
        
        _flutterTts.setErrorHandler((error) {
          _logService.error('TTS: Erro - $error');
        });
        
        _isInitialized = true;
        _logService.info('TTS: Serviço inicializado com sucesso');
      } else {
        _logService.info('TTS: Serviço desativado nas configurações');
      }
    } catch (e) {
      _logService.error('TTS: Erro ao inicializar serviço - $e');
    }
  }
  
  /// Verifica se o TTS está habilitado nas configurações
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ttsEnabled') ?? true;
  }
  
  /// Atualiza as configurações do TTS
  Future<void> updateSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
      
      if (_ttsEnabled) {
        final language = prefs.getString('ttsLanguage') ?? 'pt-BR';
        final rate = prefs.getDouble('ttsRate') ?? 0.5;
        final pitch = prefs.getDouble('ttsPitch') ?? 1.0;
        final voice = prefs.getString('ttsVoice') ?? '';
        
        await _flutterTts.setLanguage(language);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        
        if (voice.isNotEmpty) {
          await _flutterTts.setVoice({"name": voice});
        }
        
        _logService.info('TTS: Configurações atualizadas');
      }
    } catch (e) {
      _logService.error('TTS: Erro ao atualizar configurações - $e');
    }
  }
  
  /// Para a leitura atual
  Future<void> stop() async {
    if (!_ttsEnabled || !_isInitialized) return;
    
    try {
      await _flutterTts.stop();
      _logService.info('TTS: Leitura interrompida');
    } catch (e) {
      _logService.error('TTS: Erro ao interromper leitura - $e');
    }
  }
  
  /// Lê um texto simples
  Future<void> speak(String text) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _logService.error('TTS: Erro ao ler texto - $e');
    }
  }
  
  /// Lê os detalhes de uma caixa
  Future<void> speakBoxDetails(Box box, {bool includeItems = false}) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'Caixa ${box.formattedId}, ${box.name}. ';
      
      if (box.category != null && box.category!.isNotEmpty) {
        textToSpeak += 'Categoria: ${box.category}. ';
      }
      
      if (box.description != null && box.description!.isNotEmpty) {
        textToSpeak += 'Descrição: ${box.description}. ';
      }
      
      if (includeItems && box.items != null && box.items!.isNotEmpty) {
        textToSpeak += 'Contém ${box.items!.length} itens. ';
        
        for (var i = 0; i < box.items!.length; i++) {
          final item = box.items![i];
          textToSpeak += 'Item ${i + 1}: ${item.name}. ';
        }
      }
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler detalhes da caixa - $e');
    }
  }
  
  /// Lê os detalhes de um item
  Future<void> speakItemDetails(Item item) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'Item: ${item.name}. ';
      
      if (item.category != null && item.category!.isNotEmpty) {
        textToSpeak += 'Categoria: ${item.category}. ';
      }
      
      if (item.description != null && item.description!.isNotEmpty) {
        textToSpeak += 'Descrição: ${item.description}. ';
      }
      
      if (item.quantity != null && item.quantity! > 0) {
        textToSpeak += 'Quantidade: ${item.quantity}. ';
      }
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler detalhes do item - $e');
    }
  }
  
  /// Lê uma lista de caixas (resumo)
  Future<void> speakBoxesList(List<Box> boxes) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'Lista de ${boxes.length} caixas. ';
      
      for (var i = 0; i < boxes.length; i++) {
        final box = boxes[i];
        textToSpeak += 'Caixa ${i + 1}: ${box.formattedId}, ${box.name}. ';
      }
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler lista de caixas - $e');
    }
  }
  
  /// Lê uma lista de itens (resumo)
  Future<void> speakItemsList(List<Item> items) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'Lista de ${items.length} itens. ';
      
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        textToSpeak += 'Item ${i + 1}: ${item.name}. ';
      }
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler lista de itens - $e');
    }
  }
  
  /// Lê o resultado de reconhecimento de objeto
  Future<void> speakObjectRecognitionResult(Map<String, dynamic> result) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'Objeto reconhecido. ';
      
      if (result.containsKey('name') && result['name'] != null) {
        textToSpeak += 'Nome: ${result['name']}. ';
      }
      
      if (result.containsKey('category') && result['category'] != null) {
        textToSpeak += 'Categoria: ${result['category']}. ';
      }
      
      if (result.containsKey('description') && result['description'] != null) {
        textToSpeak += 'Descrição: ${result['description']}. ';
      }
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler resultado de reconhecimento - $e');
    }
  }
  
  /// Lê o resultado de reconhecimento de ID de caixa
  Future<void> speakBoxIdRecognitionResult(String boxId) async {
    if (!_ttsEnabled) return;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      String textToSpeak = 'ID de caixa reconhecido: $boxId. ';
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      _logService.error('TTS: Erro ao ler ID de caixa reconhecido - $e');
    }
  }
}
