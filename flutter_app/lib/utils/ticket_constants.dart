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
      category: 'BSC',
      prizes: [
        Prize(emoji: '🏆', text: 'GRATE SEZON!\n5,000 GOUD', value: 5000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n2,000 GOUD', value: 2000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n250 GOUD', value: 250, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n100 GOUD', value: 100, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
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
      subText: '⭐ COSMIC EDITION',
      coverText: 'GRATE TOUTE',
      category: 'PRM',
      prizes: [
        Prize(emoji: '🏆', text: 'MEGA CHANS!\n15,000 GOUD', value: 15000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n4,000 GOUD', value: 4000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n2,000 GOUD', value: 2000, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n200 GOUD', value: 200, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFF7c3aed),
          Color(0xFF6366f1),
          Color(0xFF4f46e5),
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
        Prize(emoji: '🏆', text: 'GRATE SEZON!\n50,000 GOUD', value: 50000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n6,000 GOUD', value: 6000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n3,000 GOUD', value: 3000, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n1,500 GOUD', value: 1500, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n750 GOUD', value: 750, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n300 GOUD', value: 300, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
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
        Prize(emoji: '🏆', text: 'MEGA AJAN!\n150,000 GOUD', value: 150000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n8,000 GOUD', value: 8000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n4,000 GOUD', value: 4000, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n2,000 GOUD', value: 2000, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n600 GOUD', value: 600, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFFcbd5e1),
          Color(0xFF94a3b8),
          Color(0xFF64748b),
        ],
        textColor: Color(0xFF1e293b),
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
      subText: '💰 GOLDEN EDITION',
      coverText: 'GRATE TOUTE',
      category: 'GLD',
      prizes: [
        Prize(emoji: '🏆', text: 'MEGA AJAN!\n250,000 GOUD', value: 250000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n10,000 GOUD', value: 10000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n2,500 GOUD', value: 2500, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n1,500 GOUD', value: 1500, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n800 GOUD', value: 800, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
      ],
      theme: TicketTheme(
        gradientColors: [
          Color(0xFFfbbf24),
          Color(0xFFf59e0b),
          Color(0xFFd97706),
        ],
        textColor: Color(0xFF78350f),
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
      subText: '💎 ULTIMATE EDITION',
      coverText: 'GRATE TOUTE',
      category: 'DMD',
      prizes: [
        Prize(emoji: '🏆', text: 'MEGA AJAN!\n1,000,000 GOUD', value: 1000000, weight: 5),
        Prize(emoji: '💎', text: 'OU GENYEN\n25,000 GOUD', value: 25000, weight: 50),
        Prize(emoji: '✨', text: 'OU GENYEN\n12,500 GOUD', value: 12500, weight: 200),
        Prize(emoji: '🌟', text: 'OU GENYEN\n6,000 GOUD', value: 6000, weight: 200),
        Prize(emoji: '🎲', text: 'OU GENYEN\n3,000 GOUD', value: 3000, weight: 300),
        Prize(emoji: '💰', text: 'OU GENYEN\n1,500 GOUD', value: 1500, weight: 500),
        Prize(emoji: '🎟️', text: 'TIKÈ GRATIS!\nJWE ANKÒ', value: 0, weight: 800),
        Prize(emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 11645),
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
