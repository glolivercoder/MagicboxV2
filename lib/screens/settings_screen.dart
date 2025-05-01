import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:magicboxv2/services/log_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LogService _logService = LogService.instance;
  final TextEditingController _apiKeyController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isDarkMode = true;
  bool _ttsEnabled = true;
  double _ttsRate = 0.5;
  double _ttsPitch = 1.0;
  String _ttsLanguage = 'pt-BR';
  bool _isLoading = true;
  List<String> _availableLanguages = [];
  List<String> _availableVoices = [];
  String _selectedVoice = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTts();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      // Inicializa TTS e carrega idiomas disponíveis
      final languages = await _flutterTts.getLanguages;
      final voices = await _flutterTts.getVoices;
      
      setState(() {
        if (languages is List) {
          _availableLanguages = List<String>.from(languages);
        }
        
        if (voices is List) {
          _availableVoices = List<String>.from(voices.map((voice) => voice['name']));
          if (_availableVoices.isNotEmpty && _selectedVoice.isEmpty) {
            _selectedVoice = _availableVoices.first;
          }
        }
      });
      
      // Configura TTS com as preferências salvas
      await _flutterTts.setLanguage(_ttsLanguage);
      await _flutterTts.setSpeechRate(_ttsRate);
      await _flutterTts.setPitch(_ttsPitch);
      
      if (_selectedVoice.isNotEmpty) {
        await _flutterTts.setVoice({"name": _selectedVoice});
      }
    } catch (e) {
      _logService.error('Erro ao inicializar TTS: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? true;
        _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
        _ttsRate = prefs.getDouble('ttsRate') ?? 0.5;
        _ttsPitch = prefs.getDouble('ttsPitch') ?? 1.0;
        _ttsLanguage = prefs.getString('ttsLanguage') ?? 'pt-BR';
        _selectedVoice = prefs.getString('ttsVoice') ?? '';
        
        final apiKey = prefs.getString('geminiApiKey') ?? '';
        _apiKeyController.text = apiKey;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _logService.error('Erro ao carregar configurações: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('ttsEnabled', _ttsEnabled);
      await prefs.setDouble('ttsRate', _ttsRate);
      await prefs.setDouble('ttsPitch', _ttsPitch);
      await prefs.setString('ttsLanguage', _ttsLanguage);
      await prefs.setString('ttsVoice', _selectedVoice);
      await prefs.setString('geminiApiKey', _apiKeyController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logService.error('Erro ao salvar configurações: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testTts() async {
    if (!_ttsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TTS está desativado. Ative-o primeiro.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    try {
      await _flutterTts.setLanguage(_ttsLanguage);
      await _flutterTts.setSpeechRate(_ttsRate);
      await _flutterTts.setPitch(_ttsPitch);
      
      if (_selectedVoice.isNotEmpty) {
        await _flutterTts.setVoice({"name": _selectedVoice});
      }
      
      await _flutterTts.speak('Teste de leitura do MagicBox versão 2. Configurações aplicadas com sucesso.');
    } catch (e) {
      _logService.error('Erro ao testar TTS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao testar TTS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, size: 48),
                          const SizedBox(width: 16),
                          const Text(
                            'Configurações',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seção de API Gemini
                  _buildSectionHeader('API Gemini'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(
                              labelText: 'Chave da API Gemini',
                              border: OutlineInputBorder(),
                              hintText: 'Insira sua chave da API Gemini',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Necessária para reconhecimento de objetos e IDs de caixas',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seção de Tema
                  _buildSectionHeader('Tema'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SwitchListTile(
                        title: const Text('Modo Escuro'),
                        subtitle: const Text('Ativar tema escuro com neon azul'),
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seção de TTS
                  _buildSectionHeader('Text-to-Speech (TTS)'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('Ativar TTS'),
                            subtitle: const Text('Leitura de conteúdos por voz'),
                            value: _ttsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _ttsEnabled = value;
                              });
                            },
                          ),
                          const Divider(),
                          
                          // Idioma TTS
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Idioma',
                              border: OutlineInputBorder(),
                            ),
                            value: _availableLanguages.contains(_ttsLanguage) 
                                ? _ttsLanguage 
                                : (_availableLanguages.isNotEmpty ? _availableLanguages.first : 'pt-BR'),
                            items: _availableLanguages.map((language) {
                              return DropdownMenuItem<String>(
                                value: language,
                                child: Text(language),
                              );
                            }).toList(),
                            onChanged: _ttsEnabled ? (value) {
                              if (value != null) {
                                setState(() {
                                  _ttsLanguage = value;
                                });
                              }
                            } : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Voz TTS
                          if (_availableVoices.isNotEmpty)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Voz',
                                border: OutlineInputBorder(),
                              ),
                              value: _availableVoices.contains(_selectedVoice) 
                                  ? _selectedVoice 
                                  : (_availableVoices.isNotEmpty ? _availableVoices.first : ''),
                              items: _availableVoices.map((voice) {
                                return DropdownMenuItem<String>(
                                  value: voice,
                                  child: Text(voice),
                                );
                              }).toList(),
                              onChanged: _ttsEnabled ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedVoice = value;
                                  });
                                }
                              } : null,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Velocidade TTS
                          Text('Velocidade: ${(_ttsRate * 2).toStringAsFixed(1)}x'),
                          Slider(
                            value: _ttsRate,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: (_ttsRate * 2).toStringAsFixed(1) + 'x',
                            onChanged: _ttsEnabled ? (value) {
                              setState(() {
                                _ttsRate = value;
                              });
                            } : null,
                          ),
                          
                          // Tom TTS
                          Text('Tom: ${_ttsPitch.toStringAsFixed(1)}'),
                          Slider(
                            value: _ttsPitch,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: _ttsPitch.toStringAsFixed(1),
                            onChanged: _ttsEnabled ? (value) {
                              setState(() {
                                _ttsPitch = value;
                              });
                            } : null,
                          ),
                          
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _ttsEnabled ? _testTts : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Testar TTS'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botão Salvar
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Salvar Configurações'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
