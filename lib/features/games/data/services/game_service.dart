import '../models/game_model.dart';

class GameService {
  /// Hardcoded list of 2 games for Phase 1
  static const List<GameModel> availableGames = [
    GameModel(
      id: 'candy_match',
      title: 'Sweet Candy Shop',
      description: 'Swap and match candies to progress through levels and earn rewards!',
      imageUrl: 'https://img.gamemonetize.com/lqqr1rja6jn7em838kx0p2x77o2pfhxh/512x384.jpg',
      gameUrl: 'https://html5.gamemonetize.co/lqqr1rja6jn7em838kx0p2x77o2pfhxh/',
      entryCost: 0.5,
      tokenRewardMax: 20,
      category: 'Puzzle',
    ),
    GameModel(
      id: 'orbit_rush',
      title: 'Orbit Tap Rush',
      description: 'Fast-paced arcade game! Tap to reverse orbit and dodge obstacles.',
      imageUrl: 'https://img.gamemonetize.com/skq5w0gwq9coozmm0spmn6r92ayjo0gj/512x384.jpg',
      gameUrl: 'https://html5.gamemonetize.co/skq5w0gwq9coozmm0spmn6r92ayjo0gj/',
      entryCost: 0.5,
      tokenRewardMax: 20,
      category: 'Arcade',
    ),
  ];

  /// Calculate token reward based on time played
  /// Tiers: 0–2min = 0, 2–5min = 5, 5–10min = 10, 10+min = 15 (max)
  static int calculateTokenReward(int secondsPlayed) {
    if (secondsPlayed < 120) return 0;      // Under 2 min — no reward
    if (secondsPlayed < 300) return 5;      // 2 – 5 min
    if (secondsPlayed < 600) return 10;     // 5 – 10 min
    return 15;                              // 10+ min (max)
  }
}
