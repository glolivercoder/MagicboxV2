# Sistema de TTS (Text-to-Speech) do MagicBox V2

## Visão Geral

O MagicBox V2 possui um sistema avançado de Text-to-Speech (TTS) que permite a narração de conteúdos por voz, tornando o aplicativo mais acessível e prático para os usuários. O sistema TTS é utilizado principalmente para:

1. Narrar o conteúdo das caixas (itens armazenados)
2. Descrever objetos analisados pelo Google Gemini AI
3. Responder a comandos de voz específicos

## Bibliotecas Utilizadas

O sistema TTS do MagicBox V2 utiliza as seguintes bibliotecas:

```yaml
dependencies:
  # TTS (Text-to-Speech)
  flutter_tts: ^3.8.5
  
  # Reconhecimento de voz
  speech_to_text: ^6.4.1
  
  # Permissões
  permission_handler: ^12.0.0+1
```

## Funcionalidades Principais

### 1. Narração de Itens na Caixa

O sistema pode narrar todos os itens contidos em uma caixa específica, facilitando a identificação do conteúdo sem necessidade de abrir a caixa fisicamente.

```dart
// Exemplo de código para narrar itens de uma caixa
Future<void> speakBoxContents(Box box, List<Item> items) async {
  final String intro = "A caixa ${box.name} contém ${items.length} itens.";
  await _ttsService.speak(intro);
  
  for (var item in items) {
    final String itemDescription = "Item: ${item.name}. ${item.description ?? ''}";
    await _ttsService.speak(itemDescription);
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
```

### 2. Descrição de Objetos Analisados pelo Gemini

Quando um objeto é analisado pela câmera usando o Google Gemini AI, o sistema pode narrar a descrição detalhada do objeto identificado.

```dart
// Exemplo de código para narrar a descrição de um objeto
Future<void> speakObjectDescription(String description) async {
  final String intro = "Objeto identificado.";
  await _ttsService.speak(intro);
  await Future.delayed(const Duration(milliseconds: 500));
  await _ttsService.speak(description);
}
```

### 3. Comandos de Voz

O MagicBox V2 suporta comandos de voz específicos que ativam diferentes funcionalidades:

#### Comandos Implementados:

| Comando | Função |
|---------|--------|
| "Zoio, pega visão" | Ativa a câmera para reconhecimento de objetos pelo Gemini AI |
| "Zoio, que treco é esse" | Narra a descrição do objeto analisado pelo Gemini AI |
| "Zoio, o que tem aqui" | Narra os itens da caixa atualmente selecionada |
| "Zoio, ajuda" | Lista os comandos de voz disponíveis |

## Implementação do Serviço TTS

O serviço TTS é implementado como um singleton para garantir que apenas uma instância seja utilizada em todo o aplicativo:

```dart
class TTSService {
  static final TTSService instance = TTSService._internal();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  TTSService._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage('pt-BR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    
    _isInitialized = true;
  }
  
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    if (_isSpeaking) {
      await stop();
    }
    
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }
  
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    await _flutterTts.stop();
    _isSpeaking = false;
  }
  
  bool get isSpeaking => _isSpeaking;
}
```

## Implementação do Reconhecimento de Voz

O reconhecimento de voz é implementado para capturar os comandos do usuário:

```dart
class SpeechRecognitionService {
  static final SpeechRecognitionService instance = SpeechRecognitionService._internal();
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  SpeechRecognitionService._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done') {
          _isListening = false;
        }
      },
    );
  }
  
  Future<void> startListening({
    required Function(String) onResult,
    Function()? onTimeout,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;
    
    _isListening = await _speechToText.listen(
      localeId: 'pt_BR',
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords.toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: false,
    );
    
    Future.delayed(const Duration(seconds: 10), () {
      if (_isListening) {
        stopListening();
        if (onTimeout != null) onTimeout();
      }
    });
  }
  
  Future<void> stopListening() async {
    if (!_isInitialized) return;
    
    await _speechToText.stop();
    _isListening = false;
  }
  
  bool get isListening => _isListening;
}
```

## Configuração do TTS na Tela de Configurações

O MagicBox V2 permite personalizar as configurações do TTS através da tela de configurações:

- Ativar/desativar TTS
- Ajustar velocidade da fala
- Ajustar volume
- Ajustar tom de voz
- Selecionar idioma (Português do Brasil por padrão)

## Integração com o Reconhecimento de Objetos

A integração entre o TTS e o reconhecimento de objetos pelo Gemini AI permite uma experiência completa de identificação e descrição por voz:

1. O usuário ativa a câmera com o comando "Zoio, pega visão"
2. O aplicativo captura a imagem e envia para análise pelo Gemini AI
3. Após receber a descrição, o usuário pode solicitar a narração com "Zoio, que treco é esse"
4. O sistema TTS narra a descrição detalhada do objeto

## Instalação e Configuração

Para habilitar o sistema TTS e reconhecimento de voz no MagicBox V2, siga estes passos:

1. Adicione as dependências no arquivo `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_tts: ^3.8.5
     speech_to_text: ^6.4.1
     permission_handler: ^12.0.0+1
   ```

2. Execute o comando para instalar as dependências:
   ```bash
   flutter pub get
   ```

3. Configure as permissões necessárias:

   **Android (android/app/src/main/AndroidManifest.xml):**
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <queries>
     <intent>
       <action android:name="android.intent.action.TTS_SERVICE" />
     </intent>
   </queries>
   ```

   **iOS (ios/Runner/Info.plist):**
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Este aplicativo precisa de acesso ao microfone para comandos de voz</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Este aplicativo precisa de acesso ao reconhecimento de fala para comandos de voz</string>
   ```

4. Inicialize os serviços no método `main()` ou durante a inicialização do aplicativo:
   ```dart
   await TTSService.instance.initialize();
   await SpeechRecognitionService.instance.initialize();
   ```

## Dicas de Uso

1. Para melhor reconhecimento de voz, fale claramente e em um ambiente com pouco ruído de fundo.
2. Os comandos de voz funcionam melhor quando precedidos pela palavra-chave "Zoio".
3. Ajuste as configurações de TTS nas preferências do aplicativo para uma experiência personalizada.
4. O reconhecimento de voz requer conexão com a internet para processamento mais preciso.
