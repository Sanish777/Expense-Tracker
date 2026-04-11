import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  void dispose() {
    _textRecognizer.close();
  }

  Future<double?> scanReceiptTotal() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return null;

      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      List<double> numbers = [];
      final regex = RegExp(r'[$€£Rs]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)');
      
      bool foundTotalKeyword = false;
      double? totalValue;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.toLowerCase();
          
          if (text.contains('total') || text.contains('amount sum') || text.contains('final')) {
            foundTotalKeyword = true;
            // Check if amount is on the same line
            final match = regex.firstMatch(text.replaceAll(RegExp(r'(total|amount sum|final|:|-|=|\s)'), ''));
            if (match != null) {
                final valStr = match.group(1)?.replaceAll(',', '');
                final val = double.tryParse(valStr ?? '');
                if (val != null) {
                   totalValue = val;
                }
            }
          }
          
          final matches = regex.allMatches(text);
          for (var match in matches) {
             final valStr = match.group(1)?.replaceAll(',', '');
             final val = double.tryParse(valStr ?? '');
             if (val != null && val > 0) {
                 numbers.add(val);
             }
          }
        }
      }
      
      if (totalValue != null && totalValue > 0) return totalValue;
      
      if (numbers.isNotEmpty) {
        numbers.sort();
        return numbers.last;
      }
      return null;
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }
}
