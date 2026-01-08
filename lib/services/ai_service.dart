import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clothing_item.dart';
import '../core/constants/api_constants.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AIService {
  final _uuid = const Uuid();
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<ClothingItem> analyzeImage(Uint8List imageBytes, String mimeType) async {
    final url = Uri.parse('$_baseUrl?key=$kGeminiApiKey');
    
    final promptText = '''
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
    ''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Encode(imageBytes)
              }
            }
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        print('Gemini API Error: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final textFn = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
      var text = textFn?.toString() ?? '{}';
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanText) as Map<String, dynamic>;
      
      return ClothingItem(
        id: _uuid.v4(),
        imageUrl: '',
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
      return ClothingItem(
        id: _uuid.v4(),
        imageUrl: '',
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
    final url = Uri.parse('$_baseUrl?key=$kGeminiApiKey');

    final wardrobeDescription = wardrobe.map((item) => 
      '- ${item.colors.join(", ")} ${item.pattern} ${item.type} (${item.subtype}) suitable for ${item.events.join(", ")}'
    ).join('\n');
    
    final promptText = '''
    You are a professional fashion stylist. The user is asking: "$query".
    
    Here is their current wardrobe:
    $wardrobeDescription
    
    Recommend an outfit from their wardrobe that fits their request and current fashion trends. 
    Explain why you chose it. If they don't have suitable items, suggest what they should buy.
    Keep the tone helpful, stylish, and encouraging. Use emojis.
    ''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptText}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        print('Gemini API Error: ${response.body}');
        return "I'm having trouble connecting to the style server right now. Please try again later! 😓 (Status: ${response.statusCode})";
      }

      final jsonResponse = jsonDecode(response.body);
      final text = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      return text?.toString() ?? "I couldn't generate a recommendation at this time. Please try again! 👗";
    } catch (e) {
      print('GenAI Error: $e');
      return "I'm having trouble connecting to the style server right now. Please try again later! 😓";
    }
  }
}

final aiServiceProvider = Provider((ref) => AIService());
