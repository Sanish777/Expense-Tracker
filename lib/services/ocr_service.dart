import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_category.dart';

class ReceiptLineItem {
  final String name;
  final double amount;
  final String categoryId;

  const ReceiptLineItem({
    required this.name,
    required this.amount,
    required this.categoryId,
  });
}

class ReceiptScanResult {
  final DateTime? billDate;
  final double? total;
  final List<ReceiptLineItem> items;

  const ReceiptScanResult({
    required this.billDate,
    required this.total,
    required this.items,
  });
}

class OCRService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  void dispose() {
    _textRecognizer.close();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<ReceiptScanResult?> scanReceiptItems(
      List<AppCategory> categories) async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (image == null) return null;
      return scanReceiptItemsFromFile(image.path, categories);
    } catch (e) {
      print('Receipt OCR Error: $e');
      return null;
    }
  }

  Future<ReceiptScanResult?> scanReceiptItemsFromFile(
      String imagePath, List<AppCategory> categories) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Collect all lines with bounding boxes
      final rawLines = <_OcrWord>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) {
            rawLines.add(_OcrWord(text, line.boundingBox));
          }
        }
      }

      // Group elements by Y coordinate to form rows
      rawLines.sort((a, b) {
        // Primary sort by Y
        final yDiff = a.rect.top.compareTo(b.rect.top);
        if (yDiff != 0 && (a.rect.top - b.rect.top).abs() > 15) return yDiff;
        // Secondary sort by X
        return a.rect.left.compareTo(b.rect.left);
      });
      
      final allLines = <String>[];
      if (rawLines.isNotEmpty) {
        var currentRow = [rawLines.first];
        for (int i = 1; i < rawLines.length; i++) {
          final current = rawLines[i];
          // Use median Y of current row for comparing to handle tilt slightly
          final rowTop = currentRow.map((e) => e.rect.top).reduce((a, b) => a + b) / currentRow.length;
          
          final tolerance = 12.0; // Lines within 12px vertically = same row
          if ((current.rect.top - rowTop).abs() < tolerance) {
            currentRow.add(current);
          } else {
            // Sort elements in row from left to right
            currentRow.sort((a, b) => a.rect.left.compareTo(b.rect.left));
            allLines.add(currentRow.map((e) => e.text).join(' '));
            currentRow = [current];
          }
        }
        // Don't forget last row
        currentRow.sort((a, b) => a.rect.left.compareTo(b.rect.left));
        allLines.add(currentRow.map((e) => e.text).join(' '));
      }

      if (allLines.isEmpty) {
        return const ReceiptScanResult(billDate: null, total: null, items: []);
      }

      // Debug: Print all OCR lines
      print('═══ OCR LINES (${allLines.length}) ═══');
      for (int i = 0; i < allLines.length; i++) {
        print('  [$i] ${allLines[i]}');
      }
      print('═══════════════════════════');

      final billDate = _extractBillDate(allLines);

      // Strategy 1: Find structured section (column header row)
      final headerIdx = _findColumnHeaderIndex(allLines);

      List<ReceiptLineItem> items;
      double? total;

      if (headerIdx >= 0) {
        // Found a column header — parse structured bill
        print('[OCR] Found column header at line $headerIdx');
        final endIdx = _findTotalsSectionIndex(allLines, headerIdx + 1);
        print('[OCR] Items section: lines ${headerIdx + 1} to $endIdx');
        items = _parseStructuredItems(
            allLines.sublist(headerIdx + 1, endIdx), categories);
        total = _extractTotal(allLines.sublist(endIdx));
      } else {
        // No column header — use permissive line-by-line parser
        print('[OCR] No column header found, using line-by-line parser');
        items = _parseLineByLine(allLines, categories);
        total = _extractTotal(allLines);
      }

      total ??=
          items.isNotEmpty ? items.fold<double>(0, (s, i) => s + i.amount) : null;

      print('[OCR] Result: ${items.length} items, total=$total');
      for (final item in items) {
        print('  → ${item.name}: ${item.amount}');
      }

      return ReceiptScanResult(
        billDate: billDate,
        total: total,
        items: items,
      );
    } catch (e) {
      print('Receipt OCR Error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STRUCTURED PARSER (bills with Sn|Particulars|Qty|Rate|Amount header)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Finds the index of the column-header row, or -1 if not found.
  int _findColumnHeaderIndex(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (_isColumnHeader(lines[i])) return i;
    }
    return -1;
  }

  bool _isColumnHeader(String line) {
    final lower = line.toLowerCase();
    int score = 0;
    if (lower.contains('particular') || lower.contains('description')) score++;
    if (lower.contains('qty') || lower.contains('quantity') ||
        RegExp(r'\bqt\b').hasMatch(lower)) score++;
    if (lower.contains('rate') || lower.contains('price')) score++;
    if (lower.contains('amount') || lower.contains('amt')) score++;
    if (RegExp(r'\bsn\b|\bsr\b|\bsl\b|s\.no|s\.n').hasMatch(lower)) score++;
    if (lower.contains('hsc')) score++;

    // Need at least 3 matches, or 2 matches + pipe separator
    return score >= 3 || (score >= 2 && lower.contains('|'));
  }

  /// Finds where the totals section starts (after items).
  int _findTotalsSectionIndex(List<String> lines, int startFrom) {
    for (int i = startFrom; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (lower.contains('gross amount') ||
          lower.contains('sub total') ||
          lower.contains('subtotal') ||
          lower.contains('grand total') ||
          (lower.contains('net') && lower.contains('amount'))) {
        return i;
      }
    }
    return lines.length;
  }

  /// A true SN-start line begins with 1-3 digits then has LETTERS (item name).
  /// "1  Spaghetti Carbonara 1 433.63 433.63" → TRUE  (has letters after SN)
  /// "1 433.63 433.63"                         → FALSE (only numbers after SN)
  static final RegExp _snWithTextPattern =
      RegExp(r'^(\d{1,3})[.)\]\|]?\s*([A-Za-z].*)');

  bool _isSnStartLine(String line) {
    return _snWithTextPattern.hasMatch(line.trim());
  }

  /// Parses items from the structured section between header and totals.
  /// Groups multi-line item names. A new item starts only when a serial number
  /// is followed by LETTERS (not by more numbers = qty/rate line).
  List<ReceiptLineItem> _parseStructuredItems(
      List<String> lines, List<AppCategory> categories) {
    final items = <ReceiptLineItem>[];
    String currentName = '';
    double currentAmount = 0;

    void _flush() {
      if (currentName.isNotEmpty && currentAmount > 0) {
        items.add(_makeItem(currentName, currentAmount, categories));
      }
      currentName = '';
      currentAmount = 0;
    }

    for (final rawLine in lines) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();

      // Skip dividers and HSC lines
      if (_isDivider(line)) continue;
      if (lower.startsWith('hsc')) continue;

      // ── New item: "1 Spaghetti Carbonara ..." ─────────────────────────────
      if (_isSnStartLine(line)) {
        _flush(); // save previous item

        final match = _snWithTextPattern.firstMatch(line)!;
        final rest = match.group(2)!.trim();

        // The rightmost number on this line is the line-total amount
        currentAmount = _extractRightmostAmount(rest) ?? 0;
        currentName = _extractNameBeforeNumbers(rest);

      // ── Pure-number line: "1 433.63 433.63" = qty / rate / amount ─────────
      } else if (_isPureNumbers(line) ||
          RegExp(r'^\d+[\s.,]+[\d.,\s]+$').hasMatch(line)) {
        // This is the qty/rate/amount row for the current item.
        // Update the amount with the rightmost value on this line.
        final amt = _extractRightmostAmount(line);
        if (amt != null && amt > 0 && _isReasonableItemAmount(amt)) {
          currentAmount = amt;
        }

      // ── Continuation text line: second word of a multi-line name ──────────
      } else if (!_isMetadataLine(lower)) {
        final textPart = _extractNameBeforeNumbers(line);
        if (textPart.isNotEmpty) {
          currentName = currentName.isEmpty
              ? textPart
              : '$currentName $textPart';
          // If this line also has an amount, capture it
          final amt = _extractRightmostAmount(line);
          if (amt != null && amt > 0 && _isReasonableItemAmount(amt)) {
            currentAmount = amt;
          }
        }
      }
    }

    _flush(); // save last item
    return items;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LINE-BY-LINE PARSER (fallback for simple/unstructured bills)
  // ═══════════════════════════════════════════════════════════════════════════

  List<ReceiptLineItem> _parseLineByLine(
      List<String> lines, List<AppCategory> categories) {
    final items = <ReceiptLineItem>[];
    String? pendingName;

    for (final rawLine in lines) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();

      // Skip metadata lines
      if (_isMetadataLine(lower)) continue;
      if (_isDivider(line)) continue;
      if (_isPureNumbers(line)) continue;

      // Try to extract amount from this line
      final amount = _extractRightmostAmount(line);
      final name = _extractNameBeforeNumbers(line);

      if (amount != null && amount > 0 && _isReasonableItemAmount(amount)) {
        final itemName = name.isNotEmpty ? name : pendingName;
        if (itemName != null && itemName.length >= 2 &&
            !_isMetadataLine(itemName.toLowerCase())) {
          items.add(_makeItem(itemName, amount, categories));
          pendingName = null;
        }
      } else if (name.length >= 2 && !_isMetadataLine(name.toLowerCase())) {
        // Text-only line — might be a pending item name
        pendingName = name;
      }
    }

    return items;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AMOUNT EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════════

  static final RegExp _amountRegex = RegExp(
    r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+\.\d{1,2}|\d{2,})',
  );

  /// Returns the rightmost valid amount from a line.
  /// For "Spaghetti 1 433.63 433.63" → returns 433.63
  double? _extractRightmostAmount(String line) {
    final sanitized = _sanitizeCurrency(line);
    final matches = _amountRegex.allMatches(sanitized).toList();
    if (matches.isEmpty) return null;

    // Walk from right to left, return first reasonable amount
    for (final match in matches.reversed) {
      final raw = match.group(1)?.replaceAll(',', '');
      final amount = double.tryParse(raw ?? '');
      if (amount == null) continue;
      if (amount < 1) continue; // skip tiny values
      if (amount > 500000) continue; // skip huge values
      // Skip values that look like serial numbers (1-digit at position 0)
      if (raw != null && raw.length <= 2 && !raw.contains('.')) {
        // Could be qty like "1" or "2" — only skip if there's a bigger number
        if (matches.length > 1) continue;
      }
      return amount;
    }
    return null;
  }

  bool _isReasonableItemAmount(double amount) =>
      amount >= 1 && amount <= 500000;

  // ═══════════════════════════════════════════════════════════════════════════
  // NAME EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extracts the text portion before trailing numbers.
  /// "Spaghetti 1 433.63 433.63" → "Spaghetti"
  /// "Chicken Sizzler 1 539.82 539.82" → "Chicken Sizzler"
  /// "Chocolate" → "Chocolate"
  String _extractNameBeforeNumbers(String line) {
    final sanitized = _sanitizeCurrency(line).trim();

    // Find where the trailing numbers start
    // Pattern: text followed by (optional qty) (rate) (amount)
    // We look for the first number that starts a "trailing numbers" sequence
    final matches = _amountRegex.allMatches(sanitized).toList();

    if (matches.isEmpty) {
      // No numbers — entire line is the name
      return _cleanName(sanitized);
    }

    // Find the earliest "numeric tail": a sequence of numbers at the end
    // Walk backwards to find where text ends and numbers begin
    int cutPoint = sanitized.length;
    for (final match in matches) {
      // Check if everything after this match start is just numbers and spaces
      final afterText = sanitized.substring(match.start);
      if (RegExp(r'^[\d\s.,]+$').hasMatch(afterText)) {
        cutPoint = match.start;
        break;
      }
    }

    final name = sanitized.substring(0, cutPoint).trim();
    return _cleanName(name);
  }

  String _cleanName(String raw) {
    var name = raw.trim();
    // Remove leading serial number like "1 " or "12 "
    name = name.replaceAll(RegExp(r'^\d{1,3}\s+'), '');
    // Remove trailing colons, dashes, pipes
    name = name.replaceAll(RegExp(r'[-:|]+$'), '');
    // Remove leading/trailing special chars
    name = name.replaceAll(RegExp(r'^[|/\-:]+|[|/\-:]+$'), '');
    // Collapse whitespace
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Title case
    if (name.isNotEmpty) {
      name = name
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w.length == 1
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
    }
    return name;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LINE CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Known metadata phrases — if a line contains any of these, skip it.
  static const List<String> _metadataPhrases = [
    'grand total', 'sub total', 'subtotal', 'net total', 'net amount',
    'gross amount', 'amount due', 'tax invoice', 'bill no', 'invoice no',
    'order no', 'token no', 'ref no', 'txn no', 'pan no', 'vat no',
    'reg no', 'room no', 'payment mode', 'powered by', 'thank you',
    'visit again', 'service charge', 'ims software',
  ];

  /// Metadata label words — if a line is ONLY these words, skip it.
  static const Set<String> _metadataLabels = {
    'total', 'subtotal', 'gross', 'taxable', 'nontaxable', 'discount',
    'vat', 'gst', 'tender', 'change', 'paid', 'cash', 'balance',
    'invoice', 'receipt', 'miti', 'date', 'time', 'printed',
    'address', 'phone', 'email', 'website', 'contact', 'fax',
    'waiter', 'cashier', 'server', 'counter', 'terminal',
    'customer', 'guest', 'pax', 'remarks', 'name', 'table',
  };

  bool _isMetadataLine(String lowerLine) {
    final trimmed = lowerLine.trim();
    if (trimmed.length < 2) return true;

    // Check phrase matches
    for (final phrase in _metadataPhrases) {
      if (trimmed.contains(phrase)) return true;
    }

    // "Label : value" pattern → metadata
    final colonMatch = RegExp(r'^([a-z]+)\s*:').firstMatch(trimmed);
    if (colonMatch != null) {
      final label = colonMatch.group(1)!;
      if (_metadataLabels.contains(label)) return true;
    }

    // If line is a single metadata label word alone
    final words = trimmed
        .split(RegExp(r'[\s|,:;/]+'))
        .where((w) => w.length >= 2 && RegExp(r'^[a-z]+$').hasMatch(w))
        .toList();
    if (words.isNotEmpty && words.every(_metadataLabels.contains)) return true;

    // "Rs. One thousand..." → amount in words
    if (trimmed.startsWith('rs.') && trimmed.contains(' ')) return true;

    return false;
  }

  bool _isDivider(String line) {
    final t = line.replaceAll(RegExp(r'\s'), '');
    return t.length >= 3 && RegExp(r'^[-=*_.]+$').hasMatch(t);
  }

  bool _isPureNumbers(String line) {
    return RegExp(r'^[\d\s.,:%]+$').hasMatch(line.trim());
  }

  String _sanitizeCurrency(String line) => line
      .replaceAll(RegExp(r'\b(rs\.?|usd|npr)\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'[$€£]'), ' ');

  // ═══════════════════════════════════════════════════════════════════════════
  // TOTAL EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════════

  double? _extractTotal(List<String> lines) {
    double? netAmount;
    double? grossAmount;
    double? tender;

    for (final line in lines) {
      final lower = line.toLowerCase();
      final amount = _extractRightmostAmount(line);
      if (amount == null || amount <= 0) continue;

      if (lower.contains('net') && lower.contains('amount')) {
        netAmount ??= amount;
      } else if (lower.contains('grand total')) {
        netAmount ??= amount;
      } else if (lower.contains('tender')) {
        tender ??= amount;
      } else if (lower.contains('gross')) {
        grossAmount ??= amount;
      } else if (lower.contains('total') && !lower.contains('sub')) {
        netAmount ??= amount;
      }
    }

    return netAmount ?? tender ?? grossAmount;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════════

  static final RegExp _datePattern = RegExp(
    r'(\b\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}\b|\b\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2}\b)',
  );

  DateTime? _extractBillDate(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      // Only look at lines with "date" label, skip "miti" (Nepali calendar)
      if (lower.contains('miti')) continue;
      if (!lower.contains('date')) continue;
      final match = _datePattern.firstMatch(line);
      if (match != null) {
        final parsed = _tryParseDate(match.group(0)!);
        if (parsed != null) return parsed;
      }
    }
    // Second pass: any line with a date pattern
    for (final line in lines) {
      if (line.toLowerCase().contains('miti')) continue;
      final match = _datePattern.firstMatch(line);
      if (match != null) {
        final parsed = _tryParseDate(match.group(0)!);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  DateTime? _tryParseDate(String input) {
    final cleaned = input.trim().replaceAll('.', '/').replaceAll('-', '/');
    final parts = cleaned.split('/');
    if (parts.length != 3) return null;

    int? year, month, day;
    if (parts[0].length == 4) {
      year = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      day = int.tryParse(parts[2]);
    } else {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      year = int.tryParse(parts[2]);
      if (year != null && year < 100) year += 2000;
    }

    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year > 2100 || year < 2000) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return null;
    }
    return candidate;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY INFERENCE
  // ═══════════════════════════════════════════════════════════════════════════

  static String inferCategoryId(
      String itemName, List<AppCategory> categories) {
    final lower = itemName.toLowerCase();

    const keywordMap = <String, List<String>>{
      'food': [
        'rice', 'momo', 'pizza', 'burger', 'coffee', 'tea', 'snack', 'meal',
        'milk', 'bread', 'egg', 'chicken', 'vegetable', 'fruit', 'water',
        'coke', 'pepsi', 'juice', 'noodle', 'dal', 'restaurant', 'cafe',
        'thali', 'roti', 'curry', 'samosa', 'chow', 'fried', 'soup',
        'drink', 'beer', 'wine', 'meat', 'fish', 'prawn', 'paneer',
        'spaghetti', 'pasta', 'carbonara', 'sizzler', 'lassi', 'chocolate',
        'peach', 'sandwich', 'wrap', 'salad', 'dessert', 'cake', 'momos',
        'chowmein', 'buff', 'mutton', 'pork', 'sekuwa', 'biryani',
      ],
      'transport': [
        'bus', 'taxi', 'petrol', 'diesel', 'fuel', 'uber', 'pathao',
        'flight', 'ticket', 'parking', 'fare', 'auto', 'rickshaw',
      ],
      'shopping': [
        'shirt', 'pant', 'shoe', 'bag', 'soap', 'shampoo', 'grocery',
        'store', 'mart', 'cloth', 'dress', 'jacket',
      ],
      'bills': [
        'electricity', 'internet', 'wifi', 'recharge', 'rent', 'subscription',
      ],
    };

    for (final entry in keywordMap.entries) {
      final match = categories.where((c) =>
          c.title.toLowerCase().contains(entry.key)).toList();
      if (match.isEmpty) continue;
      if (entry.value.any(lower.contains)) return match.first.id;
    }

    final others = categories.where((c) {
      final t = c.title.toLowerCase();
      return t == 'others' || t == 'other';
    }).toList();
    return others.isNotEmpty ? others.first.id : categories.first.id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  ReceiptLineItem _makeItem(
      String name, double amount, List<AppCategory> categories) {
    final cleaned = _cleanName(name);
    return ReceiptLineItem(
      name: cleaned.isEmpty ? 'Unknown Item' : cleaned,
      amount: amount,
      categoryId: inferCategoryId(cleaned, categories),
    );
  }
}

class _OcrWord {
  final String text;
  final Rect rect;
  _OcrWord(this.text, this.rect);
}
