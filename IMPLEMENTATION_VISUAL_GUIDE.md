# Flutter Buyer Portal - Visual Implementation Guide

## Tab Navigation Structure

```
┌─────────────────────────────────────────────────────────────┐
│  Buyer Portal                                     [≡ Menu]   │
├─────────────────────────────────────────────────────────────┤
│  📋 Raffle Info | 🎫 Available | 💳 Purchase | 👤 My | ✅ Verify │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [Current Tab Content]                                       │
│                                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Tab 1: Raffle Info

```
┌──────────────────────────────────────────┐
│ 🎉 Current Raffle Name                   │
│ 📅 Draw Date: 2024-XX-XX                 │
│ ℹ️  Status: Active                       │
│ Description text here...                 │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ 🎟️ TICKET TYPES & PRIZES                │
│                                          │
│ ┌──────┬───────┬────────┬─────────┐    │
│ │ Type │ Price │ Prize  │ Category│    │
│ ├──────┼───────┼────────┼─────────┤    │
│ │[BASIC]│ 50HTG │5,000HTG│ XYZ 1/2│    │
│ │[PREM] │100HTG │15,000  │ EFG    │    │
│ │[BRNZ] │250HTG │50,000  │ EFG F½ │    │
│ │[SLVR] │500HTG │150,000 │ ABC F½ │    │
│ │[GOLD] │1,000  │250,000 │ ABC B½ │    │
│ │[DMND] │5,000  │1,000,000│EFG B½ │    │
│ └──────┴───────┴────────┴─────────┘    │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ 💳 Online Purchase                       │
│ ✅ Online ticket purchases available     │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │   🛒 Buy Tickets Now                │  │
│ └────────────────────────────────────┘  │
│                                          │
│ Statistics:                              │
│ 📊 Total: 100,000                        │
│ ✅ Available: 75,000                     │
│ ❌ Sold: 25,000                          │
└──────────────────────────────────────────┘
```

## Tab 2: Available Tickets

```
┌──────────────────────────────────────────┐
│ Filter: [All Categories ▼]  [🔄 Refresh]│
├──────────────────────────────────────────┤
│ 🎫 Ticket #123456                        │
│    Category: XYZ | 50 HTG  [Available]  │
├──────────────────────────────────────────┤
│ 🎫 Ticket #123457                        │
│    Category: EFG | 100 HTG [Available]  │
├──────────────────────────────────────────┤
│ 🎫 Ticket #123458                        │
│    Category: ABC | 500 HTG [Available]  │
├──────────────────────────────────────────┤
│ [◀ Previous]  Page 1 of 20  [Next ▶]    │
└──────────────────────────────────────────┘
```

## Tab 3: Purchase (3-Step Wizard)

### Step 1: Buyer Information
```
┌──────────────────────────────────────────┐
│ ● ──── ○ ──── ○  (Step Indicator)       │
│                                          │
│ 📝 Step 1: Your Information             │
│                                          │
│ Full Name: [________________]  *         │
│ Phone: [________________]  *             │
│ Department: [Select ▼]  *                │
│ Email: [________________] (optional)     │
│ Category: [Select ▼]  *                  │
│                                          │
│ Quantity: [-] [5] [+]                    │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ Total Amount: 250 HTG              │  │
│ └────────────────────────────────────┘  │
│                                          │
│ [Continue to Payment →]                  │
└──────────────────────────────────────────┘
```

### Step 2: Payment Method
```
┌──────────────────────────────────────────┐
│ ● ──── ● ──── ○  (Step Indicator)       │
│                                          │
│ 💳 Step 2: Choose Payment Method        │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ ⚡ MonCash          [Instant]      │  │
│ │                           →        │  │
│ └────────────────────────────────────┘  │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ ⚡ NatCash          [Instant]      │  │
│ │                           →        │  │
│ └────────────────────────────────────┘  │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ ✏️  Manual Payment  [Requires      │  │
│ │                      Approval]  →  │  │
│ └────────────────────────────────────┘  │
│                                          │
│ [← Back]                                 │
└──────────────────────────────────────────┘
```

### Step 3: Payment Details (Manual)
```
┌──────────────────────────────────────────┐
│ ● ──── ● ──── ●  (Step Indicator)       │
│                                          │
│ 💳 Step 3: Manual Payment               │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ ⚠️ Payment Instructions            │  │
│ │ Wallet: 1234-5678                  │  │
│ │ 1. Send payment to wallet          │  │
│ │ 2. Note your transaction reference │  │
│ │ 3. Submit reference below          │  │
│ └────────────────────────────────────┘  │
│                                          │
│ ┌────────────────────────────────────┐  │
│ │ Your Buyer Code: BC-123456         │  │
│ └────────────────────────────────────┘  │
│                                          │
│ Transaction Reference: [___________] *   │
│                                          │
│ [Submit Payment]                         │
│ [← Back]                                 │
└──────────────────────────────────────────┘
```

## Tab 4: My Tickets

```
┌──────────────────────────────────────────┐
│ 🔍 Look Up My Tickets                    │
│                                          │
│ Email: [________________]                │
│ Phone: [________________]                │
│ Buyer Code: [________________]           │
│                                          │
│ [🔍 Search Tickets]                      │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ Your Tickets                  [3 found]  │
│                                          │
│ 🎫 #123456              [Available]      │
│    Category: XYZ | 50 HTG                │
│    📊 Barcode: BC123 | 📅 2024-XX-XX    │
├──────────────────────────────────────────┤
│ 🎫 #123457              [Available]      │
│    Category: EFG | 100 HTG               │
│    📊 Barcode: BC124 | 📅 2024-XX-XX    │
├──────────────────────────────────────────┤
│ 🎫 #123458              [Sold]           │
│    Category: ABC | 500 HTG               │
│    📊 Barcode: BC125 | 📅 2024-XX-XX    │
└──────────────────────────────────────────┘
```

## Tab 5: Verify Ticket

```
┌──────────────────────────────────────────┐
│ ✅ Verify Ticket Status                  │
│                                          │
│ Enter ticket number or barcode           │
│                                          │
│ Ticket Number: [________________]  *     │
│                                          │
│ [✓ Verify Ticket]                        │
└──────────────────────────────────────────┘

