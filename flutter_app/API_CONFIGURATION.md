# API Configuration

## Production API
- **Base URL:** `https://grategenyen.com`
- **Default Environment:** Production

## Testing Connection
You can test the API connection:
```bash
curl https://grategenyen.com/health
curl https://grategenyen.com/api/public/raffle-info
```

## Custom API URL (Development)
To use a different API URL during development:
```bash
flutter run --dart-define=API_BASE_URL=https://your-dev-server.com
```

## Troubleshooting
If no tickets are displayed:
1. Check internet connection
2. Verify backend is running at https://grategenyen.com
3. Check Flutter console for error messages
4. Test API endpoints with curl commands above

## Configuration Details

### API Configuration File
The API base URL is configured in `lib/config/api_config.dart`:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://grategenyen.com',
);
```

### Error Handling
The `BuyerApiService` (`lib/services/buyer_api_service.dart`) includes enhanced error handling that provides user-friendly messages for common connection issues:

- **Network connectivity issues**: "Cannot connect to server at https://grategenyen.com. Please check your internet connection..."
- **Timeout issues**: "Connection timeout. The server at https://grategenyen.com is taking too long to respond..."
- **SSL certificate errors**: Clear messages about certificate issues

### CI/CD Configuration
The `codemagic.yaml` file in the repository root includes the API_BASE_URL configuration for automated builds:
```yaml
vars:
  API_BASE_URL: "https://grategenyen.com"
```

## Environment Variables

### Building with Custom API URL
For development or testing with a different backend:

```bash
# Development build
flutter run --dart-define=API_BASE_URL=http://localhost:10000

# Release build with custom URL
flutter build apk --release --dart-define=API_BASE_URL=https://staging.grategenyen.com
```

### Available Endpoints
The production API at `https://grategenyen.com` provides:

- **Public Endpoints** (no authentication required):
  - `/api/public/raffle-info` - Get raffle information
  - `/api/public/available-tickets` - Get available tickets
  - `/api/public/departments` - Get list of departments
  - `/api/public/ticket-availability` - Get ticket availability status
  - `/api/public/purchase/initiate` - Initiate ticket purchase
  - `/api/public/my-tickets` - Look up purchased tickets
  - `/api/public/verify-ticket/{ticketNumber}` - Verify a ticket

- **Payment Endpoints**:
  - `/api/payments/methods` - Get available payment methods
  - `/api/payments/manual-instructions/{method}` - Get manual payment instructions
  - `/api/payments/manual/submit` - Submit manual payment

- **Health Check**:
  - `/health` - Check API server status

## Support
For issues connecting to the production API:
1. Verify the domain `grategenyen.com` is accessible from your network
2. Check the Flutter console for detailed error messages
3. Test endpoints using curl commands shown above
4. Contact support with error details if issues persist
