// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Configura o SQLite para web
void setupSqliteWeb() {
  // Define o caminho para os arquivos do SQLite
  html.window.document.body?.setAttribute('data-sqflite-path', 'sqlite3/');
  
  // Adiciona o script do SQLite ao documento
  final script = html.ScriptElement()
    ..src = 'sqlite3/sqlite3.js'
    ..type = 'text/javascript';
  
  html.document.head?.append(script);
}
