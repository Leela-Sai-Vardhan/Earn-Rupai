class GameModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String gameUrl;
  final double entryCost; // coins required to play
  final int tokenRewardMax; // max tokens per play
  final String category;

  const GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.gameUrl,
    required this.entryCost,
    required this.tokenRewardMax,
    required this.category,
  });
}
