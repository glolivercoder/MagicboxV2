# Sistema de Preview de Etiquetas do MagicBox V2

## Visão Geral

O MagicBox V2 possui um sistema avançado de geração e preview de etiquetas para caixas e itens, facilitando a organização e identificação visual do conteúdo armazenado. O sistema permite a visualização prévia das etiquetas antes da impressão, com suporte a diferentes formatos e estilos.

## Funcionalidades Principais

### 1. Geração de Etiquetas para Caixas

O sistema gera etiquetas para caixas com as seguintes informações:
- ID único da caixa (com código de barras)
- Nome da caixa
- Categoria
- Descrição (opcional)
- QR Code para acesso rápido via aplicativo

### 2. Geração de Etiquetas para Itens

Para itens individuais, o sistema gera etiquetas com:
- Nome do item
- Categoria
- Caixa onde está armazenado
- Miniatura da imagem (se disponível)
- QR Code para identificação rápida

### 3. Preview em Tempo Real

O sistema oferece preview em tempo real das etiquetas, permitindo:
- Visualização exata de como a etiqueta ficará após impressão
- Ajuste de tamanho e layout antes da impressão
- Seleção de diferentes modelos de etiquetas

### 4. Formatos Suportados

O MagicBox V2 suporta diversos formatos de etiquetas:
- A4 (para impressão em folhas de etiquetas)
- Etiquetas térmicas (80mm x 50mm)
- Etiquetas pequenas (38mm x 25mm)
- Etiquetas médias (63mm x 38mm)

## Implementação Técnica

### Bibliotecas Utilizadas

```yaml
dependencies:
  # Geração de PDF
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # Geração de códigos de barras e QR codes
  barcode: ^2.2.4
  qr_flutter: ^4.1.0
  flutter_barcode_scanner: ^2.0.0
  zxing2: ^0.2.1
  
  # Manipulação de imagens
  image: ^4.1.3
```

### Biblioteca Adicional para Geração de Códigos de Barras

Além das bibliotecas principais, o MagicBox V2 também utiliza a biblioteca `zxing2` para oferecer opções adicionais de geração e leitura de códigos de barras:

```dart
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/oned/ean13_writer.dart';

class AdvancedBarcodeGenerator {
  // Gerar código de barras EAN-13 (usado em produtos comerciais)
  static Uint8List generateEAN13(String data, {int width = 200, int height = 80}) {
    final writer = EAN13Writer();
    final bitMatrix = writer.encode(data, BarcodeFormat.EAN_13, width, height);
    
    // Converter BitMatrix para imagem
    final image = Image(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (bitMatrix.get(x, y) == 1) {
          image.setPixel(x, y, 0xFF000000); // Preto
        } else {
          image.setPixel(x, y, 0xFFFFFFFF); // Branco
        }
      }
    }
    
    return Uint8List.fromList(encodePng(image));
  }
  
  // Gerar QR Code com logo no centro
  static Uint8List generateQRCodeWithLogo(String data, Uint8List logoBytes, {int size = 300}) {
    final writer = QRCodeWriter();
    final hints = EncodeHints(errorCorrectionLevel: ErrorCorrectionLevel.H);
    final bitMatrix = writer.encode(data, BarcodeFormat.QR_CODE, size, size, hints);
    
    // Converter BitMatrix para imagem
    final qrImage = Image(size, size);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (bitMatrix.get(x, y) == 1) {
          qrImage.setPixel(x, y, 0xFF000000); // Preto
        } else {
          qrImage.setPixel(x, y, 0xFFFFFFFF); // Branco
        }
      }
    }
    
    // Adicionar logo no centro
    final logo = decodeImage(logoBytes)!;
    final logoSize = size ~/ 5;
    final resizedLogo = copyResize(logo, width: logoSize, height: logoSize);
    
    final x = (size - logoSize) ~/ 2;
    final y = (size - logoSize) ~/ 2;
    
    compositeImage(qrImage, resizedLogo, dstX: x, dstY: y);
    
    return Uint8List.fromList(encodePng(qrImage));
  }
}
```

