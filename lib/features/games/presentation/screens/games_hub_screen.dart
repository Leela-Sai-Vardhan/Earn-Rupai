import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../spin_win/data/services/coin_service.dart';
import '../../data/models/game_model.dart';
import '../../data/services/game_service.dart';
import '../../data/services/token_service.dart';
import '../widgets/game_card.dart';
import 'game_play_screen.dart';
import '../../../spin_win/presentation/screens/spin_win_screen.dart';
import '../../../../shared/services/admob_service.dart';

class GamesHubScreen extends ConsumerStatefulWidget {
  const GamesHubScreen({super.key});

  @override
  ConsumerState<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends ConsumerState<GamesHubScreen> {
  double _coinBalance = 0;
  double _tokenBalance = 0;
  int _remainingPlays = TokenService.maxPlaysPerDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
    AdMobService.loadRewardedAd(); // Preload for game-end ad gate
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoading = true);
    try {
      final coinData = await CoinService.getCoinBalance();
      final tokens = await TokenService.getTokenBalance();
      final remaining = await TokenService.getRemainingPlays();
      if (mounted) {
        setState(() {
          _coinBalance = coinData.coinsBalance;
          _tokenBalance = tokens;
          _remainingPlays = remaining;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onGameTap(GameModel game) async {
    // Check if user can play
    final canPlay = await TokenService.canPlayGame();
    if (canPlay['canPlay'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(canPlay['reason'] as String),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Check coin balance
    if (_coinBalance < game.entryCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough coins! Need ${game.entryCost.toStringAsFixed(1)} coins to play.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.sports_esports, color: AppColors.primaryPurple),
            const SizedBox(width: 10),
            Expanded(child: Text(game.title, style: AppTextStyles.h4())),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(Icons.toll, 'Entry Cost', '${game.entryCost.toStringAsFixed(1)} coins', AppColors.primaryOrange),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.token, 'Max Reward', '${game.tokenRewardMax} tokens', AppColors.primaryPurple),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.account_balance_wallet, 'Your Balance', '${_coinBalance.toStringAsFixed(1)} coins', AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text(
              'Play longer to earn more tokens!',
              style: AppTextStyles.caption(color: AppColors.greyText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Play Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Deduct coins
    try {
      final deducted = await CoinService.deductCoinsForGame(game.entryCost, game.title);
      if (!deducted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough coins to play!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deduct coins: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Record game play
    await TokenService.recordGamePlay();

    // Navigate to game
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePlayScreen(game: game),
      ),
    );

    // Refresh balances when returning
    _loadBalances();
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyMedium(color: AppColors.greyText)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium(color: color).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBalances,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Rupai Games',
                  style: AppTextStyles.h2(
                    color: isDark ? AppColors.lightText : AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Play games, earn tokens!',
                  style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                ),
                const SizedBox(height: 20),

                // Balance cards
                Row(
                  children: [
                    Expanded(child: _buildBalanceCard(
                      icon: Icons.toll,
                      label: 'Coins',
                      value: _isLoading ? '...' : _coinBalance.toStringAsFixed(1),
                      gradient: AppColors.greenGradient,
                      isDark: isDark,
                      onTap: () => context.push('/wallet'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBalanceCard(
                      icon: Icons.token,
                      label: 'Game Tokens',
                      value: _isLoading ? '...' : _tokenBalance.toStringAsFixed(0),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                      ),
                      isDark: isDark,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Token withdrawal coming soon! Stay tuned.'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF6C63FF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 10),

                // ₹ Conversion rates
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard.withValues(alpha: 0.6) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildConversionChip(
                        Icons.toll,
                        '1 Coin = ₹1',
                        AppColors.primaryGreen,
                        isDark,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      _buildConversionChip(
                        Icons.token,
                        '100 Tokens = ₹100',
                        AppColors.primaryPurple,
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Spin & Win card
                _buildSpinWinCard(isDark),
                const SizedBox(height: 24),

                // Games section header
                Row(
                  children: [
                    const Text('🎮', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Play & Earn Tokens',
                      style: AppTextStyles.h4(
                        color: isDark ? AppColors.lightText : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Play longer to earn more tokens • Max ${TokenService.maxPlaysPerDay} plays/day',
                  style: AppTextStyles.caption(color: AppColors.greyText),
                ),
                const SizedBox(height: 16),

                // Game cards
                ...GameService.availableGames.map((game) => GameCard(
                  game: game,
                  remainingPlays: _remainingPlays,
                  onTap: () => _onGameTap(game),
                )),

                const SizedBox(height: 16),

                // Token reward info
                _buildRewardInfoCard(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.6), size: 12),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h3(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionChip(IconData icon, String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.caption(
            color: isDark ? AppColors.lightText : AppColors.darkText,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSpinWinCard(bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpinWinScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.casino, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spin & Earn',
                    style: AppTextStyles.h4(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spin the wheel daily to earn coins!',
                    style: AppTextStyles.bodySmall(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'How Token Rewards Work',
                style: AppTextStyles.label(color: AppColors.primaryPurple)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Watch an ad after the game to collect your tokens.',
            style: AppTextStyles.caption(color: AppColors.greyText),
          ),
          const SizedBox(height: 12),
          _buildRewardRow('Under 2 min', '0 tokens', AppColors.greyText),
          _buildRewardRow('2 – 5 min', '5 tokens', AppColors.greyText),
          _buildRewardRow('5 – 10 min', '10 tokens', AppColors.greyText),
          _buildRewardRow('10+ min', '15 tokens (max)', AppColors.primaryPurple),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String time, String reward, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: AppTextStyles.caption(color: AppColors.greyText)),
          Text(
            reward,
            style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
