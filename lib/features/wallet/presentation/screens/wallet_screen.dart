import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/wallet_transaction.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      color: AppColors.primaryGreen.withOpacity(0.3),
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
              const SizedBox(height: 32),
              
              // Transaction History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: AppTextStyles.h4(
                      color: isDark ? AppColors.lightText : AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Transactions List
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: AppColors.greyText.withOpacity(0.5),
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _TransactionTile(transaction: transaction);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error loading transactions',
                      style: AppTextStyles.bodyMedium(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Banner Ad
              const BannerAdWidget(),
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
      onTap: () {
        if (transaction.taskId != null) {
          // Navigate to task
          // We need context to access GoRouter or Navigator
          // Since we are inside a StatelessWidget, context is available
          context.push('/tasks/${transaction.taskId}');
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
                color: color.withOpacity(0.1),
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
                      color: AppColors.warning.withOpacity(0.1),
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
