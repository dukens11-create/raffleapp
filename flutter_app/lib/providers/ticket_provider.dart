import 'package:flutter/material.dart';
import '../models/scratch/scratch_ticket.dart';
import '../models/scratch/prize.dart';
import '../utils/ticket_constants.dart';

class TicketProvider with ChangeNotifier {
  List<ScratchTicket> _tickets = [];
  bool _isLoading = false;
  Map<String, Prize> _scratchedTickets = {};

  List<ScratchTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  Map<String, Prize> get scratchedTickets => _scratchedTickets;

  TicketProvider() {
    loadTickets();
  }

  void loadTickets() {
    _isLoading = true;
    notifyListeners();

    // Load tickets from constants
    _tickets = TicketConstants.allTickets;

    _isLoading = false;
    notifyListeners();
  }

  Prize scratchTicket(String ticketId) {
    final ticket = _tickets.firstWhere((t) => t.id == ticketId);
    final prize = ticket.selectPrize();
    
    // Store the scratched ticket result
    _scratchedTickets[ticketId] = prize;
    notifyListeners();
    
    return prize;
  }

  Prize? getScratchedPrize(String ticketId) {
    return _scratchedTickets[ticketId];
  }

  void clearScratchedTickets() {
    _scratchedTickets.clear();
    notifyListeners();
  }
}
