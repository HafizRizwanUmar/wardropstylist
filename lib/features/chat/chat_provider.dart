
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../wardrobe/wardrobe_provider.dart';
import 'package:uuid/uuid.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AIService _aiService;
  final Ref _ref;
  final _uuid = const Uuid();

  ChatNotifier(this._aiService, this._ref) : super([
    ChatMessage(
      id: 'welcome',
      text: "Hi! I'm your AI stylist. Upload your wardrobe to get started 👕👖",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String text) async {
    // 1. Add user message
    final userMsg = ChatMessage(
        id: _uuid.v4(),
        text: text,
        isUser: true,
        timestamp: DateTime.now());
    state = [...state, userMsg];

    // 2. Mock AI typing/processing
    // (Optional: add a "typing" state here)

    // 3. Get Recommendation
    // We need access to the current wardrobe to give context
    final wardrobe = _ref.read(wardrobeProvider);
    final responseText = await _aiService.getOutfitRecommendation(text, wardrobe);

    // 4. Add AI response
    final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now());
    state = [...state, aiMsg];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ChatNotifier(aiService, ref);
});
