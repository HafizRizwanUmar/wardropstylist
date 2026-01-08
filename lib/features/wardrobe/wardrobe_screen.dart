
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'wardrobe_provider.dart';
import 'widgets/clothing_card.dart';

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  Future<void> _pickImage(WidgetRef ref, BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyzing image... 🤖')),
        );
      }
      
      try {
        final bytes = await image.readAsBytes(); // Read bytes for Web support
        await ref.read(wardrobeProvider.notifier).addItem(bytes, image.name);
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added! 👕')),
          );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clothingItems = ref.watch(wardrobeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
      ),
      body: clothingItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.checkroom, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(
                    'Your wardrobe is empty.',
                    style: Theme.of(context).textTheme.titleMedium,
                   ),
                   const SizedBox(height: 8),
                   const Text('Tap + to add your clothes!'),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: clothingItems.length,
              itemBuilder: (context, index) {
                return ClothingCard(item: clothingItems[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImage(ref, context),
        tooltip: 'Add Item',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
