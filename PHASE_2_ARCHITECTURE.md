# Phase 2 Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                             │
┌───────▼──────────┐                        ┌────────▼──────────┐
│  Admin Portal    │                        │  Seller Portal     │
│                  │                        │                    │
│ - Statistics     │                        │ - My Statistics    │
│ - Seller Mgmt    │                        │ - Sales History    │
│ - Approvals      │                        │ - Commission       │
│ - Charts         │                        │ - Charts           │
└───────┬──────────┘                        └────────┬──────────┘
        │                                            │
        └────────────────────┬───────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │   Providers      │
                    │  (State Mgmt)    │
                    │                  │
                    │ - Statistics     │
                    │ - Seller         │
                    │ - AdminTicket    │
                    │ - SellerSales    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │    Services      │
                    │  (API Layer)     │
                    │                  │
                    │ - Analytics      │
                    │ - Seller         │
                    │ - AdminTicket    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   API Service    │
                    │   (Dio Client)   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Backend APIs    │
                    │                  │
                    │ /api/admin/*     │
                    │ /api/seller/*    │
                    │ /api/sellers/*   │
                    └──────────────────┘
```

## Data Flow

### Admin Statistics Flow
```
User Action → StatisticsScreen
                    │
                    ↓
        StatisticsProvider.loadStatistics()
                    │
                    ↓
        AnalyticsService.getAdminStatistics()
                    │
                    ↓
        ApiService.get('/api/admin/statistics')
                    │
                    ↓
              Backend Server
                    │
                    ↓
        Statistics Model ← JSON Response
                    │
                    ↓
        Provider notifyListeners()
                    │
                    ↓
        UI Update (Charts & Cards)
```

### Seller Approval Flow
```
User Action → SellerApprovalScreen
                    │
                    ↓
        SellerProvider.loadPendingRequests()
                    │
                    ↓
        SellerService.getPendingSellerRequests()
                    │
                    ↓
        ApiService.get('/api/seller-requests')
                    │
                    ↓
              Backend Server
                    │
                    ↓
        List<Seller> ← JSON Response
                    │
                    ↓
        Display Pending List
                    │
        User clicks Approve
                    │
                    ↓
        SellerProvider.approveSeller(id)
                    │
                    ↓
        SellerService.approveSeller(id)
                    │
                    ↓
        ApiService.post('/api/seller-requests/:id/approve')
                    │
                    ↓
        Success → Refresh List → UI Update
```

## File Structure

```
flutter_app/lib/
│
├── models/
│   ├── statistics.dart          # Statistics, CategoryStat, DepartmentStat, SellerStat
│   ├── seller.dart              # Seller, SellerStatistics, CategorySales, DailySales
│   ├── winner.dart              # Winner model for raffles
│   └── ticket_admin.dart        # TicketAdmin, BulkTicketOperation
│
├── services/
│   ├── analytics_service.dart   # Statistics API calls
│   ├── seller_service.dart      # Seller CRUD, approvals, sales
│   └── admin_ticket_service.dart # Ticket management APIs
│
├── providers/
│   ├── statistics_provider.dart      # Admin statistics state
│   ├── seller_provider.dart          # Seller management state
│   ├── admin_ticket_provider.dart    # Ticket management state
│   └── seller_sales_provider.dart    # Seller sales state
│
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard.dart         # Main admin screen
│   │   ├── statistics_screen.dart       # Statistics dashboard
│   │   ├── seller_list_screen.dart      # All sellers
│   │   ├── seller_details_screen.dart   # Seller profile
│   │   └── seller_approval_screen.dart  # Pending approvals
│   │
│   └── seller/
│       ├── seller_dashboard.dart        # Main seller screen
│       ├── seller_stats_screen.dart     # Personal stats
│       ├── my_sales_screen.dart         # Sales history
│       └── commission_screen.dart       # Commission tracking
│
└── widgets/
    ├── stat_card.dart                    # Reusable stat card
    └── charts/
        ├── category_pie_chart.dart       # Category breakdown
        ├── department_bar_chart.dart     # Department performance
        └── seller_leaderboard.dart       # Top sellers ranking
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                        Main App                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              MultiProvider Setup                      │   │
│  │  - AuthProvider                                       │   │
│  │  - StatisticsProvider         ← NEW                   │   │
│  │  - SellerProvider             ← NEW                   │   │
│  │  - AdminTicketProvider        ← NEW                   │   │
│  │  - SellerSalesProvider        ← NEW                   │   │
│  │  - TicketProvider, RaffleProvider, etc.              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
                    ┌─────────────────┐
                    │  Route Table    │
                    ├─────────────────┤
                    │ /admin          │
                    │ /admin/statistics      ← NEW
                    │ /admin/sellers         ← NEW
                    │ /admin/sellers/approval ← NEW
                    │ /seller         │
                    │ /seller/stats          ← NEW
                    │ /seller/sales          ← NEW
                    │ /seller/commission     ← NEW
                    └─────────────────┘
```

## Widget Hierarchy Examples

### Statistics Screen
```
StatisticsScreen
├── AppBar
│   ├── Title
│   └── Actions (Filter, Refresh)
├── Consumer<StatisticsProvider>
│   └── RefreshIndicator
│       └── SingleChildScrollView
│           ├── Overview Section
│           │   ├── Text (Title)
│           │   └── GridView
│           │       ├── StatCard (Total Tickets)
│           │       ├── StatCard (Total Sold)
│           │       ├── StatCard (Revenue)
│           │       └── StatCard (Active Raffles)
│           ├── Category Section
│           │   ├── Text (Title)
│           │   └── Card
│           │       └── CategoryPieChart
│           ├── Department Section
│           │   ├── Text (Title)
│           │   └── Card
│           │       └── DepartmentBarChart
│           └── Sellers Section
│               ├── Text (Title)
│               └── SellerLeaderboard
```

### Seller Details Screen
```
SellerDetailsScreen
├── AppBar
│   ├── Title
│   └── PopupMenuButton (Edit, Delete)
├── Consumer<SellerProvider>
│   └── SingleChildScrollView
│       ├── Info Card
│       │   ├── Avatar + Name
│       │   ├── Status Chip
│       │   └── Details (Phone, Email, Dept)
│       ├── Performance Section
│       │   └── GridView
│       │       ├── StatCard (Sales)
│       │       ├── StatCard (Commission)
│       │       ├── StatCard (Active Tickets)
│       │       └── StatCard (Revenue)
│       └── Actions (if pending)
│           ├── Approve Button
│           └── Reject Button
```

## State Management Pattern

```
┌──────────────────────────────────────────────────────────┐
│                 ChangeNotifier Pattern                     │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Provider (extends ChangeNotifier)                        │
│  ├── Private State Variables                             │
│  │   ├── _data                                           │
│  │   ├── _isLoading                                      │
│  │   └── _error                                          │
│  │                                                         │
│  ├── Public Getters                                       │
│  │   ├── get data => _data                               │
│  │   ├── get isLoading => _isLoading                     │
│  │   └── get error => _error                             │
│  │                                                         │
│  └── Public Methods                                       │
│      ├── async loadData()                                │
│      │   ├── Set _isLoading = true                       │
│      │   ├── notifyListeners()                           │
│      │   ├── Call service                                │
│      │   ├── Update _data                                │
│      │   ├── Set _isLoading = false                      │
│      │   └── notifyListeners()                           │
│      │                                                     │
│      └── async performAction()                           │
│          ├── Call service                                │
│          ├── Update state                                │
│          └── notifyListeners()                           │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

## API Integration Pattern

```
┌──────────────────────────────────────────────────────────┐
│                  Service Layer Pattern                     │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Service Class                                            │
│  ├── final ApiService _apiService                        │
│  │                                                         │
│  ├── Future<Model> getData()                             │
│  │   try {                                                │
│  │     response = await _apiService.get('/endpoint')     │
│  │     return Model.fromJson(response.data)              │
│  │   } catch (e) {                                        │
│  │     throw Exception('Failed: $e')                     │
│  │   }                                                    │
│  │                                                         │
│  └── Future<void> performAction(data)                    │
│      try {                                                │
│        await _apiService.post('/endpoint', data: data)   │
│      } catch (e) {                                        │
│        throw Exception('Failed: $e')                     │
│      }                                                    │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

## Chart Integration

```
┌──────────────────────────────────────────────────────────┐
│                  fl_chart Integration                      │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  CategoryPieChart                                         │
│  ├── Input: List<CategoryStat>                           │
│  ├── Process:                                             │
│  │   ├── Calculate totals                                │
│  │   ├── Create sections with colors                     │
│  │   └── Generate legends                                │
│  └── Output: PieChart widget                             │
│                                                            │
│  DepartmentBarChart                                       │
│  ├── Input: List<DepartmentStat>                         │
│  ├── Process:                                             │
│  │   ├── Calculate max value for Y-axis                  │
│  │   ├── Create bar groups with colors                   │
│  │   └── Setup tooltips                                  │
│  └── Output: BarChart widget                             │
│                                                            │
│  SellerLeaderboard                                        │
│  ├── Input: List<SellerStat>                             │
│  ├── Process:                                             │
│  │   ├── Take top N sellers                              │
│  │   ├── Assign rank colors (gold/silver/bronze)         │
│  │   └── Format data                                     │
│  └── Output: ListView of cards                           │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

## Navigation Flow

### Admin Flow
```
Login (Admin)
    │
    ↓
AdminDashboard
    ├─→ Dashboard Tab (default)
    ├─→ Statistics Tab → StatisticsScreen
    ├─→ Tickets Tab
    ├─→ Sellers Tab → SellerListScreen
    │                       ├─→ SellerDetailsScreen
    │                       │       ├─→ Approve Action
    │                       │       └─→ Reject Action
    │                       └─→ Filter Options
    ├─→ Approvals Tab → SellerApprovalScreen
    │                       ├─→ SellerDetailsScreen
    │                       └─→ Quick Actions
    ├─→ Draws Tab
    └─→ Payments Tab
```

### Seller Flow
```
Login (Seller)
    │
    ↓
SellerDashboard
    ├─→ Dashboard Tab (default)
    ├─→ My Tickets Tab
    ├─→ Sales Tab → MySalesScreen
    ├─→ Stats Tab → SellerStatsScreen
    └─→ Commission Tab → CommissionScreen
```

## Error Handling Flow

```
User Action
    │
    ↓
Provider.method()
    │
    ├─ try {
    │    Service.call()
    │        │
    │        ├─ Success → Update state → notifyListeners()
    │        │                                │
    │        │                                ↓
    │        │                          UI shows data
    │        │
    │        └─ Error → throw Exception
    │                       │
    │                       ↓
    │  } catch (e) {
    │    Set error message
    │    notifyListeners()
    │        │
    │        ↓
    │   UI shows error with retry button
    │  }
    │
    └─→ User clicks retry → Restart flow
```

This architecture provides:
- Clean separation of concerns
- Testable components
- Reusable widgets
- Consistent patterns
- Easy maintenance and extension
