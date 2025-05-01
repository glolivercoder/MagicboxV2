import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  static LogService get instance => _instance;
  factory LogService() => _instance;

  static const String _logEnabledKey = 'log_enabled';
  static const String _logLevelKey = 'log_level';
  static const int _maxLogSize = 5 * 1024 * 1024; // 5MB
  static const String _logDirectory = 'logs';
  
  bool _isLogEnabled = true;
  LogLevel _logLevel = LogLevel.info;
  File? _logFile;

  LogService._internal() {
    _initialize();
  }

  // Lista de logs em memória para ambiente web
  final List<String> _webLogs = [];
  final int _maxWebLogs = 1000; // Máximo de logs armazenados em memória

  Future<void> _initialize() async {
    try {
      // Carregar configurações
      final prefs = await SharedPreferences.getInstance();
      _isLogEnabled = prefs.getBool(_logEnabledKey) ?? true;
      final logLevelIndex = prefs.getInt(_logLevelKey) ?? LogLevel.info.index;
      _logLevel = LogLevel.values[logLevelIndex];
      
      // Se estivermos no ambiente web, não precisamos inicializar o arquivo de log
      if (kIsWeb) {
        return;
      }

      // Inicializar arquivo de log
      if (_isLogEnabled) {
        final appDir = await getApplicationDocumentsDirectory();
        final logDir = Directory('${appDir.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        final now = DateTime.now();
        final fileName = 'magicbox_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
        _logFile = File('${logDir.path}/$fileName');

        // Verificar tamanho do arquivo e rotacionar se necessário
        if (await _logFile!.exists()) {
          final stats = await _logFile!.stat();
          if (stats.size > _maxLogSize) {
            await _rotateLogFile();
          }
        }
      }
    } catch (e) {
      print('Erro ao inicializar LogService: $e');
    }
  }

  Future<void> _rotateLogFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/logs');
      final now = DateTime.now();
      final timestamp = '${now.hour}${now.minute}${now.second}';
      final oldFileName = _logFile!.path;
      final newFileName = '${oldFileName.substring(0, oldFileName.length - 4)}_$timestamp.log';
      
      await _logFile!.rename(newFileName);
      _logFile = File(oldFileName);
    } catch (e) {
      print('Erro ao rotacionar arquivo de log: $e');
    }
  }

  Future<void> setLogEnabled(bool enabled) async {
    _isLogEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_logEnabledKey, enabled);
    
    if (enabled && _logFile == null) {
      await _initialize();
    }
  }

  Future<void> setLogLevel(LogLevel level) async {
    _logLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_logLevelKey, level.index);
  }

  bool get isLogEnabled => _isLogEnabled;
  LogLevel get logLevel => _logLevel;

  Future<void> debug(String message, {String? category, dynamic error, StackTrace? stackTrace}) async {
    if (_isLogEnabled && _logLevel.index <= LogLevel.debug.index) {
      await _writeLog('DEBUG', message, category, error, stackTrace);
    }
  }

  Future<void> info(String message, {String? category, dynamic error, StackTrace? stackTrace}) async {
    if (_isLogEnabled && _logLevel.index <= LogLevel.info.index) {
      await _writeLog('INFO', message, category, error, stackTrace);
    }
  }

  Future<void> warning(String message, {String? category, dynamic error, StackTrace? stackTrace}) async {
    if (_isLogEnabled && _logLevel.index <= LogLevel.warning.index) {
      await _writeLog('WARNING', message, category, error, stackTrace);
    }
  }

  Future<void> error(String message, {String? category, dynamic error, StackTrace? stackTrace}) async {
    if (_isLogEnabled && _logLevel.index <= LogLevel.error.index) {
      await _writeLog('ERROR', message, category, error, stackTrace);
    }
  }

  Future<void> _writeLog(String level, String message, String? category, dynamic error, StackTrace? stackTrace) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logCategory = category != null ? '[$category] ' : '';
      final logMessage = '$timestamp [$level] $logCategory$message';
      
      // Adicionar erro e stack trace se fornecidos
      String fullLogMessage = logMessage;
      if (error != null) {
        fullLogMessage += '\nError: $error';
      }
      if (stackTrace != null) {
        fullLogMessage += '\nStackTrace: $stackTrace';
      }
      
      if (kIsWeb) {
        // No ambiente web, armazenamos os logs em memória
        _webLogs.add(fullLogMessage);
        
        // Limitar o número de logs em memória
        if (_webLogs.length > _maxWebLogs) {
          _webLogs.removeAt(0); // Remove o log mais antigo
        }
        return;
      }

      // Em ambientes não-web, escrevemos no arquivo
      if (_logFile != null) {
        await _logFile!.writeAsString('$fullLogMessage\n', mode: FileMode.append);
        
        // Verificar tamanho do arquivo e rotacionar se necessário
        final stats = await _logFile!.stat();
        if (stats.size > _maxLogSize) {
          await _rotateLogFile();
        }
      }
    } catch (e) {
      print('Erro ao escrever no arquivo de log: $e');
    }
  }

  Future<List<String>> getLogFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/logs');
      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().toList();
      return files
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity.path)
          .toList();
    } catch (e) {
      print('Erro ao listar arquivos de log: $e');
      return [];
    }
  }

  Future<String> readLogFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Em ambiente web, retornamos os logs armazenados em memória
        return _webLogs.join('\n');
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'Arquivo de log não encontrado.';
    } catch (e) {
      return 'Erro ao ler arquivo de log: $e';
    }
  }

  Future<void> clearLogs() async {
    try {
      if (kIsWeb) {
        // Em ambiente web, limpamos os logs armazenados em memória
        _webLogs.clear();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final logDirectory = Directory('${directory.path}/$_logDirectory');
        if (await logDirectory.exists()) {
          await logDirectory.delete(recursive: true);
          await logDirectory.create();
          
          // Reinicializar o arquivo de log atual
          await _initialize();
        }
      }
    } catch (e) {
      print('Erro ao limpar logs: $e');
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
