import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _titleController = TextEditingController();
  final _emojiController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final emoji = _emojiController.text.trim();

    if (title.isEmpty || emoji.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and emoji')),
      );
      return;
    }

    context.read<CategoryProvider>().addCategory(title, emoji);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Category')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Health, Gift',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emojiController,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Icon (Emoji)',
                hintText: 'Tap your keyboard icon 😊',
                prefixIcon: Icon(Icons.emoji_emotions_outlined),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Design Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