Valid Result:
┌──────────────────────────────────────────┐
│         ✅                               │
│    ✅ Valid Ticket                       │
│                                          │
│ Ticket Number: 123456                    │
│ Category: XYZ                            │
│ Price: 50 HTG                            │
│ Status: Available                        │
└──────────────────────────────────────────┘

Invalid Result:
┌──────────────────────────────────────────┐
│         ❌                               │
│    ❌ Invalid Ticket                     │
│                                          │
│ Ticket not found or invalid              │
└──────────────────────────────────────────┘
```

## Ticket Badge Styles

Visual representation of the 6 gradient ticket badges:

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│ BASIC   │  │ PREMIUM │  │ BRONZE  │
└─────────┘  └─────────┘  └─────────┘
Green        Purple       Orange

┌─────────┐  ┌─────────┐  ┌─────────┐
│ SILVER  │  │  GOLD   │  │ DIAMOND │
└─────────┘  └─────────┘  └─────────┘
Silver       Gold         Cyan
(dark text)  (dark text)  (white text)
```

### Gradient Details:
- **BASIC**: Linear(#10b981 → #059669) white text
- **PREMIUM**: Linear(#7c3aed → #6366f1) white text
- **BRONZE**: Linear(#ea580c → #dc2626) white text
- **SILVER**: Linear(#cbd5e1 → #94a3b8) dark text
- **GOLD**: Linear(#fbbf24 → #f59e0b) dark text
- **DIAMOND**: Linear(#22d3ee → #06b6d4) white text

## Color Palette

```
Primary Gradient: #667eea → #764ba2 (Purple)
Background: Same gradient with transparency

Cards: White (#FFFFFF)
Text Primary: #1e293b
Text Secondary: #64748b
Text Tertiary: #94a3b8

Success: #10b981
Error: #ef4444
Warning: #f59e0b
Info: #3b82f6
```

## Responsive Behavior

- Tabs scroll horizontally on small screens
- Cards stack vertically on mobile
- Tables scroll horizontally on small screens
- Forms adapt to available width
- Buttons full-width on mobile

## Loading States

```
     ⟳
Loading...
```

## Empty States

```
  📭
  No Data
  Message here
  [Retry Button]
```

## Error States

```
  ⚠️
  Error Title
  Error message
  [Retry Button]
```

---

This guide provides a visual reference for the implemented Flutter Buyer Portal matching the web app design.
