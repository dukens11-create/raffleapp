# Customer Department Tracking Implementation

## Overview
This implementation adds the ability to track which of the 10 Haiti departments customers are purchasing tickets from. Department information is collected during ticket purchase and displayed in seller dashboards.

## The 10 Haiti Departments
1. Ouest
2. Sud
3. Nord
4. Artibonite
5. Centre
6. Grand'Anse
7. Nippes
8. Nord-Est
9. Nord-Ouest
10. Sud-Est

## Database Changes

### New Columns
Two tables have been updated with a new `customer_department` TEXT column:
- `tickets` table - stores the department for each ticket sold
- `payments` table - stores the department for each payment

### Migration
A migration script is provided: `raffle-app/migrations/add_customer_department.js`

**To run the migration:**
```bash
cd raffle-app
node migrations/add_customer_department.js
```

**Features:**
- Compatible with both PostgreSQL and SQLite
- Safely handles existing databases
- Verifies column addition
- Provides statistics on current data

**Auto-migration:** The columns are also automatically added when the server starts if they don't exist (in `db.js` initialization).

## Backend API Changes

### New Endpoints

#### `GET /api/departments`
Public endpoint that returns the list of valid Haiti departments.

**Response:**
```json
{
  "success": true,
  "departments": ["Ouest", "Sud", "Nord", ...]
}
```

#### `GET /api/seller/department-stats`
Protected endpoint (requires authentication) that returns department statistics for the logged-in seller.

**Response:**
```json
{
  "success": true,
  "departments": [
    {
      "customer_department": "Ouest",
      "ticket_count": 45,
      "total_revenue": 2250.00,
      "percentage": 30
    },
    ...
  ],
  "total": {
    "total_tickets": 150,
    "total_revenue": 7500.00
  }
}
```

#### `GET /api/admin/department-stats`
Admin-only endpoint that returns system-wide department statistics across all sellers.

**Response:** Same format as seller endpoint but includes all tickets across all sellers.

### Updated Endpoints

All payment initiation and submission endpoints now require the `customer_department` parameter:

- `POST /api/payments/moncash/initiate`
- `POST /api/payments/natcash/initiate`
- `POST /api/payments/manual/submit`

**Required Parameter:**
```json
{
  "customer_department": "Ouest",
  // ... other required fields
}
```

**Validation:**
- Server-side validation ensures the department is one of the 10 valid options
- Returns 400 error if department is missing or invalid

### Payment Approval
When admins approve manual payments (`POST /api/admin/payments/approve`), the department is automatically copied from the payment record to all assigned tickets.

## Frontend Changes

### Buyer Purchase Form (`buyers.html`)

#### New Field
A required dropdown field has been added after the phone number field:

```html
<select id="purchase-department" required>
  <option value="">Select your department...</option>
  <!-- Options populated dynamically from API -->
</select>
```

#### JavaScript Functions
- `loadDepartments()` - Fetches the list of departments from `/api/departments` and populates the dropdown
- Updated `proceedToPayment()` - Validates that a department is selected before proceeding
- Updated payment submission functions to include `customer_department` in all payment requests

### Seller Dashboard (`seller.html`)

#### New Section
"Sales by Department" section displays statistics in a table format:

- Department name
- Number of tickets sold
- Total revenue
- Percentage of total sales
- Visual progress bar

#### JavaScript Functions
- `loadDepartmentStats()` - Fetches seller-specific statistics from `/api/seller/department-stats`
- Called automatically when the dashboard loads
- Handles empty states gracefully

#### CSS Styling
- `.dept-stats-table` - Styles for the statistics table
- `.dept-progress-bar` - Progress bar container
- `.dept-progress-fill` - Progress bar fill with gradient

## Validation

### Server-Side
- `isValidDepartment(department)` - Helper function validates against the list of 10 departments
- Used in express-validator chains on all payment endpoints
- Returns clear error messages when validation fails