Esta biblioteca oferece recursos avançados para geração de códigos de barras, incluindo:

- Suporte a múltiplos formatos (EAN-13, UPC-A, Code 128, etc.)
- QR Codes com logotipos incorporados
- Ajuste de nível de correção de erros
- Personalização avançada de cores e tamanhos

### Componentes Principais

#### 1. Gerador de Etiquetas

```dart
class LabelGenerator {
  static Future<Uint8List> generateBoxLabel(Box box, {LabelSize size = LabelSize.medium}) async {
    final pdf = Document();
    
    pdf.addPage(
      Page(
        build: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com ID e código de barras
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ID: ${box.formattedId}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  BarcodeWidget(
                    data: box.id.toString(),
                    barcode: Barcode.code128(),
                    width: 100,
                    height: 30,
                  ),
                ],
              ),
              SizedBox(height: 10),
              
              // Nome da caixa
              Text(box.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              
              // Categoria
              Text('Categoria: ${box.category}', style: TextStyle(fontSize: 14)),
              SizedBox(height: 5),
              
              // Descrição (se disponível)
              if (box.description != null && box.description!.isNotEmpty)
                Text('Descrição: ${box.description}', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              
              // QR Code
              Center(
                child: QrImageView(
                  data: 'magicbox://box/${box.id}',
                  version: QrVersions.auto,
                  size: 120,
                ),
              ),
            ],
          );
        },
        pageFormat: getPageFormatForSize(size),
      ),
    );
    
    return pdf.save();
  }
  
  static PdfPageFormat getPageFormatForSize(LabelSize size) {
    switch (size) {
      case LabelSize.small:
        return PdfPageFormat(38 * PdfPageFormat.mm, 25 * PdfPageFormat.mm);
      case LabelSize.medium:
        return PdfPageFormat(63 * PdfPageFormat.mm, 38 * PdfPageFormat.mm);
      case LabelSize.large:
        return PdfPageFormat(80 * PdfPageFormat.mm, 50 * PdfPageFormat.mm);
      case LabelSize.a4:
        return PdfPageFormat.a4;
    }
  }
}

enum LabelSize { small, medium, large, a4 }
```

#### 2. Preview de Etiquetas

```dart
class LabelPreviewScreen extends StatefulWidget {
  final Box box;
  
  const LabelPreviewScreen({Key? key, required this.box}) : super(key: key);
  
  @override
  _LabelPreviewScreenState createState() => _LabelPreviewScreenState();
}

class _LabelPreviewScreenState extends State<LabelPreviewScreen> {
  LabelSize _selectedSize = LabelSize.medium;
  late Future<Uint8List> _pdfFuture;
  
  @override
  void initState() {
    super.initState();
    _pdfFuture = LabelGenerator.generateBoxLabel(widget.box, size: _selectedSize);
  }
  
  void _updatePreview() {
    setState(() {
      _pdfFuture = LabelGenerator.generateBoxLabel(widget.box, size: _selectedSize);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview de Etiqueta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printLabel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de tamanho
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<LabelSize>(
              value: _selectedSize,
              onChanged: (LabelSize? newSize) {
                if (newSize != null) {
                  setState(() {
                    _selectedSize = newSize;
                    _updatePreview();
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: LabelSize.small, child: Text('Pequena (38x25mm)')),
                DropdownMenuItem(value: LabelSize.medium, child: Text('Média (63x38mm)')),
                DropdownMenuItem(value: LabelSize.large, child: Text('Grande (80x50mm)')),
                DropdownMenuItem(value: LabelSize.a4, child: Text('A4 (210x297mm)')),
              ],
            ),
          ),
          
          // Preview do PDF
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao gerar etiqueta: ${snapshot.error}'));
                }
                
                if (snapshot.hasData) {
                  return PdfPreview(
                    build: (format) => snapshot.data!,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                  );
                }
                
                return const Center(child: Text('Nenhuma etiqueta para visualizar'));
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _printLabel() async {
    final pdfData = await _pdfFuture;
    await Printing.layoutPdf(
      onLayout: (format) => pdfData,
      name: 'Etiqueta - ${widget.box.name}',
    );
  }
}
```

