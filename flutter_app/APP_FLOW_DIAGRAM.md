# Flutter Scratch Tickets - App Flow Diagram

## User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                              │
│                     (main_scratch.dart)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         v
┌─────────────────────────────────────────────────────────────────┐
│                   TICKET GALLERY SCREEN                         │
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                        │
│  │ Basic   │  │ Premium │  │ Bronze  │                        │
│  │ 50 HTG  │  │ 100 HTG │  │ 250 HTG │                        │
│  └─────────┘  └─────────┘  └─────────┘                        │
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                        │
│  │ Silver  │  │  Gold   │  │ Diamond │                        │
│  │ 500 HTG │  │1000 HTG │  │5000 HTG │                        │
│  └─────────┘  └─────────┘  └─────────┘                        │
│                                                                 │
│         [User taps on a ticket]                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         v
┌─────────────────────────────────────────────────────────────────┐
│                     SCRATCH SCREEN                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │             TICKET HEADER                             │     │
│  │  • Ticket name (e.g., "GRATE GENYEN")               │     │
│  │  • Type (e.g., "Premium")                           │     │
│  │  • Price badge (e.g., "100 HTG")                    │     │
│  │  • Prize range (e.g., "Win up to 15,000 GOURDES")  │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │           SCRATCH AREA (Interactive)                  │     │
│  │                                                       │     │
│  │    [User scratches here with finger]                 │     │
│  │                                                       │     │
│  │    Prize hidden underneath:                          │     │
│  │    • Emoji (e.g., 🎰)                                │     │
│  │    • Text (e.g., "OU GENYEN 15,000 GOUD")           │     │
│  │                                                       │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │          PROGRESS INDICATOR                           │     │
│  │  [▓▓▓▓▓▓▓░░░░░░░░] Scratched: 45%                   │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│         [Scratch reaches 70% threshold]                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         v
┌─────────────────────────────────────────────────────────────────┐
│                     RESULT DIALOG                               │
│                                                                 │
│              🎰                                                 │
│                                                                 │
│           Félicitasyon!                                         │
│      (or "Eseye Ankò!" if no win)                             │
│                                                                 │
│        OU GENYEN 15,000 GOUD                                   │
│                                                                 │
│     ┌─────────────────────────────────┐                       │
│     │  Ou genyen: 15000 HTG          │                       │
│     └─────────────────────────────────┘                       │
│                                                                 │
│  ┌──────────────┐        ┌──────────────┐                    │
│  │ ← Back       │        │ ↻ Play Again │                    │
│  └──────────────┘        └──────────────┘                    │
│                                                                 │
└────────────────────────┬───────────┬────────────────────────────┘
                         │           │
         ┌───────────────┘           └────────────────┐
         │                                            │
         v                                            v
┌─────────────────┐                    ┌─────────────────────────┐
│ Return to       │                    │ Reload Scratch Screen   │
│ Gallery         │                    │ (New Prize Selected)    │
└─────────────────┘                    └─────────────────────────┘
```

## Technical Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT                             │
│                   (TicketProvider)                              │
│                                                                 │
│  • loadTickets() - Load all 6 ticket configurations           │
│  • scratchTicket(id) - Select random prize                    │
│  • getScratchedPrize(id) - Retrieve result                    │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         v
┌─────────────────────────────────────────────────────────────────┐
│                    DATA MODELS                                  │
│                                                                 │
│  ScratchTicket                                                 │
│  ├── id, name, typeName                                        │
│  ├── price, prizeRange                                         │
│  ├── prizes: List<Prize>                                       │
│  └── theme: TicketTheme                                        │
│                                                                 │
│  Prize                                                         │
│  ├── emoji, text                                               │
│  ├── value (HTG amount)                                        │
│  └── weight (probability)                                      │
│                                                                 │
│  TicketTheme                                                   │
│  ├── gradientColors: List<Color>                              │
│  ├── textColor: Color                                          │
│  └── animation: String                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Prize Selection Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│              WEIGHTED PROBABILITY SYSTEM                        │
│                                                                 │
│  Example: Basic Ticket (Total Weight = 400)                   │
│                                                                 │
│  Prize          Weight    Probability    Range                │
│  ─────────────────────────────────────────────────────────────│
│  5,000 HTG      1         0.25%          [0-1)               │
│  2,500 HTG      3         0.75%          [1-4)               │
│  1,000 HTG      10        2.50%          [4-14)              │
│    500 HTG      25        6.25%          [14-39)             │
│    100 HTG      60        15.00%         [39-99)             │
│      5 HTG      100       25.00%         [99-199)            │
│  Try Again      201       50.25%         [199-400)           │
│                                                                 │
│  Algorithm:                                                    │
│  1. Calculate totalWeight = sum(all weights)                  │
│  2. Generate random number in [0, totalWeight)                │
│  3. Iterate through prizes, adding weights                    │
│  4. Return prize when random < accumulated weight             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Hierarchy

```
MaterialApp
└── TicketGalleryScreen
    ├── AppBar (with gradient)
    ├── Container (gradient background)
    └── Consumer<TicketProvider>
        ├── Header Message
        └── GridView.builder
            └── TicketCard (x6)
                ├── Gradient Header
                ├── Prize Info
                └── Tap Handler
                    └── Navigate to ScratchScreen
                        ├── AppBar (themed)
                        ├── Instructions
                        └── ScratchCardWidget
                            ├── TicketHeader (gradient)
                            ├── Scratcher
                            │   └── Prize Content (hidden)
                            └── ProgressIndicator
                                └── onThreshold
                                    └── Show ResultDialog
                                        ├── Prize Display
                                        └── Actions
                                            ├── Back
                                            └── Play Again
