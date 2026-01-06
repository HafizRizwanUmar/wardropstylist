
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clothing_item.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';
import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class AIService {
  final _uuid = const Uuid();

  Future<ClothingItem> analyzeImage(String imagePath) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: kGeminiApiKey);
    final imageBytes = await File(imagePath).readAsBytes();
    
    final prompt = TextPart('''
    Analyze this clothing item and return a JSON object with the following fields:
    - type: (e.g., T-Shirt, Jeans, Dress)
    - subtype: (e.g., Crew Neck, Skinny, Maxi)
    - colors: [List of strings]
    - pattern: (e.g., Solid, Striped, Floral)
    - seasons: [List of strings]
    - formality: (e.g., Casual, Formal, Business)
    - events: [List of strings]
    - pairingSuggestions: [List of 2-3 specific items that would go well with this]
    
    Only return valid JSON. Do not include markdown formatting like ```json ... ```.
    ''');
    
    final content = [Content.multi([prompt, DataPart('image/jpeg', imageBytes)])];
    
    try {
      final response = await model.generateContent(content);
      final text = response.text ?? '{}';
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanText) as Map<String, dynamic>;
      
      return ClothingItem(
        id: _uuid.v4(),
        imageUrl: imagePath,
        type: data['type'] ?? 'Unknown',
        subtype: data['subtype'] ?? 'Unknown',
        colors: List<String>.from(data['colors'] ?? []),
        pattern: data['pattern'] ?? 'Solid',
        seasons: List<String>.from(data['seasons'] ?? []),
        formality: data['formality'] ?? 'Casual',
        events: List<String>.from(data['events'] ?? []),
        pairingSuggestions: List<String>.from(data['pairingSuggestions'] ?? []),
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      print('Error analyzing image: $e');
      // Return a basic item on error/fallback
      return ClothingItem(
        id: _uuid.v4(),
        imageUrl: imagePath,
        type: 'Unknown Item',
        subtype: 'Unknown',
        colors: [],
        pattern: 'Unknown',
        seasons: [],
        formality: 'Unknown',
        events: [],
        pairingSuggestions: [],
        dateAdded: DateTime.now(),
      );
    }
  }

  Future<String> getOutfitRecommendation(String query, List<ClothingItem> wardrobe) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: kGeminiApiKey);
    
    final wardrobeDescription = wardrobe.map((item) => 
      '- ${item.colors.join(", ")} ${item.pattern} ${item.type} (${item.subtype}) suitable for ${item.events.join(", ")}'
    ).join('\n');
    
    final prompt = '''
    You are a professional fashion stylist. The user is asking: "$query".
    
    Here is their current wardrobe:
    $wardrobeDescription
    
    Recommend an outfit from their wardrobe that fits their request and current fashion trends. 
    Explain why you chose it. If they don't have suitable items, suggest what they should buy.
    Keep the tone helpful, stylish, and encouraging. Use emojis.
    ''';
    
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    
    return response.text ?? "I couldn't generate a recommendation at this time. Please try again! 👗";
  }
}

final aiServiceProvider = Provider((ref) => AIService());
