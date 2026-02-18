# Update Raffle Name to GRATE GENYEN

This migration updates the raffle name from "Grand Raffle 2026" or "Default Raffle" to "GRATE GENYEN".

## Run Migration

```bash
cd raffle-app
node migrations/update-raffle-name.js
```

## What It Does

1. Updates all raffles in the database with old names to "GRATE GENYEN"
2. Updates the description to "Official Grate Genyen raffle for ticket sales"
3. Verifies the changes by listing all raffles

## Safe to Run Multiple Times

This migration is idempotent - it only updates raffles that still have old names, so it's safe to run multiple times.

## After Migration

All pages displaying the raffle name will automatically show "GRATE GENYEN":
- Buyer portal (Raffle Info tab)
- Flutter app (Home screen)
- Admin dashboard
- API responses
