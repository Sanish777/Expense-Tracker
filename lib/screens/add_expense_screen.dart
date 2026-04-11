import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../models/app_category.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../services/ocr_service.dart';

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
  AppCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
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
        _scanReceipt();
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

  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);
    final total = await _ocrService.scanReceiptTotal();
    
    if (mounted) {
      if (total != null) {
        _amountController.text = total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount extracted successfully!'), backgroundColor: AppTheme.accent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect amount. Please enter manually.'), backgroundColor: AppTheme.danger),
        );
      }
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
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
      setState(() {
        _selectedDate = DateTime.now();
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        automaticallyImplyLeading: false,
        leading: widget.onClose != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: widget.onClose,
              )
            : null,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount input
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
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
                        const Text('Amount (Rs.)',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        _isScanning 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : IconButton(
                                onPressed: _scanReceipt,
                                icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Scan Receipt',
                              ),
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
                        hintStyle: TextStyle(
                            color: Colors.white38, fontSize: 36),
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
              const Text('Category',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Category chips
              Consumer<CategoryProvider>(
                builder: (context, catProv, _) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: catProv.categories.map((cat) {
                      return CategoryChip(
                        category: cat,
                        isSelected: cat.id == _selectedCategory?.id,
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  );
                },
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Date picker
              const Text('Date',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Note
              const Text('Note (optional)',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lunch at Bhojan Griha…',
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2),
                        )
                      : const Text('Save Expense'),
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
