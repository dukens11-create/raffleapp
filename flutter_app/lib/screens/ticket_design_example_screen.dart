import 'package:flutter/material.dart';
import '../models/ticket_category.dart';
import '../widgets/ticket_design_card.dart';

/// Example screen demonstrating the ticket design system
/// This shows how to use the TicketDesignCard widget for all 6 tiers
class TicketDesignExampleScreen extends StatefulWidget {
  const TicketDesignExampleScreen({Key? key}) : super(key: key);

  @override
  State<TicketDesignExampleScreen> createState() => _TicketDesignExampleScreenState();
}

class _TicketDesignExampleScreenState extends State<TicketDesignExampleScreen> {
  TicketTier? selectedTier;
  bool showWithTicketNumber = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Design Gallery'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Show ticket numbers: '),
                Switch(
                  value: showWithTicketNumber,
                  onChanged: (value) {
                    setState(() {
                      showWithTicketNumber = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Gallery
          Expanded(
            child: selectedTier == null
                ? _buildAllTicketsView()
                : _buildSingleTicketView(selectedTier!),
          ),
        ],
      ),
    );
  }

  /// Display all ticket tiers in a scrollable grid
  Widget _buildAllTicketsView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: TicketTier.values.length,
      itemBuilder: (context, index) {
        final tier = TicketTier.values[index];
        return TicketDesignCard(
          tier: tier,
          ticketNumber: showWithTicketNumber ? tier.generateSampleCode(index + 1) : null,
          isPreview: !showWithTicketNumber,
          onTap: () {
            setState(() {
              selectedTier = tier;
            });
          },
        );
      },
    );
  }

  /// Display a single ticket tier with specifications
  Widget _buildSingleTicketView(TicketTier tier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedTier = null;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Gallery'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Large ticket preview
          TicketDesignCard(
            tier: tier,
            ticketNumber: showWithTicketNumber ? tier.generateSampleCode(123456) : null,
            isPreview: !showWithTicketNumber,
            width: 400,
          ),
          
          const SizedBox(height: 24),
          
          // Specifications
          TicketSpecificationCard(tier: tier),
          
          const SizedBox(height: 24),
          
          // Sample ticket numbers
          _buildSampleNumbers(tier),
        ],
      ),
    );
  }

  Widget _buildSampleNumbers(TicketTier tier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Ticket Numbers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              final number = (index + 1) * 10000;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tier.backgroundColor.withOpacity(0.1),
                    border: Border.all(color: tier.backgroundColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tier.generateSampleCode(number),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Simple usage example showing how to create a single ticket
class SimpleTicketExample extends StatelessWidget {
  const SimpleTicketExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Ticket Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Example 1: Preview mode (no ticket number)
              const Text(
                'Preview Mode:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TicketDesignCard(
                tier: TicketTier.gold,
                isPreview: true,
              ),
              
              const SizedBox(height: 40),
              
              // Example 2: With ticket number
              const Text(
                'With Ticket Number:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TicketDesignCard(
                tier: TicketTier.diamond,
                ticketNumber: 'DMD-12345',
                isPreview: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example showing all tiers side by side
class ComparisonExample extends StatelessWidget {
  const ComparisonExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Comparison')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: TicketTier.values.length,
        itemBuilder: (context, index) {
          final tier = TicketTier.values[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                TicketDesignCard(
                  tier: tier,
                  ticketNumber: tier.generateSampleCode(index + 1),
                  isPreview: false,
                ),
                const SizedBox(height: 8),
                Text(
                  '${tier.name} - ${tier.price.toStringAsFixed(0)} HTG',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
