import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../models/app_category.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../services/ocr_service.dart' hide ReceiptLineItem;

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final bool autoScan;
  const AddExpenseScreen({super.key, this.onClose, this.autoScan = false});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final OCRService _ocrService = OCRService();
  final Uuid _uuid = const Uuid();
  AppCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<ReceiptLineItemPreview> _scannedItems = [];
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<CategoryProvider>().categories;
      if (categories.isNotEmpty) {
        setState(() => _selectedCategory = categories.first);
      }
      if (widget.autoScan) {
        // _scanReceipt(); // Scanning disabled for now
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // ── Scanning ─────────────────────────────────────────────────────────────

  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);
    final categories = context.read<CategoryProvider>().categories;

    try {
      final result = await _ocrService.scanReceiptItems(categories);

      if (!mounted) return;

      if (result == null) {
        // User cancelled camera
        setState(() => _isScanning = false);
        return;
      }

      if (result.items.isNotEmpty) {
        final total = result.total ??
            result.items.fold<double>(0, (sum, item) => sum + item.amount);
        _amountController.text =
            total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);
        _noteController.text = 'Imported from scanned bill';
        setState(() {
          _selectedDate = result.billDate ?? _selectedDate;
          _scannedItems = result.items
              .map((item) => ReceiptLineItemPreview(
                    name: item.name,
                    amount: item.amount,
                    categoryId: item.categoryId,
                  ))
              .toList();
        });
        _showSuccess('${result.items.length} items scanned 📷');
      } else if (result.total != null && result.total! > 0) {
        final total = result.total!;
        _amountController.text =
            total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);
        if (result.billDate != null) {
          setState(() => _selectedDate = result.billDate!);
        }
        _showInfo(
            'Bill total detected: Rs. ${total.toStringAsFixed(0)}. Add items manually.');
      } else {
        _showError(
          'No items found. Hold the camera steady, keep the full bill visible with good lighting.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Scan error: ${e.toString().split('\n').first}');
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_scannedItems.isNotEmpty) {
      await _saveScannedItems();
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isSaving = true);
    final expProv = context.read<ExpenseProvider>();
    final budget = context.read<BudgetProvider>().budget;

    await expProv.addExpense(
      amount: amount,
      category: _selectedCategory!.id,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      budget: budget,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Expense added! Rs. ${amount.toStringAsFixed(0)}'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ));
      _amountController.clear();
      _noteController.clear();
      setState(() => _selectedDate = DateTime.now());
    }
  }

  Future<void> _saveScannedItems() async {
    final validItems = _scannedItems.where((item) => item.amount > 0).toList();
    if (validItems.isEmpty) {
      _showError('No valid bill items found to save');
      return;
    }

    setState(() => _isSaving = true);
    final expProv = context.read<ExpenseProvider>();
    final budget = context.read<BudgetProvider>().budget;

    final expenses = validItems
        .map(
          (item) => Expense(
            id: _uuid.v4(),
            amount: item.amount,
            category: item.categoryId,
            date: _selectedDate,
            note: item.name,
          ),
        )
        .toList();

    await expProv.addExpenses(expenses: expenses, budget: budget);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _scannedItems = [];
      _selectedDate = DateTime.now();
    });
    _amountController.clear();
    _noteController.clear();

    _showSuccess('${expenses.length} expenses imported from bill 🎉');
  }

  // ── Scanned items management ──────────────────────────────────────────────

  void _updateScannedItemCategory(int index, String categoryId) {
    setState(() {
      _scannedItems[index] = _scannedItems[index].copyWith(categoryId: categoryId);
    });
  }

  void _updateScannedItemName(int index, String name) {
    setState(() {
      _scannedItems[index] = _scannedItems[index].copyWith(name: name);
    });
  }

  void _updateScannedItemAmount(int index, double amount) {
    setState(() {
      _scannedItems[index] = _scannedItems[index].copyWith(amount: amount);
    });
  }

  void _removeScannedItem(int index) {
    setState(() {
      _scannedItems.removeAt(index);
    });
  }

  void _addBlankItem() {
    final categories = context.read<CategoryProvider>().categories;
    if (categories.isEmpty) return;
    setState(() {
      _scannedItems.add(ReceiptLineItemPreview(
        name: 'New Item',
        amount: 0,
        categoryId: categories.first.id,
      ));
    });
  }

  void _clearScannedItems() {
    setState(() {
      _scannedItems = [];
      _amountController.clear();
      _noteController.clear();
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.accent,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.primary,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Discard guard ─────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (_scannedItems.isEmpty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard scanned items?'),
        content: Text(
            'You have ${_scannedItems.length} unsaved item${_scannedItems.length > 1 ? 's' : ''}. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBillImport = _scannedItems.isNotEmpty;

    // Determine if we're on the stack vs in the tab shell
    final canPop = Navigator.canPop(context);
    final showBackButton = canPop || widget.onClose != null;

    return PopScope(
      canPop: _scannedItems.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _scannedItems.isNotEmpty) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isBillImport ? 'Review Bill Items' : 'Add Expense'),
          automaticallyImplyLeading: false,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () async {
                    if (_scannedItems.isNotEmpty) {
                      final shouldLeave = await _onWillPop();
                      if (shouldLeave && context.mounted) {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      }
                    } else {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                )
              : null,
          actions: [
            if (isBillImport)
              TextButton.icon(
                onPressed: _clearScannedItems,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount / Scan header ──────────────────────────────────
                if (!isBillImport) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount (Rs.)',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            _isScanning
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const SizedBox.shrink(), // Scan disabled for now
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle:
                                TextStyle(color: Colors.white38, fontSize: 36),
                            filled: false,
                            border: InputBorder.none,
                            prefixText: 'Rs. ',
                            prefixStyle: TextStyle(
                                color: Colors.white60,
                                fontSize: 20,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                  const SizedBox(height: 24),

                  // ── Category ────────────────────────────────────────────
                  const Text('Category',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  Consumer<CategoryProvider>(
                    builder: (context, catProv, _) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: catProv.categories.map((cat) {
                          return CategoryChip(
                            category: cat,
                            isSelected: cat.id == _selectedCategory?.id,
                            onTap: () => setState(() => _selectedCategory = cat),
                          );
                        }).toList(),
                      );
                    },
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── Date ────────────────────────────────────────────────
                  const Text('Date',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _DatePickerRow(date: _selectedDate, onTap: _pickDate),

                  const SizedBox(height: 24),

                  // ── Note ────────────────────────────────────────────────
                  const Text('Note (optional)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Lunch at Bhojan Griha…',
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ] else ...[
                  // ── Bill Import mode ─────────────────────────────────────

                  // Summary header
                  _BillSummaryHeader(
                    items: _scannedItems,
                    date: _selectedDate,
                    onDateTap: _pickDate,
                    onScanAgain: null, // Scanning disabled for now
                    isScanning: _isScanning,
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 20),

                  // Items list header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_scannedItems.length} Item${_scannedItems.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: _addBlankItem,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Item'),
                        style:
                            TextButton.styleFrom(foregroundColor: AppTheme.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Consumer<CategoryProvider>(
                    builder: (context, catProv, _) {
                      return Column(
                        children: List.generate(_scannedItems.length, (index) {
                          return _ScannedItemCard(
                            key: ValueKey('item_$index'),
                            item: _scannedItems[index],
                            categories: catProv.categories,
                            index: index,
                            onRemove: () => _removeScannedItem(index),
                            onNameChanged: (v) => _updateScannedItemName(index, v),
                            onAmountChanged: (v) =>
                                _updateScannedItemAmount(index, v),
                            onCategoryChanged: (v) =>
                                _updateScannedItemCategory(index, v),
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: 40 * index),
                              duration: 300.ms);
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // Help text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Swipe left on an item to remove it. Tap the name or amount to edit.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],

                const SizedBox(height: 32),

                // ── Save button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSaving ||
                            (isBillImport && _scannedItems.isEmpty))
                        ? null
                        : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isBillImport
                                ? 'Import ${_scannedItems.length} Item${_scannedItems.length > 1 ? 's' : ''}'
                                : 'Save Expense',
                          ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ScanButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, d MMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }
}

class _BillSummaryHeader extends StatelessWidget {
  final List<ReceiptLineItemPreview> items;
  final DateTime date;
  final VoidCallback onDateTap;
  final VoidCallback? onScanAgain;
  final bool isScanning;

  const _BillSummaryHeader({
    required this.items,
    required this.date,
    required this.onDateTap,
    required this.onScanAgain,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanned Bill',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('${items.length} items detected',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              if (isScanning)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
              else if (onScanAgain != null)
                GestureDetector(
                  onTap: onScanAgain,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Rescan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMM yyyy').format(date),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannedItemCard extends StatefulWidget {
  final ReceiptLineItemPreview item;
  final List<AppCategory> categories;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<String> onCategoryChanged;

  const _ScannedItemCard({
    super.key,
    required this.item,
    required this.categories,
    required this.index,
    required this.onRemove,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onCategoryChanged,
  });

  @override
  State<_ScannedItemCard> createState() => _ScannedItemCardState();
}

class _ScannedItemCardState extends State<_ScannedItemCard> {
  bool _editingName = false;
  bool _editingAmount = false;
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _amountController = TextEditingController(
      text: widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(
              widget.item.amount.truncateToDouble() == widget.item.amount
                  ? 0
                  : 2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  AppCategory? get _selectedCat {
    try {
      return widget.categories
          .firstWhere((c) => c.id == widget.item.categoryId);
    } catch (_) {
      return widget.categories.isNotEmpty ? widget.categories.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _selectedCat;
    final isInvalid = widget.item.amount <= 0;

    return Dismissible(
      key: widget.key ?? ValueKey(widget.index),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            const SizedBox(height: 4),
            const Text('Remove',
                style: TextStyle(color: AppTheme.danger, fontSize: 11)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isInvalid
                  ? AppTheme.danger
                  : (cat != null
                      ? AppTheme.primary
                      : AppTheme.primary),
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name row ────────────────────────────────────────────────
              Row(
                children: [
                  Text(cat?.emoji ?? '📦',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _editingName
                        ? TextField(
                            controller: _nameController,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 4),
                              border: UnderlineInputBorder(),
                            ),
                            onSubmitted: (v) {
                              setState(() => _editingName = false);
                              if (v.trim().isNotEmpty) {
                                widget.onNameChanged(v.trim());
                              }
                            },
                            onTapOutside: (_) {
                              setState(() => _editingName = false);
                              final v = _nameController.text.trim();
                              if (v.isNotEmpty) widget.onNameChanged(v);
                            },
                          )
                        : GestureDetector(
                            onTap: () => setState(() => _editingName = true),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.item.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Icon(Icons.edit_outlined,
                                    size: 14, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Amount chip
                  GestureDetector(
                    onTap: () => setState(() => _editingAmount = true),
                    child: _editingAmount
                        ? SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _amountController,
                              autofocus: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]')),
                              ],
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                                border: UnderlineInputBorder(),
                                prefixText: 'Rs. ',
                                prefixStyle: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted),
                              ),
                              onSubmitted: (v) {
                                setState(() => _editingAmount = false);
                                final parsed = double.tryParse(v);
                                if (parsed != null) {
                                  widget.onAmountChanged(parsed);
                                }
                              },
                              onTapOutside: (_) {
                                setState(() => _editingAmount = false);
                                final parsed = double.tryParse(
                                    _amountController.text);
                                if (parsed != null) {
                                  widget.onAmountChanged(parsed);
                                }
                              },
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isInvalid
                                  ? AppTheme.danger.withValues(alpha: 0.1)
                                  : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isInvalid
                                  ? 'Tap to set'
                                  : 'Rs. ${widget.item.amount.toStringAsFixed(widget.item.amount.truncateToDouble() == widget.item.amount ? 0 : 2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isInvalid
                                    ? AppTheme.danger
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Category chips row ───────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final c = widget.categories[i];
                    final isSelected = c.id == widget.item.categoryId;
                    return GestureDetector(
                      onTap: () => widget.onCategoryChanged(c.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.emoji,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              c.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? AppTheme.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class ReceiptLineItemPreview {
  final String name;
  final double amount;
  final String categoryId;

  const ReceiptLineItemPreview({
    required this.name,
    required this.amount,
    required this.categoryId,
  });

  ReceiptLineItemPreview copyWith({
    String? name,
    double? amount,
    String? categoryId,
  }) {
    return ReceiptLineItemPreview(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
