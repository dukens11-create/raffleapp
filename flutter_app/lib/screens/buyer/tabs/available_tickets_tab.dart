import 'package:flutter/material.dart';
import '../../../services/buyer_api_service.dart';
import '../../../models/buyer/available_ticket.dart';
import '../../../widgets/buyer/loading_spinner.dart';
import '../../../widgets/buyer/empty_state.dart';
import '../../../widgets/buyer/status_badge.dart';
import '../../../utils/error_helper.dart';

class AvailableTicketsTab extends StatefulWidget {
  const AvailableTicketsTab({super.key});

  @override
  State<AvailableTicketsTab> createState() => _AvailableTicketsTabState();
}

class _AvailableTicketsTabState extends State<AvailableTicketsTab> {
  final BuyerApiService _apiService = BuyerApiService();
  List<AvailableTicket> _tickets = [];
  List<AvailableTicket> _displayedTickets = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  int _currentPage = 0;
  final int _itemsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAvailableTickets(
        category: _selectedCategory,
      );
      setState(() {
        _tickets = response.getAllTickets();
        _currentPage = 0;
        _updateDisplayedTickets();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedTickets() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    setState(() {
      _displayedTickets = _tickets.sublist(
        startIndex,
        endIndex > _tickets.length ? _tickets.length : endIndex,
      );
    });
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _tickets.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedTickets();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateDisplayedTickets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...['XYZ', 'EFG', 'ABC'].map(
                  (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
                _loadTickets();
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _loadTickets,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingSpinner(message: 'Loading available tickets...');
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Tickets',
        message: ErrorHelper.formatErrorMessage(_error!),
        onRetry: _loadTickets,
      );
    }

    if (_tickets.isEmpty) {
      return const EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'No Available Tickets',
        message: 'There are no tickets available at the moment.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTickets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _displayedTickets.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(_displayedTickets[index]);
              },
            ),
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildTicketCard(AvailableTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.confirmation_number,
                color: Color(0xFF667eea),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.ticketNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ticket.category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748b),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${ticket.price} HTG',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            StatusBadge(status: ticket.status, small: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_tickets.length / _itemsPerPage).ceil();
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          TextButton.icon(
            onPressed: (_currentPage + 1) * _itemsPerPage < _tickets.length
                ? _nextPage
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}
