import 'package:flutter/material.dart';
import '../../../services/buyer_api_service.dart';
import '../../../models/buyer/raffle_info.dart';
import '../../../widgets/buyer/loading_spinner.dart';
import '../../../widgets/buyer/empty_state.dart';
import '../../../widgets/buyer/ticket_badge.dart';
import '../../../utils/error_helper.dart';

class RaffleInfoTab extends StatefulWidget {
  final Function(int) onTabChange;

  const RaffleInfoTab({
    super.key,
    required this.onTabChange,
  });

  @override
  State<RaffleInfoTab> createState() => _RaffleInfoTabState();
}

class _RaffleInfoTabState extends State<RaffleInfoTab> {
  final BuyerApiService _apiService = BuyerApiService();
  RaffleInfo? _raffleInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRaffleInfo();
  }

  Future<void> _loadRaffleInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await _apiService.getRaffleInfo();
      setState(() {
        _raffleInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSpinner(message: 'Loading raffle information...');
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Raffle Info',
        message: ErrorHelper.formatErrorMessage(_error!),
        onRetry: _loadRaffleInfo,
      );
    }

    if (_raffleInfo == null) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Raffle Information',
        message: 'No active raffle found.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRaffleInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRaffleHeader(),
            const SizedBox(height: 24),
            _buildTicketTypesSection(),
            const SizedBox(height: 24),
            _buildOnlinePurchaseSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRaffleHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.celebration,
                  color: Color(0xFF667eea),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _raffleInfo!.raffleName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_raffleInfo!.drawDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748b)),
                  const SizedBox(width: 8),
                  Text(
                    'Draw Date: ${_raffleInfo!.drawDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748b)),
                const SizedBox(width: 8),
                Text(
                  'Status: ${_raffleInfo!.status}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            if (_raffleInfo!.description != null) ...[
              const SizedBox(height: 12),
              Text(
                _raffleInfo!.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎟️ TICKET TYPES & PRIZES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF667eea).withOpacity(0.1),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Ticket Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Max Prize',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _raffleInfo!.ticketTypes.map((ticketType) {
                  return DataRow(
                    cells: [
                      DataCell(TicketBadge(type: ticketType.type)),
                      DataCell(Text('${ticketType.price} HTG')),
                      DataCell(
                        Text(
                          '${ticketType.maxPrize} HTG',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                      DataCell(Text(ticketType.category)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlinePurchaseSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💳 Online Purchase',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Online ticket purchases available',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onTabChange(2), // Switch to Purchase tab
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Buy Tickets Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ticket Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _raffleInfo!.statistics.totalTickets.toString(),
                  Icons.confirmation_number,
                  const Color(0xFF3b82f6),
                ),
                _buildStatItem(
                  'Available',
                  _raffleInfo!.statistics.availableTickets.toString(),
                  Icons.check_circle,
                  const Color(0xFF10b981),
                ),
                _buildStatItem(
                  'Sold',
                  _raffleInfo!.statistics.soldTickets.toString(),
                  Icons.sell,
                  const Color(0xFFef4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748b),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (_raffleInfo!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 16),
            ..._raffleInfo!.categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${category.price} HTG',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: category.available > 0
                                ? const Color(0xFF10b981).withOpacity(0.15)
                                : const Color(0xFFef4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${category.available} available',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: category.available > 0
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFdc2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
