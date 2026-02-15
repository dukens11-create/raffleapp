import 'package:flutter/material.dart';
import '../models/scratch/scratch_ticket.dart';
import '../models/scratch/prize.dart';
import '../models/scratch/ticket_theme.dart';

class TicketConstants {
  static final List<ScratchTicket> allTickets = [
    // Basic Ticket - Green Sparkle Theme
    ScratchTicket(
      id: 'basic',
      name: 'GRATE GENYEN',
      typeName: 'Basic',
      className: 'ticket-basic',
      price: 50,
      prizeRange: '5,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'BAS',
      prizes: [
        Prize(emoji: '🎉', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 1),
        Prize(emoji: '💎', text: 'OU GENYEN\n2,500 GOUD', value: 2500, weight: 3),
        Prize(emoji: '🔥', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 10),
        Prize(emoji: '💰', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 25),
        Prize(emoji: '🎁', text: 'OU GENYEN\n100 GOUD', value: 100, weight: 60),
        Prize(emoji: '✨', text: 'OU GENYEN\n5 GOUD', value: 5, weight: 100),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 201),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFF10b981),
          Color(0xFF059669),
          Color(0xFF047857),
        ],
        textColor: Colors.white,
        animation: 'sparkle',
      ),
    ),

    // Premium Ticket - Purple Cosmic Theme
    ScratchTicket(
      id: 'premium',
      name: 'GRATE GENYEN',
      typeName: 'Premium',
      className: 'ticket-premium',
      price: 100,
      prizeRange: '15,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'PRM',
      prizes: [
        Prize(emoji: '🎰', text: 'MEGA PRIZE!\n15,000 GOUD', value: 15000, weight: 2),
        Prize(emoji: '💎', text: 'OU GENYEN\n7,500 GOUD', value: 7500, weight: 5),
        Prize(emoji: '🔥', text: 'OU GENYEN\n3,000 GOUD', value: 3000, weight: 15),
        Prize(emoji: '💰', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 35),
        Prize(emoji: '🎁', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 70),
        Prize(emoji: '✨', text: 'OU GENYEN\n50 GOUD', value: 50, weight: 120),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 153),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFF7c3aed),
          Color(0xFF6366f1),
          Color(0xFF8b5cf6),
        ],
        textColor: Colors.white,
        animation: 'cosmic',
      ),
    ),

    // Bronze Ticket - Bronze/Orange Gradient
    ScratchTicket(
      id: 'bronze',
      name: 'GRATE GENYEN',
      typeName: 'Bronze',
      className: 'ticket-bronze',
      price: 250,
      prizeRange: '50,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'BRZ',
      prizes: [
        Prize(emoji: '🎉', text: 'OU GENYEN\n50,000 GOUD', value: 50000, weight: 1),
        Prize(emoji: '💎', text: 'OU GENYEN\n25,000 GOUD', value: 25000, weight: 3),
        Prize(emoji: '🔥', text: 'OU GENYEN\n10,000 GOUD', value: 10000, weight: 10),
        Prize(emoji: '💰', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 25),
        Prize(emoji: '🎁', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 60),
        Prize(emoji: '✨', text: 'OU GENYEN\n250 GOUD', value: 250, weight: 100),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 201),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFFea580c),
          Color(0xFFdc2626),
          Color(0xFFc2410c),
        ],
        textColor: Colors.white,
        animation: 'sparkle',
      ),
    ),

    // Silver Ticket - Metallic Silver/Gray Holographic
    ScratchTicket(
      id: 'silver',
      name: 'GRATE GENYEN',
      typeName: 'Silver',
      className: 'ticket-silver',
      price: 500,
      prizeRange: '150,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'SLV',
      prizes: [
        Prize(emoji: '🏆', text: 'MEGA AJAN!\n150,000 GOUD', value: 150000, weight: 1),
        Prize(emoji: '💎', text: 'OU GENYEN\n75,000 GOUD', value: 75000, weight: 3),
        Prize(emoji: '🔥', text: 'OU GENYEN\n25,000 GOUD', value: 25000, weight: 10),
        Prize(emoji: '⭐', text: 'OU GENYEN\n10,000 GOUD', value: 10000, weight: 25),
        Prize(emoji: '💰', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 60),
        Prize(emoji: '✨', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 100),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 201),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFFcbd5e1),
          Color(0xFF94a3b8),
          Color(0xFF64748b),
        ],
        textColor: Colors.white,
        animation: 'holographic',
      ),
    ),

    // Gold Ticket - Golden Sunburst
    ScratchTicket(
      id: 'gold',
      name: 'GRATE GENYEN',
      typeName: 'Gold',
      className: 'ticket-gold',
      price: 1000,
      prizeRange: '250,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'GLD',
      prizes: [
        Prize(emoji: '🎉', text: 'OU GENYEN\n250,000 GOUD', value: 250000, weight: 1),
        Prize(emoji: '💎', text: 'OU GENYEN\n100,000 GOUD', value: 100000, weight: 3),
        Prize(emoji: '🔥', text: 'OU GENYEN\n50,000 GOUD', value: 50000, weight: 8),
        Prize(emoji: '💰', text: 'OU GENYEN\n10,000 GOUD', value: 10000, weight: 20),
        Prize(emoji: '🎁', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 40),
        Prize(emoji: '✨', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 80),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 148),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFFfbbf24),
          Color(0xFFf59e0b),
          Color(0xFFd97706),
        ],
        textColor: Colors.white,
        animation: 'sunburst',
      ),
    ),

    // Diamond Ticket - Blue Icy Diamonds
    ScratchTicket(
      id: 'diamond',
      name: 'GRATE GENYEN',
      typeName: 'Diamond',
      className: 'ticket-diamond',
      price: 5000,
      prizeRange: '1,000,000 GOURDES!',
      coverText: 'GRATE TOUTE',
      category: 'DIA',
      prizes: [
        Prize(emoji: '💎', text: 'MEGA DYAMAN!\n1,000,000 GOUD', value: 1000000, weight: 1),
        Prize(emoji: '🎰', text: 'SUPER PRIZE!\n500,000 GOUD', value: 500000, weight: 2),
        Prize(emoji: '🔥', text: 'OU GENYEN\n250,000 GOUD', value: 250000, weight: 3),
        Prize(emoji: '⭐', text: 'OU GENYEN\n100,000 GOUD', value: 100000, weight: 8),
        Prize(emoji: '💰', text: 'OU GENYEN\n50,000 GOUD', value: 50000, weight: 20),
        Prize(emoji: '🎁', text: 'OU GENYEN\n10,000 GOUD', value: 10000, weight: 60),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 206),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFF22d3ee),
          Color(0xFF06b6d4),
          Color(0xFF0891b2),
        ],
        textColor: Colors.white,
        animation: 'diamond',
      ),
    ),
  ];

  static ScratchTicket? getTicketById(String id) {
    try {
      return allTickets.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      return null;
    }
  }
}
