# MagicBoxV2

Aplicativo Flutter multiplataforma para gestão de caixas, itens e impressão de etiquetas. Esta versão foi completamente reestruturada para oferecer uma experiência mais fluida, código mais limpo e funcionalidades aprimoradas.

## Funcionalidades Principais

### 1. Gestão de Caixas e Itens
- Cadastro de caixas com ID, nome, categoria e descrição
- Adição de múltiplos itens por caixa com detalhes completos
- Busca avançada por texto, categoria ou ID
- Visualização em lista com opções de ordenação

### 2. Reconhecimento de Objetos
- Captura de imagem via câmera ou galeria
- Reconhecimento automático usando IA Gemini
- Sugestão inteligente de categorias e descrições
- Salvamento automático das imagens capturadas

### 3. Sistema de Etiquetas Aprimorado
- Interface unificada para seleção de modelos Pimaco
- Preview em tempo real das etiquetas na mesma tela
- Adição de modelos personalizados com armazenamento
- Exportação em múltiplos formatos (PDF Vetorial)

### 4. Reconhecimento de IDs de Caixas
- Captura de imagem via câmera ou galeria
- Reconhecimento automático de IDs manuscritos
- Busca automática da caixa pelo ID reconhecido

## Tecnologias Utilizadas

- Flutter para desenvolvimento multiplataforma
- SQLite para armazenamento local de dados
- Google Generative AI (Gemini) para reconhecimento de objetos e texto
- PDF e impressão para geração de etiquetas

## Instalação

1. Clone o repositório
2. Execute `flutter pub get` para instalar as dependências
3. Configure sua chave da API Gemini nas configurações do aplicativo
4. Execute `flutter run` para iniciar o aplicativo

## Estrutura do Projeto

- `lib/models`: Modelos de dados (Box, Item, User, Etiqueta)
- `lib/screens`: Telas do aplicativo
- `lib/services`: Serviços (Database, Gemini, Log)
- `lib/utils`: Utilitários (Tema, Constantes)
- `lib/widgets`: Widgets reutilizáveis

## Requisitos

- Flutter 3.7.0 ou superior
- Chave da API Gemini para funcionalidades de IA
- Dispositivo ou emulador com câmera para reconhecimento
