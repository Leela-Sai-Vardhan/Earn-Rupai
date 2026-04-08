import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/wallet_transaction.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import 'package:intl/intl.dart';
import '../../../../shared/services/admob_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../spin_win/data/services/coin_service.dart';
import '../../../spin_win/data/models/coin_transaction_model.dart';
import '../../../../shared/utils/timezone_utils.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalEarningsAsync = ref.watch(totalEarningsProvider);
    final pendingEarningsAsync = ref.watch(pendingEarningsProvider);
    final availableBalanceAsync = ref.watch(availableBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(totalEarningsProvider);
              ref.invalidate(pendingEarningsProvider);
              ref.invalidate(availableBalanceProvider);
              ref.invalidate(transactionsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalEarningsProvider);
          ref.invalidate(pendingEarningsProvider);
          ref.invalidate(availableBalanceProvider);
          ref.invalidate(transactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: AppTextStyles.bodyMedium(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    availableBalanceAsync.when(
                      data: (balance) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.white, size: 40),
                          Text(
                            balance.toStringAsFixed(2),
                            style: AppTextStyles.h1(color: Colors.white),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(color: Colors.white),
                      error: (_, __) => const Text('--', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats Row
              Row(
                children: [
                  // Total Earnings
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Earned',
                            style: AppTextStyles.caption(color: AppColors.greyText),
                          ),
                          const SizedBox(height: 8),
                          totalEarningsAsync.when(
                            data: (total) => Row(
                              children: [
                                const Icon(Icons.currency_rupee, size: 20, color: AppColors.success),
                                Text(
                                  total.toStringAsFixed(2),
                                  style: AppTextStyles.h4(color: AppColors.success),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pending
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending',
                            style: AppTextStyles.caption(color: AppColors.greyText),
                          ),
                          const SizedBox(height: 8),
                          pendingEarningsAsync.when(
                            data: (pending) => Row(
                              children: [
                                const Icon(Icons.currency_rupee, size: 20, color: AppColors.warning),
                                Text(
                                  pending.toStringAsFixed(2),
                                  style: AppTextStyles.h4(color: AppColors.warning),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Banner Ad
              const BannerAdWidget(),
              const SizedBox(height: 16),
              
              // TabBar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.greyText,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: const [
                    Tab(text: 'Tasks History'),
                    Tab(text: 'Coins History'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // TabBarView
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tasks History Tab
                    _TasksHistoryTab(transactionsAsync: transactionsAsync, isDark: isDark),
                    // Coins History Tab
                    _CoinsHistoryTab(isDark: isDark),
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

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = transaction.isCredit;
    final color = transaction.isPending
        ? AppColors.warning
        : isCredit
            ? AppColors.success
            : AppColors.error;

    return InkWell(
      onTap: () async {
        if (transaction.taskId != null) {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('View Task Details?'),
              content: const Text('Watch a quick ad to view task details.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;

          // Show blocking overlay
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.white,
            builder: (context) => const SizedBox.expand(),
          );

          // Show rewarded ad
          AdMobService.showRewardedAd(
            onUserEarnedReward: () {
              Navigator.pop(context); // Close blocking overlay
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: transaction.taskId!),
                ),
              );
            },
            onAdFailedToLoad: () {
              Navigator.pop(context); // Close blocking overlay
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ad not available. Proceeding to task details...'),
                  backgroundColor: Colors.blue,
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: transaction.taskId!),
                ),
              );
            },
            onAdDismissed: (bool earnedReward) {
              if (!earnedReward) {
                Navigator.pop(context); // Close blocking overlay
              }
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.notes ?? 'Transaction',
                    style: AppTextStyles.bodyMedium(
                      color: isDark ? AppColors.lightText : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
                    style: AppTextStyles.caption(color: AppColors.greyText),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      isCredit ? '+' : '-',
                      style: AppTextStyles.h4(color: color),
                    ),
                    const Icon(Icons.currency_rupee, size: 16, color: AppColors.greyText),
                    Text(
                      transaction.amount.toStringAsFixed(2),
                      style: AppTextStyles.h4(color: color),
                    ),
                  ],
                ),
                if (transaction.isPending)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Pending',
                      style: AppTextStyles.caption(color: AppColors.warning),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tasks History Tab Widget
class _TasksHistoryTab extends ConsumerWidget {
  final AsyncValue transactionsAsync;
  final bool isDark;

  const _TasksHistoryTab({
    required this.transactionsAsync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.greyText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete tasks to start earning!',
                    style: AppTextStyles.caption(color: AppColors.greyText),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _TransactionTile(transaction: transaction);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading transactions',
          style: AppTextStyles.bodyMedium(color: AppColors.error),
        ),
      ),
    );
  }
}

// Coins History Tab Widget
class _CoinsHistoryTab extends ConsumerStatefulWidget {
  final bool isDark;

  const _CoinsHistoryTab({required this.isDark});

  @override
  ConsumerState<_CoinsHistoryTab> createState() => _CoinsHistoryTabState();
}

class _CoinsHistoryTabState extends ConsumerState<_CoinsHistoryTab> {
  List<CoinTransactionModel>? _coinTransactions;
  double _coinBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoinData();
  }

  Future<void> _loadCoinData() async {
    try {
      final balance = await CoinService.getCoinBalance();
      final transactions = await CoinService.getCoinTransactions();
      setState(() {
        _coinBalance = balance.coinsBalance;
        _coinTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showWithdrawalDialog() {
    final controller = TextEditingController();
    double? enteredAmount;
    String? validationMessage;
    bool isValid = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateAmount(String value) {
            setDialogState(() {
              enteredAmount = double.tryParse(value);
              
              if (value.isEmpty) {
                validationMessage = null;
                isValid = false;
              } else if (enteredAmount == null) {
                validationMessage = '⚠️ Please enter a valid number';
                isValid = false;
              } else if (enteredAmount! < 25) {
                validationMessage = '⚠️ Minimum withdrawal is 25 coins';
                isValid = false;
              } else if (enteredAmount! > _coinBalance) {
                validationMessage = '⚠️ Insufficient balance (Available: ${_coinBalance.toStringAsFixed(1)} coins)';
                isValid = false;
              } else {
                validationMessage = '✓ Valid amount (₹${CoinService.coinsToRupees(enteredAmount!).toStringAsFixed(1)})';
                isValid = true;
              }
            });
          }

          return AlertDialog(
            title: const Text('Withdraw Coins'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available: ${_coinBalance.toStringAsFixed(1)} coins (₹${CoinService.coinsToRupees(_coinBalance).toStringAsFixed(1)})',
                  style: AppTextStyles.bodyMedium(color: AppColors.greyText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (coins)',
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: validateAmount,
                ),
                const SizedBox(height: 8),
                if (validationMessage != null)
                  Text(
                    validationMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (validationMessage == null)
                  Text(
                    'Minimum withdrawal: 25 coins (₹25)',
                    style: AppTextStyles.caption(color: AppColors.greyText),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isValid
                    ? () {
                        Navigator.pop(context);
                        _showUpiConfirmationDialog(enteredAmount!);
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUpiConfirmationDialog(double amount) async {
    // Fetch user UPI ID
    String? upiId;
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final profile = await SupabaseService.client
          .from('user_profiles')
          .select('upi_id')
          .eq('user_id', userId)
          .single();

      upiId = profile['upi_id'] as String?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching UPI: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (upiId == null || upiId.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('UPI ID Required'),
            content: const Text(
              'Please add your UPI ID in your profile before requesting a withdrawal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${amount.toStringAsFixed(1)} coins (₹${CoinService.coinsToRupees(amount).toStringAsFixed(1)})',
                style: AppTextStyles.bodyLarge(),
              ),
              const SizedBox(height: 12),
              Text(
                'UPI ID: $upiId',
                style: AppTextStyles.bodyMedium(color: AppColors.greyText),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your withdrawal will be pending until approved by admin.',
                        style: AppTextStyles.caption(color: Colors.orange[900]!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processWithdrawal(amount);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processWithdrawal(double amount) async {
    try {
      final result = await CoinService.requestWithdrawal(amount);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal request submitted! Status: Pending'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCoinData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Withdrawal failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Coin Balance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade700, Colors.amber.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coin Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🪙 ${_coinBalance.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '≈ ₹${CoinService.coinsToRupees(_coinBalance).toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _showWithdrawalDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Withdraw'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transactions List
        Expanded(
          child: _coinTransactions == null || _coinTransactions!.isEmpty
              ? Center(
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 64,
                        color: widget.isDark ? Colors.grey[600] : AppColors.greyText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No coin transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.isDark ? Colors.grey[400] : AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Spin the wheel to earn coins!',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDark ? Colors.grey[500] : AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _coinTransactions!.length,
                  itemBuilder: (context, index) {
                    final transaction = _coinTransactions![index];
                    return _CoinTransactionTile(transaction: transaction);
                  },
                ),
        ),
      ],
    );
  }
}

// Coin Transaction Tile Widget
class _CoinTransactionTile extends StatelessWidget {
  final CoinTransactionModel transaction;

  const _CoinTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWithdrawal = transaction.transactionType == 'withdrawal';
    final color = isWithdrawal ? AppColors.error : AppColors.success;

    String statusText = '';
    Color? statusColor;
    if (transaction.status == 'pending') {
      statusText = 'Pending';
      statusColor = AppColors.warning;
    } else if (transaction.status == 'rewarded') {
      statusText = 'Completed';
      statusColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWithdrawal ? Icons.arrow_upward : Icons.casino,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWithdrawal ? 'Withdrawal' : 'Spin Earn',
                  style: AppTextStyles.bodyLarge(),
                ),
                const SizedBox(height: 4),
                Text(
                  TimezoneUtils.formatTransactionTime(transaction.createdAt),
                  style: AppTextStyles.caption(color: AppColors.greyText),
                ),
                if (statusText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.caption(color: statusColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isWithdrawal ? '-' : '+'}${transaction.amount.abs().toStringAsFixed(1)} 🪙',
                style: AppTextStyles.h4(color: color),
              ),
              Text(
                '₹${CoinService.coinsToRupees(transaction.amount.abs()).toStringAsFixed(0)}',
                style: AppTextStyles.caption(color: AppColors.greyText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
