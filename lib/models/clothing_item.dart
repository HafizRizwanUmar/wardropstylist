
class ClothingItem {
  final String id;
  final String imageUrl;
  final String type; // e.g., Shirt, Pant
  final String subtype; // e.g., T-Shirt, Jeans
  final List<String> colors;
  final String pattern;
  final List<String> seasons; // Summer, Winter
  final String formality; // Casual, Formal
  final List<String> events; // Party, Office
  final List<String> pairingSuggestions;
  final DateTime dateAdded;

  ClothingItem({
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.subtype,
    required this.colors,
    required this.pattern,
    required this.seasons,
    required this.formality,
    required this.events,
    required this.pairingSuggestions,
    required this.dateAdded,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      type: json['type'] as String,
      subtype: json['subtype'] as String,
      colors: List<String>.from(json['colors'] ?? []),
      pattern: json['pattern'] as String,
      seasons: List<String>.from(json['seasons'] ?? []),
      formality: json['formality'] as String,
      events: List<String>.from(json['events'] ?? []),
      pairingSuggestions: List<String>.from(json['pairingSuggestions'] ?? []),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'type': type,
      'subtype': subtype,
      'colors': colors,
      'pattern': pattern,
      'seasons': seasons,
      'formality': formality,
      'events': events,
      'pairingSuggestions': pairingSuggestions,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  ClothingItem copyWith({
    String? id,
    String? imageUrl,
    String? type,
    String? subtype,
    List<String>? colors,
    String? pattern,
    List<String>? seasons,
    String? formality,
    List<String>? events,
    List<String>? pairingSuggestions,
    DateTime? dateAdded,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      colors: colors ?? this.colors,
      pattern: pattern ?? this.pattern,
      seasons: seasons ?? this.seasons,
      formality: formality ?? this.formality,
      events: events ?? this.events,
      pairingSuggestions: pairingSuggestions ?? this.pairingSuggestions,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}
