# Architecture Overview

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Application Layers](#application-layers)
3. [State Management](#state-management)
4. [Data Flow](#data-flow)
5. [Directory Structure](#directory-structure)

## System Architecture

Grate Genyen follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  (Screens, Widgets, UI Components)      │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Business Logic Layer            │
│     (Providers, State Management)       │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│            Service Layer                │
│   (API, Auth, Payment, Storage)         │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│            Data Layer                   │
│  (Models, Local Storage, Cache)         │
└─────────────────────────────────────────┘
```

## Application Layers

### 1. Presentation Layer
- **Location**: `lib/screens/`, `lib/widgets/`
- **Responsibility**: UI rendering, user interactions
- **Components**: Screens, Widgets, Custom UI elements

### 2. Business Logic Layer
- **Location**: `lib/providers/`
- **Responsibility**: State management, business rules
- **Pattern**: Provider (ChangeNotifier)

### 3. Service Layer
- **Location**: `lib/services/`
- **Responsibility**: External integrations, API calls
- **Key Services**: ApiService, AuthService, PaymentService

### 4. Data Layer
- **Location**: `lib/models/`, `lib/config/`
- **Responsibility**: Data structures, configuration

## State Management

We use the Provider package for state management with ChangeNotifier pattern.

## Directory Structure

```
lib/
├── config/              # Configuration files
├── models/              # Data models
├── providers/           # State management
├── screens/             # Application screens
├── services/            # Business services
├── utils/               # Utilities & helpers
├── widgets/             # Reusable widgets
└── main.dart            # Application entry point
```
