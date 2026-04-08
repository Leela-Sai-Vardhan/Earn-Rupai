import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/game_model.dart';
import '../../data/services/game_service.dart';
import '../../data/services/token_service.dart';
import '../../../../shared/services/admob_service.dart';

class GamePlayScreen extends StatefulWidget {
  final GameModel game;

  const GamePlayScreen({super.key, required this.game});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late final WebViewController _controller;
  int _secondsPlayed = 0;
  Timer? _timer;
  bool _isLoading = true;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startTimer();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.game.gameUrl));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsPlayed++);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _exitGame() async {
    if (_gameEnded) return;
    _gameEnded = true;
    _timer?.cancel();

    final tokensEarned = GameService.calculateTokenReward(_secondsPlayed);

    Future<void> showDialogAndExit(int actualEarned) async {
      double newBalance = 0;
      if (actualEarned > 0) {
        newBalance = await TokenService.addTokens(actualEarned);
      } else {
        newBalance = await TokenService.getTokenBalance();
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _GameResultDialog(
          game: widget.game,
          secondsPlayed: _secondsPlayed,
          tokensEarned: actualEarned,
          newTokenBalance: newBalance,
          onBackToGames: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
        ),
      );
    }

    // Show blocking overlay so the game background isn't visible during ad play/load
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.white,
        builder: (context) => const SizedBox.expand(),
      );
    }

    // Always show a rewarded ad on game exit, regardless of whether tokens were earned
    AdMobService.showRewardedAd(
      onUserEarnedReward: () {
        // The reward tracking is handled by onAdDismissed's earnedReward parameter
      },
      onAdFailedToLoad: () {
        if (mounted) Navigator.pop(context); // Close overlay
        // If the ad fails to load, gracefully fallback to granting the tokens
        showDialogAndExit(tokensEarned);
      },
      onAdDismissed: (earnedReward) {
        if (mounted) Navigator.pop(context); // Close overlay
        showDialogAndExit(earnedReward ? tokensEarned : 0);
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_gameEnded) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Game?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time played: ${_formatTime(_secondsPlayed)}',
              style: AppTextStyles.bodyMedium(color: AppColors.greyText),
            ),
            const SizedBox(height: 8),
            Text(
              _secondsPlayed < 120
                  ? 'Play at least 2 minutes to earn tokens!'
                  : 'You\'ll earn ${GameService.calculateTokenReward(_secondsPlayed)} tokens.',
              style: AppTextStyles.bodyMedium(
                color: _secondsPlayed < 120 ? AppColors.error : AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Playing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit & Collect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _exitGame();
    }

    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: game info + timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button
                    InkWell(
                      onTap: _onWillPop,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, color: AppColors.primaryPurple, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Game title
                    Expanded(
                      child: Text(
                        widget.game.title,
                        style: AppTextStyles.label(
                          color: isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _secondsPlayed < 30
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: _secondsPlayed < 30 ? AppColors.error : AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_secondsPlayed),
                            style: AppTextStyles.label(
                              color: _secondsPlayed < 30 ? AppColors.error : AppColors.primaryGreen,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Token indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.token, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '+${GameService.calculateTokenReward(_secondsPlayed)}',
                            style: AppTextStyles.caption(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // WebView
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryPurple),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameResultDialog extends StatelessWidget {
  final GameModel game;
  final int secondsPlayed;
  final int tokensEarned;
  final double newTokenBalance;
  final VoidCallback onBackToGames;

  const _GameResultDialog({
    required this.game,
    required this.secondsPlayed,
    required this.tokensEarned,
    required this.newTokenBalance,
    required this.onBackToGames,
  });

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              tokensEarned > 0 ? 'Game Complete!' : 'Game Over',
              style: AppTextStyles.h3(
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            _buildStatRow(
              Icons.timer_outlined,
              'Time Played',
              _formatTime(secondsPlayed),
              AppColors.greyText,
            ),
            const Divider(height: 20),
            _buildStatRow(
              Icons.toll,
              'Entry Cost',
              '${game.entryCost.toStringAsFixed(1)} coins',
              AppColors.primaryOrange,
            ),
            const Divider(height: 20),
            _buildStatRow(
              Icons.token,
              'Tokens Earned',
              tokensEarned > 0 ? '+$tokensEarned' : '0',
              tokensEarned > 0 ? AppColors.primaryGreen : AppColors.error,
            ),
            const Divider(height: 20),
            _buildStatRow(
              Icons.account_balance_wallet,
              'Token Balance',
              newTokenBalance.toStringAsFixed(0),
              AppColors.primaryPurple,
            ),

            if (tokensEarned == 0) ...[
              const SizedBox(height: 12),
              Text(
                'Play at least 30 seconds to earn tokens!',
                style: AppTextStyles.caption(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),
            // Back to games button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToGames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Games'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.greyText),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyMedium(color: AppColors.greyText)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium(color: valueColor).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