## Recursos Avançados

### 1. Etiquetas em Lote

O sistema permite a geração e preview de múltiplas etiquetas em uma única página, otimizando o uso de papel:

```dart
static Future<Uint8List> generateBatchBoxLabels(List<Box> boxes, {int columns = 2, int rows = 5}) async {
  final pdf = Document();
  
  pdf.addPage(
    Page(
      build: (context) {
        return GridView(
          crossAxisCount: columns,
          childAspectRatio: 1.5,
          children: boxes.map((box) => _buildBoxLabelWidget(box)).toList(),
        );
      },
      pageFormat: PdfPageFormat.a4,
    ),
  );
  
  return pdf.save();
}
```

### 2. Personalização de Templates

O sistema oferece diferentes templates para as etiquetas, permitindo personalização visual:

```dart
enum LabelTemplate { standard, minimal, detailed, colorful }

static Widget _buildBoxLabelWidget(Box box, {LabelTemplate template = LabelTemplate.standard}) {
  switch (template) {
    case LabelTemplate.standard:
      return _buildStandardTemplate(box);
    case LabelTemplate.minimal:
      return _buildMinimalTemplate(box);
    case LabelTemplate.detailed:
      return _buildDetailedTemplate(box);
    case LabelTemplate.colorful:
      return _buildColorfulTemplate(box);
  }
}
```

### 3. Exportação para Diferentes Formatos

Além da impressão direta, o sistema permite exportar as etiquetas em diferentes formatos:

```dart
Future<void> _exportLabel(ExportFormat format) async {
  final pdfData = await _pdfFuture;
  
  switch (format) {
    case ExportFormat.pdf:
      await _savePdf(pdfData);
      break;
    case ExportFormat.png:
      await _savePng(pdfData);
      break;
    case ExportFormat.jpg:
      await _saveJpg(pdfData);
      break;
  }
}

enum ExportFormat { pdf, png, jpg }
```

## Integração com o Sistema de Caixas

O preview de etiquetas é integrado diretamente ao sistema de gerenciamento de caixas, permitindo:

1. Acesso rápido ao preview a partir da tela de detalhes da caixa
2. Geração automática de etiquetas ao criar novas caixas
3. Atualização de etiquetas quando informações da caixa são modificadas

## Instalação e Configuração

Para habilitar o sistema de preview de etiquetas no MagicBox V2, siga estes passos:

1. Adicione as dependências no arquivo `pubspec.yaml`:
   ```yaml
   dependencies:
     pdf: ^3.10.7
     printing: ^5.11.1
     barcode: ^2.2.4
     qr_flutter: ^4.1.0
     image: ^4.1.3
   ```

2. Execute o comando para instalar as dependências:
   ```bash
   flutter pub get
   ```

3. Configure as permissões necessárias:

   **Android (android/app/src/main/AndroidManifest.xml):**
   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   ```

4. Inicialize o sistema de etiquetas no método `main()` ou durante a inicialização do aplicativo:
   ```dart
   // Configurar diretório para salvar etiquetas exportadas
   final appDir = await getApplicationDocumentsDirectory();
   LabelGenerator.initialize(appDir.path);
   ```

## Dicas de Uso

1. Para melhor qualidade de impressão, use impressoras térmicas dedicadas para etiquetas pequenas e médias.
2. Ao imprimir em folhas A4, utilize papel adesivo pré-cortado no tamanho das etiquetas desejadas.
3. Para etiquetas coloridas, certifique-se de usar uma impressora colorida.
4. Exporte as etiquetas em formato PDF para compartilhar com outros usuários ou imprimir em outros dispositivos.
5. Para etiquetas de itens pequenos, prefira o template minimalista para melhor legibilidade.
