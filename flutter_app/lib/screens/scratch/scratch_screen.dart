import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scratch/scratch_ticket.dart';
import '../../models/scratch/prize.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/scratch_card_widget.dart';

class ScratchScreen extends StatefulWidget {
  final ScratchTicket ticket;

  const ScratchScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<ScratchScreen> createState() => _ScratchScreenState();
}

class _ScratchScreenState extends State<ScratchScreen> {
  late Prize selectedPrize;
  bool hasScratched = false;

  @override
  void initState() {
    super.initState();
    // Select a prize when the screen is initialized
    final provider = Provider.of<TicketProvider>(context, listen: false);
    selectedPrize = provider.scratchTicket(widget.ticket.id);
  }

  void _onScratchComplete() {
    setState(() {
      hasScratched = true;
    });

    // Show result dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      _showResultDialog();
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isWinner = selectedPrize.value > 0;
        final isFreeTicket = selectedPrize.emoji == '🎟️';
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedPrize.emoji,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                isFreeTicket ? 'Félicitasyon!' : isWinner ? 'Félicitasyon!' : 'Eseye Ankò!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                selectedPrize.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isWinner) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.ticket.theme.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ou genyen: ${selectedPrize.value} HTG',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              if (isFreeTicket) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.ticket.theme.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ou genyen yon lòt tikè!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ScratchScreen(ticket: widget.ticket),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(isFreeTicket ? 'Use Free Ticket' : 'Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.ticket.theme.gradientColors.first,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ticket.typeName} Ticket'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.ticket.theme.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.ticket.theme.gradientColors.first.withOpacity(0.3),
              widget.ticket.theme.gradientColors.last.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Instructions
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scratch the ticket below to reveal your prize!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scratch Card
            Expanded(
              child: ScratchCardWidget(
                ticket: widget.ticket,
                selectedPrize: selectedPrize,
                onComplete: _onScratchComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
