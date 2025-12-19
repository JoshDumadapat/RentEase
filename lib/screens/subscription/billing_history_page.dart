import 'package:flutter/material.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

/// Billing History Page
/// 
/// Displays user's billing history with mock data
class BillingHistoryPage extends StatefulWidget {
  const BillingHistoryPage({super.key});

  @override
  State<BillingHistoryPage> createState() => _BillingHistoryPageState();
}

class _BillingHistoryPageState extends State<BillingHistoryPage> {
  // Mock billing history data
  final List<Map<String, dynamic>> _billingHistory = [
    {
      'id': '1',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'completed',
      'paymentMethod': 'BPI Bank Transfer',
      'transactionId': 'TXN-2024-001234',
    },
    {
      'id': '2',
      'date': DateTime.now().subtract(const Duration(days: 35)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'completed',
      'paymentMethod': 'BPI Bank Transfer',
      'transactionId': 'TXN-2024-001189',
    },
    {
      'id': '3',
      'date': DateTime.now().subtract(const Duration(days: 65)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'completed',
      'paymentMethod': 'BDO Bank Transfer',
      'transactionId': 'TXN-2024-001045',
    },
    {
      'id': '4',
      'date': DateTime.now().subtract(const Duration(days: 95)),
      'plan': 'Quarterly',
      'amount': 549.0,
      'status': 'completed',
      'paymentMethod': 'Visa/Mastercard',
      'transactionId': 'TXN-2024-000892',
    },
    {
      'id': '5',
      'date': DateTime.now().subtract(const Duration(days: 185)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'completed',
      'paymentMethod': 'BPI Bank Transfer',
      'transactionId': 'TXN-2024-000678',
    },
    {
      'id': '6',
      'date': DateTime.now().subtract(const Duration(days: 215)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'completed',
      'paymentMethod': 'BDO Bank Transfer',
      'transactionId': 'TXN-2024-000534',
    },
    {
      'id': '7',
      'date': DateTime.now().subtract(const Duration(days: 245)),
      'plan': 'Yearly',
      'amount': 1999.0,
      'status': 'completed',
      'paymentMethod': 'Visa/Mastercard',
      'transactionId': 'TXN-2024-000412',
    },
    {
      'id': '8',
      'date': DateTime.now().subtract(const Duration(days: 275)),
      'plan': 'Monthly',
      'amount': 199.0,
      'status': 'failed',
      'paymentMethod': 'BPI Bank Transfer',
      'transactionId': 'TXN-2024-000298',
    },
  ];

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Billing History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _billingHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: subtextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No billing history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your billing history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _billingHistory.length,
              itemBuilder: (context, index) {
                final billing = _billingHistory[index];
                final date = billing['date'] as DateTime;
                final plan = billing['plan'] as String;
                final amount = billing['amount'] as double;
                final status = billing['status'] as String;
                final paymentMethod = billing['paymentMethod'] as String;
                final transactionId = billing['transactionId'] as String;
                final statusColor = _getStatusColor(status, isDark);
                final statusIcon = _getStatusIcon(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showBillingDetails(context, billing, isDark, textColor, subtextColor!);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(date),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _themeColorDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 16,
                                  color: subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    paymentMethod,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: subtextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showBillingDetails(
    BuildContext context,
    Map<String, dynamic> billing,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final date = billing['date'] as DateTime;
    final plan = billing['plan'] as String;
    final amount = billing['amount'] as double;
    final status = billing['status'] as String;
    final paymentMethod = billing['paymentMethod'] as String;
    final transactionId = billing['transactionId'] as String;
    final statusColor = _getStatusColor(status, isDark);
    final statusIcon = _getStatusIcon(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              label: 'Plan',
              value: plan,
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Amount',
              value: '₱${amount.toStringAsFixed(2)}',
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              valueColor: _themeColorDark,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Date',
              value: _formatDate(date),
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Time',
              value: _formatTime(date),
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Payment Method',
              value: paymentMethod,
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Transaction ID',
              value: transactionId,
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                  ),
                ),
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColorDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? textColor,
          ),
        ),
      ],
    );
  }
}
