import 'package:flutter/material.dart';
import '../models/scratch/scratch_ticket.dart';

class TicketCard extends StatelessWidget {
  final ScratchTicket ticket;
  final VoidCallback onTap;
  final bool compact;

  const TicketCard({
    Key? key,
    required this.ticket,
    required this.onTap,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double headerPadding = compact ? 8.0 : 16.0;
    final double typeNameFontSize = compact ? 13.0 : 20.0;
    final double headerSpacing = compact ? 2.0 : 4.0;
    final double nameFontSize = compact ? 10.0 : 14.0;
    final double bodyPadding = compact ? 8.0 : 12.0;
    final double iconSize = compact ? 24.0 : 40.0;
    final double afterIconSpacing = compact ? 4.0 : 8.0;
    final double prizeRangeFontSize = compact ? 10.0 : 18.0;
    final double beforeBadgeSpacing = compact ? 4.0 : 12.0;
    final double badgeHPadding = compact ? 6.0 : 16.0;
    final double badgeVPadding = compact ? 4.0 : 8.0;
    final double badgeFontSize = compact ? 11.0 : 16.0;
    final double footerPadding = compact ? 8.0 : 12.0;
    final double footerIconSize = compact ? 14.0 : 18.0;
    final double footerSpacing = compact ? 4.0 : 8.0;
    final double footerFontSize = compact ? 10.0 : 14.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ticket Header with Gradient
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ticket.theme.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    ticket.typeName,
                    style: TextStyle(
                      fontSize: typeNameFontSize,
                      fontWeight: FontWeight.bold,
                      color: ticket.theme.textColor,
                    ),
                  ),
                  SizedBox(height: headerSpacing),
                  Text(
                    ticket.name,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      color: ticket.theme.textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Ticket Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(bodyPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Prize Range
                    Icon(Icons.emoji_events, size: iconSize, color: Colors.amber),
                    SizedBox(height: afterIconSpacing),
                    if (!compact) ...[
                      Text(
                        'Win up to',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      ticket.prizeRange,
                      style: TextStyle(
                        fontSize: prizeRangeFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: compact ? 1 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                    ),
                    SizedBox(height: beforeBadgeSpacing),

                    // Price
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: badgeHPadding,
                        vertical: badgeVPadding,
                      ),
                      decoration: BoxDecoration(
                        color: ticket.theme.gradientColors.first,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ticket.price} HTG',
                        style: TextStyle(
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Button
            Container(
              padding: EdgeInsets.all(footerPadding),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: footerIconSize, color: Colors.black54),
                  SizedBox(width: footerSpacing),
                  Text(
                    'Tap to scratch',
                    style: TextStyle(
                      fontSize: footerFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
