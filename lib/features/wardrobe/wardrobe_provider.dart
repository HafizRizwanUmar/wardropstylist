import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/clothing_item.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart'; // For baseUrl

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

  Future<void> addItem(Uint8List imageBytes, String filename) async {
    try {
      // 1. Upload image to backend
      final imageUrl = await _uploadImage(imageBytes, filename);
      if (imageUrl == null) throw Exception('Failed to upload image');

      // 2. Analyze image (pass bytes directly)
      final newItem = await _aiService.analyzeImage(imageBytes, 'image/jpeg'); 
      
      // Update the item with the verified remote URL
      final completeItem = newItem.copyWith(imageUrl: imageUrl);

      // 3. Add to state
      state = [...state, completeItem];
      
      // 4. Save to storage
      await _saveItems();
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  Future<String?> _uploadImage(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/images/upload');
    print('DEBUG: Attempting upload to: $uri');
    print('DEBUG: Image size: ${bytes.length} bytes');
    
    final request = http.MultipartRequest('POST', uri);
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: filename
      )
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final host = baseUrl.replaceAll('/api', '');
        return '$host${data['imageUrl']}';
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> removeItem(String id) async {
    // API call to delete image could go here
    state = state.where((item) => item.id != id).toList();
    await _saveItems();
  }
}

final wardrobeProvider =
    StateNotifierProvider<WardrobeNotifier, List<ClothingItem>>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return WardrobeNotifier(aiService);
});
