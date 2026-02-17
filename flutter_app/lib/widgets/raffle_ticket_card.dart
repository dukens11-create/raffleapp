import 'package:flutter/material.dart';
import '../models/ticket.dart';
import 'package:intl/intl.dart';

class RaffleTicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showBuyer;

  const RaffleTicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.showStatus = true,
    this.showBuyer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category badge and price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryBadge(),
                  Text(
                    '${NumberFormat.currency(symbol: 'HTG ', decimalDigits: 0).format(ticket.price)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Ticket Number
              Row(
                children: [
                  const Icon(Icons.confirmation_number, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    ticket.ticketNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Status (if enabled)
              if (showStatus) ...[
                const SizedBox(height: 4),
                _buildStatusChip(),
              ],
              
              // Buyer info (if enabled and available)
              if (showBuyer && ticket.buyerName != null) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.buyerName!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (ticket.buyerPhone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        ticket.buyerPhone!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
              
              // Department (if available)
              if (ticket.department != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      ticket.department!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    Color categoryColor;
    switch (ticket.category) {
      case 'ABC':
        categoryColor = Colors.blue;
        break;
      case 'EFG':
        categoryColor = Colors.purple;
        break;
      case 'JKL':
        categoryColor = Colors.orange;
        break;
      case 'XYZ':
        categoryColor = Colors.green;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor, width: 1),
      ),
      child: Text(
        ticket.category,
        style: TextStyle(
          color: categoryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (ticket.status.toUpperCase()) {
      case 'SOLD':
        statusColor = Colors.green;
        statusText = 'Vendu';
        statusIcon = Icons.check_circle;
        break;
      case 'RESERVED':
        statusColor = Colors.orange;
        statusText = 'Réservé';
        statusIcon = Icons.schedule;
        break;
      case 'AVAILABLE':
        statusColor = Colors.blue;
        statusText = 'Disponible';
        statusIcon = Icons.shopping_cart;
        break;
      default:
        statusColor = Colors.grey;
        statusText = ticket.status;
        statusIcon = Icons.info;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
