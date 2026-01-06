
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Implemented persistence for images
import 'package:path/path.dart' as path;
import '../../models/clothing_item.dart';
import '../../services/ai_service.dart';

class WardrobeNotifier extends StateNotifier<List<ClothingItem>> {
  final AIService _aiService;
  static const _prefsKey = 'wardrobe_items';

  WardrobeNotifier(this._aiService) : super([]) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(_prefsKey);
      if (itemsJson != null) {
        final List<dynamic> decodedList = jsonDecode(itemsJson);
        final items = decodedList
            .map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (e) {
      print('Error loading wardrobe items: $e');
    }
  }

  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList =
          jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, encodedList);
    } catch (e) {
      print('Error saving wardrobe items: $e');
    }
  }

  Future<void> addItem(String imagePath) async {
    // 0. Save image permanently to app documents
    final directory = await getApplicationDocumentsDirectory();
    final name = path.basename(imagePath);
    final savedImage = await File(imagePath).copy('${directory.path}/$name');

    // 1. Analyze image (use the saved path)
    final newItem = await _aiService.analyzeImage(savedImage.path);

    // 2. Add to state
    state = [...state, newItem];
    
    // 3. Save to storage
    await _saveItems();
  }

  Future<void> removeItem(String id) async {
    // Optional: Delete the file from valid storage if we want to clean up
    final itemToRemove = state.firstWhere((item) => item.id == id, orElse: () => ClothingItem(id: '', imageUrl: '', type: '', subtype: '', colors: [], pattern: '', seasons: [], formality: '', events: [], pairingSuggestions: [], dateAdded: DateTime.now()));
    
    if (itemToRemove.id.isNotEmpty) {
       try {
         final file = File(itemToRemove.imageUrl);
         if (await file.exists()) {
           await file.delete();
         }
       } catch (e) {
         print("Error deleting file: $e");
       }
    }

    state = state.where((item) => item.id != id).toList();
    await _saveItems();
  }
}

final wardrobeProvider =
    StateNotifierProvider<WardrobeNotifier, List<ClothingItem>>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return WardrobeNotifier(aiService);
});