```

## Theme Colors by Ticket Type

```
┌──────────┬────────────────────────────────────────────────────┐
│ Ticket   │ Gradient Colors                                    │
├──────────┼────────────────────────────────────────────────────┤
│ Basic    │ 🟢 #10b981 → #059669 → #047857 (Green Sparkle)   │
│ Premium  │ 🟣 #7c3aed → #6366f1 → #8b5cf6 (Purple Cosmic)   │
│ Bronze   │ 🟠 #ea580c → #dc2626 → #c2410c (Bronze/Orange)   │
│ Silver   │ ⚪ #cbd5e1 → #94a3b8 → #64748b (Silver Holo)     │
│ Gold     │ 🟡 #fbbf24 → #f59e0b → #d97706 (Golden Sun)      │
│ Diamond  │ 🔵 #22d3ee → #06b6d4 → #0891b2 (Blue Ice)        │
└──────────┴────────────────────────────────────────────────────┘
```

## Build Process Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   DEVELOPMENT                                   │
│                                                                 │
│  1. Edit Dart files in lib/                                    │
│  2. Hot reload (r) / Hot restart (R)                           │
│  3. Test on emulator/device                                    │
│  4. Debug with DevTools                                        │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         v
┌─────────────────────────────────────────────────────────────────┐
│                    BUILD PROCESS                                │
│                                                                 │
│  Android:                          iOS:                        │
│  ┌─────────────────────┐          ┌───────────────────────┐   │
│  │ flutter build apk   │          │ flutter build ios     │   │
│  │    --release        │          │    --release          │   │
│  └──────────┬──────────┘          └───────────┬───────────┘   │
│             │                                  │               │
│             v                                  v               │
│  ┌─────────────────────┐          ┌───────────────────────┐   │
│  │ Gradle build        │          │ Xcode build           │   │
│  │ • Compile Kotlin    │          │ • Compile Swift       │   │
│  │ • Package resources │          │ • Sign with cert      │   │
│  │ • Generate APK/AAB  │          │ • Generate IPA        │   │
│  └──────────┬──────────┘          └───────────┬───────────┘   │
│             │                                  │               │
│             v                                  v               │
│  ┌─────────────────────┐          ┌───────────────────────┐   │
│  │ app-release.apk     │          │ raffle_app.ipa        │   │
│  │ OR                  │          │                       │   │
│  │ app-release.aab     │          │                       │   │
│  └─────────────────────┘          └───────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## File Dependencies

```
main_scratch.dart
├── providers/ticket_provider.dart
├── screens/scratch/ticket_gallery_screen.dart
│   ├── widgets/ticket_card.dart
│   │   └── models/scratch/scratch_ticket.dart
│   └── screens/scratch/scratch_screen.dart
│       ├── widgets/scratch_card_widget.dart
│       │   ├── models/scratch/scratch_ticket.dart
│       │   ├── models/scratch/prize.dart
│       │   └── scratcher (package)
│       └── providers/ticket_provider.dart
├── utils/ticket_constants.dart
│   ├── models/scratch/scratch_ticket.dart
│   ├── models/scratch/prize.dart
│   └── models/scratch/ticket_theme.dart
└── config/app_theme.dart
```

---

This diagram provides a comprehensive visual representation of the Flutter Scratch Tickets app flow, from user interaction to technical implementation.
