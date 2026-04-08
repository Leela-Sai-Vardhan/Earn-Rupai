import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

import '../../data/services/coin_service.dart';
import '../../data/models/spin_result_model.dart';
import '../widgets/spin_wheel_widget.dart';
import '../../../../shared/services/admob_service.dart';
import '../../../../shared/utils/timezone_utils.dart';
import 'dart:async';
import '../../../../shared/services/review_service.dart';

class SpinWinScreen extends ConsumerStatefulWidget {
  const SpinWinScreen({super.key});

  @override
  ConsumerState<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinWinScreenState extends ConsumerState<SpinWinScreen> {
  Timer? _cooldownTimer;
  Timer? _resetCountdownTimer;
  int _cooldownSeconds = 0;
  String _resetCountdown = '';
  bool _isSpinning = false;
  bool _isLoading = true;
  CoinBalanceModel? _coinBalance;
  SpinResultModel? _lastSpinResult;

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
    _startResetCountdown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _resetCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCoinBalance() async {
    try {
      final balance = await CoinService.getCoinBalance();
      setState(() {
        _coinBalance = balance;
        _isLoading = false;
      });
      _checkCooldown();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading balance: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _checkCooldown() {
    if (_coinBalance?.lastSpinAt != null) {
      final timeSinceLastSpin =
          DateTime.now().difference(_coinBalance!.lastSpinAt!);
      final secondsRemaining = 30 - timeSinceLastSpin.inSeconds;

      if (secondsRemaining > 0) {
        setState(() => _cooldownSeconds = secondsRemaining);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _cooldownSeconds > 0) {
            setState(() => _cooldownSeconds--);
            _checkCooldown();
          }
        });
      }
    }
  }

  void _startResetCountdown() {
    _resetCountdownTimer?.cancel();
    _resetCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_coinBalance?.dailySpinsResetAt != null) {
        final now = DateTime.now().toUtc();
        final resetTime = _coinBalance!.dailySpinsResetAt!;
        final difference = resetTime.difference(now);

        if (difference.isNegative) {
          setState(() => _resetCountdown = '');
          _loadCoinBalance(); // Reload to get new spins
        } else {
          final hours = difference.inHours;
          final minutes = difference.inMinutes % 60;
          final seconds = difference.inSeconds % 60;
          
          if (hours > 0) {
            setState(() => _resetCountdown = '${hours}h ${minutes}m');
          } else if (minutes > 0) {
            setState(() => _resetCountdown = '${minutes}m ${seconds}s');
          } else {
            setState(() => _resetCountdown = '${seconds}s');
          }
        }
      }
    });
  }

  Future<void> _performSpin() async {
    if (_isSpinning || _cooldownSeconds > 0 || _coinBalance == null) return;

    // Check if user can spin
    try {
      final canSpin = await CoinService.canPerformSpin();
      if (canSpin['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(canSpin['message'] ?? 'Cannot spin'),
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSpinning = true);

    // Perform spin (client-side calculation)
    final spinResult = CoinService.performSpin(
      _coinBalance!.isFirstDaySpin,
      _coinBalance!.firstDaySpinCount,
    );

    setState(() => _lastSpinResult = spinResult);

    // The SpinWheelWidget will handle the animation and call _onSpinComplete when done
  }

  void _onSpinComplete() {
    // Show ad claim dialog after wheel stops
    if (mounted && _lastSpinResult != null) {
      _showAdClaimDialog(_lastSpinResult!.coinsWon);
    }
  }

  void _showAdClaimDialog(double coinsWon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Text(
          'You won ${coinsWon.toStringAsFixed(1)} coins!\n\nWatch a quick ad to claim your reward.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAdSkipped();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAdAndClaim(coinsWon);
            },
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  void _showAdAndClaim(double coinsWon) {
    // Show blocking overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white,
      builder: (context) => const SizedBox.expand(),
    );

    // Show rewarded ad
    AdMobService.showRewardedAd(
      onUserEarnedReward: () async {
        Navigator.pop(context); // Close overlay
        await _claimCoins(coinsWon, adWatched: true);
      },
      onAdFailedToLoad: () async {
        Navigator.pop(context); // Close overlay
        // Refund spin - don't consume it
        setState(() {
          _isSpinning = false;
          _cooldownSeconds = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available. Spin refunded!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      onAdDismissed: (earnedReward) {
        if (!earnedReward) {
          Navigator.pop(context); // Close overlay
          _handleAdSkipped();
        }
      },
    );
  }

  void _handleAdSkipped() async {
    // User skipped ad - consume spin but don't credit coins
    await _claimCoins(_lastSpinResult!.coinsWon, adWatched: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spin wasted! Watch ads to claim coins.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _claimCoins(double coinsWon, {required bool adWatched}) async {
    try {
      final result = await CoinService.claimSpinCoins(
        coinsWon,
        adWatched: adWatched,
      );

      if (result['success'] == true && adWatched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Claimed ${coinsWon.toStringAsFixed(1)} coins! New balance: ${result['new_balance']}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Trigger in-app review on first ever spin coin earned
        ReviewService.requestReviewAfterFirstSpin();
      }

      // Reload balance
      await _loadCoinBalance();
      setState(() {
        _isSpinning = false;
        _cooldownSeconds = 30;
      });
      _checkCooldown();
    } catch (e) {
      setState(() => _isSpinning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming coins: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryGreen,
      appBar: AppBar(
        title: const Text('Spin and Earn'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Coin Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Coin Balance',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.greyText : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '🪙 ${_coinBalance?.coinsBalance.toStringAsFixed(1) ?? '0.0'}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '≈ ₹${CoinService.coinsToRupees(_coinBalance?.coinsBalance ?? 0).toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? AppColors.greyText : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Spins Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Available Spins: ${_coinBalance?.spinsRemaining ?? 0}/5',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_cooldownSeconds > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Next spin in: ${_cooldownSeconds}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                        if (_coinBalance?.spinsRemaining == 0) ...[
                          const SizedBox(height: 8),
                          if (_resetCountdown.isNotEmpty) ...[
                            Text(
                              'Next spin in: $_resetCountdown',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.orange[300] : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (_coinBalance?.dailySpinsResetAt != null) ...[
                            Text(
                              'Next spin at: ${TimezoneUtils.formatISTTime(_coinBalance!.dailySpinsResetAt!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.red[300] : Colors.red,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Come back tomorrow for more spins!',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.red[300] : Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Spin Wheel
                  SpinWheelWidget(
                    size: 300,
                    isSpinning: _isSpinning,
                    targetCoinValue: _lastSpinResult?.coinsWon,
                    onSpinComplete: _onSpinComplete,
                  ),
                  const SizedBox(height: 32),

                  // Spin Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isSpinning ||
                              _cooldownSeconds > 0 ||
                              (_coinBalance?.spinsRemaining ?? 0) == 0)
                          ? null
                          : _performSpin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey[850] : Colors.amber,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        disabledBackgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        disabledForegroundColor: isDark ? Colors.grey[500] : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isSpinning
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _cooldownSeconds > 0
                                  ? 'Wait ${_cooldownSeconds}s'
                                  : (_coinBalance?.spinsRemaining ?? 0) == 0
                                      ? 'No Spins Left'
                                      : 'SPIN NOW',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