### Client-Side
- HTML5 `required` attribute on the department select field
- JavaScript validation in `proceedToPayment()` function
- User-friendly error messages displayed on the form

## Testing Checklist

### Database
- [ ] Run migration script successfully on SQLite
- [ ] Run migration script successfully on PostgreSQL
- [ ] Verify columns exist with correct type
- [ ] Test that server starts without errors

### API Endpoints
- [ ] Test `GET /api/departments` returns correct list
- [ ] Test `GET /api/seller/department-stats` requires authentication
- [ ] Test `GET /api/admin/department-stats` requires admin role
- [ ] Test payment endpoints reject requests without department
- [ ] Test payment endpoints reject invalid departments
- [ ] Test payment endpoints accept valid departments

### Frontend
- [ ] Verify department dropdown appears on purchase form
- [ ] Verify dropdown is populated with all 10 departments
- [ ] Verify form cannot be submitted without selecting department
- [ ] Test MonCash payment includes department
- [ ] Test NatCash payment includes department
- [ ] Test manual payment includes department

### Seller Dashboard
- [ ] Verify "Sales by Department" section appears
- [ ] Verify empty state displays when no data
- [ ] Verify statistics display correctly with data
- [ ] Verify progress bars display correctly
- [ ] Verify percentages add up correctly

### End-to-End
- [ ] Complete a ticket purchase with department selection
- [ ] Verify department is saved in database
- [ ] Verify department appears in seller statistics
- [ ] Verify department appears in ticket records

## Backward Compatibility

### Existing Data
- Existing tickets without department information will have `NULL` in the `customer_department` field
- Statistics queries handle NULL values correctly using `WHERE customer_department IS NOT NULL`
- The system continues to work with existing data

### No Breaking Changes
- All changes are additive (new columns, new endpoints)
- Existing functionality remains unchanged
- No modifications to existing API contracts (except adding required parameter)

## Deployment Notes

### Environment Variables
No new environment variables are required.

### Database Migration
1. Automatic: Columns are added automatically when the server starts
2. Manual: Run the migration script for verification: `node migrations/add_customer_department.js`

### Order of Operations
1. Deploy code changes
2. Restart server (columns will be added automatically)
3. Verify department dropdown appears on purchase form
4. Verify seller dashboard shows statistics section

### Rollback Plan
If rollback is needed:
1. Revert code changes
2. Department columns can remain in database (they won't cause issues)
3. Or remove columns with:
   ```sql
   ALTER TABLE tickets DROP COLUMN customer_department;
   ALTER TABLE payments DROP COLUMN customer_department;
   ```

## Future Enhancements

Potential improvements for future iterations:

1. **Multi-language Support**
   - Add Haitian Creole translations for department names
   - Implement language toggle on forms

2. **Geographic Visualization**
   - Add map visualization on admin dashboard
   - Show department distribution geographically

3. **Advanced Analytics**
   - Track department trends over time
   - Compare performance across departments
   - Predict popular departments for inventory planning

4. **Export Functionality**
   - Include department in CSV exports
   - Add department filters to export options

5. **Department-based Promotions**
   - Target specific departments with promotions
   - Department-specific ticket pricing

## Support

For questions or issues with this implementation:
- Check the migration output for detailed error messages
- Verify DATABASE_URL is set correctly
- Ensure all dependencies are installed (`npm install`)
- Check server logs for validation errors

## Files Modified

### Backend
- `raffle-app/db.js` - Schema updates and auto-migration
- `raffle-app/server.js` - API endpoints, validation, and statistics
- `raffle-app/migrations/add_customer_department.js` - Migration script (new)

### Frontend
- `raffle-app/public/buyers.html` - Purchase form with department field
- `raffle-app/public/seller.html` - Dashboard with department statistics

## Version History

- **v1.0** - Initial implementation (current)
  - Database schema updates
  - API endpoints for department management
  - Frontend forms with department selection
  - Seller dashboard with statistics
  - Migration script for existing databases
