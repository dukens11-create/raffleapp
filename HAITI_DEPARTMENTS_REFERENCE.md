# Haiti Departments Reference

## Official List of Haiti's 10 Departments

This document serves as the authoritative reference for Haiti's 10 administrative departments (départements) used throughout the Raffle App system.

### Complete Department List (Alphabetically Ordered)

| Code | Department (French) | Kreyòl Name | English Translation |
|------|---------------------|-------------|---------------------|
| AR   | Artibonite          | Latibonit   | Artibonite          |
| CE   | Centre              | Sant        | Center              |
| GA   | Grand'Anse          | Grandans    | Grand Anse          |
| NI   | Nippes              | Nip         | Nippes              |
| NO   | Nord                | Nò          | North               |
| NE   | Nord-Est            | Nòdès       | Northeast           |
| NW   | Nord-Ouest          | Nòdwès      | Northwest           |
| OU   | Ouest               | Lwès        | West                |
| SU   | Sud                 | Sid         | South               |
| SE   | Sud-Est             | Sidès       | Southeast           |

## Ordering Standard

**All department lists MUST be alphabetically sorted by French name** across all platforms:
- Backend (Node.js/Express)
- Flutter mobile app
- HTML/JavaScript web interfaces
- Database queries and exports
- API responses

### Rationale for Alphabetical Ordering:
- ✅ Predictable and easy to navigate
- ✅ Consistent user experience across platforms
- ✅ International standard for administrative divisions
- ✅ Language-neutral ordering principle
- ✅ Easier to find specific departments

## Implementation Locations

### Backend (raffle-app/server.js)
```javascript
const HAITI_DEPARTMENTS = [
  'Artibonite',
  'Centre',
  "Grand'Anse",
  'Nippes',
  'Nord',
  'Nord-Est',
  'Nord-Ouest',
  'Ouest',
  'Sud',
  'Sud-Est'
];
```

### Flutter Mobile App (flutter_app/lib/models/department.dart)
```dart
static final List<Department> all = [
  Department(code: 'AR', name: 'Artibonite', nameKreyol: 'Latibonit'),
  Department(code: 'CE', name: 'Centre', nameKreyol: 'Sant'),
  Department(code: 'GA', name: 'Grand\'Anse', nameKreyol: 'Grandans'),
  Department(code: 'NI', name: 'Nippes', nameKreyol: 'Nip'),
  Department(code: 'NO', name: 'Nord', nameKreyol: 'Nò'),
  Department(code: 'NE', name: 'Nord-Est', nameKreyol: 'Nòdès'),
  Department(code: 'NW', name: 'Nord-Ouest', nameKreyol: 'Nòdwès'),
  Department(code: 'OU', name: 'Ouest', nameKreyol: 'Lwès'),
  Department(code: 'SU', name: 'Sud', nameKreyol: 'Sid'),
  Department(code: 'SE', name: 'Sud-Est', nameKreyol: 'Sidès'),
];
```

### Web Interface HTML Files
- `raffle-app/public/seller.html` - Seller dashboard department datalist
- `raffle-app/public/admin.html` - Admin dashboard department filter
- `raffle-app/public/buyers.html` - Buyer portal (dynamically loaded via API)

## API Endpoints

### GET /api/public/departments
Returns department information in two formats for backward compatibility:

```json
{
  "success": true,
  "departments": [
    "Artibonite",
    "Centre",
    "Grand'Anse",
    "Nippes",
    "Nord",
    "Nord-Est",
    "Nord-Ouest",
    "Ouest",
    "Sud",
    "Sud-Est"
  ],
  "departmentsDetailed": [
    { "code": "AR", "name": "Artibonite", "nameKreyol": "Latibonit" },
    { "code": "CE", "name": "Centre", "nameKreyol": "Sant" },
    { "code": "GA", "name": "Grand'Anse", "nameKreyol": "Grandans" },
    { "code": "NI", "name": "Nippes", "nameKreyol": "Nip" },
    { "code": "NO", "name": "Nord", "nameKreyol": "Nò" },
    { "code": "NE", "name": "Nord-Est", "nameKreyol": "Nòdès" },
    { "code": "NW", "name": "Nord-Ouest", "nameKreyol": "Nòdwès" },
    { "code": "OU", "name": "Ouest", "nameKreyol": "Lwès" },
    { "code": "SU", "name": "Sud", "nameKreyol": "Sid" },
    { "code": "SE", "name": "Sud-Est", "nameKreyol": "Sidès" }
  ]
}
```

**Backward Compatibility:**
- `departments` field: Array of department name strings (existing format)
- `departmentsDetailed` field: Array of department objects with codes and Kreyòl names (new format)

## Department Codes

Two-letter codes are used in the Flutter mobile app for compact storage and display:

- **AR** - Artibonite
- **CE** - Centre  
- **GA** - Grand'Anse
- **NI** - Nippes
- **NO** - Nord
- **NE** - Nord-Est
- **NW** - Nord-Ouest
- **OU** - Ouest
- **SU** - Sud
- **SE** - Sud-Est

## Kreyòl (Haitian Creole) Names

Kreyòl is one of Haiti's official languages alongside French. The app supports displaying department names in Kreyòl for better accessibility:

- **Latibonit** - Artibonite
- **Sant** - Centre
- **Grandans** - Grand'Anse
- **Nip** - Nippes
- **Nò** - Nord
- **Nòdès** - Nord-Est
- **Nòdwès** - Nord-Ouest
- **Lwès** - Ouest
- **Sid** - Sud
- **Sidès** - Sud-Est

## Usage Guidelines

### For Frontend Developers
1. Always use the API endpoint `/api/public/departments` to fetch departments
2. Use `departments` field for simple string lists
3. Use `departmentsDetailed` field when codes or Kreyòl names are needed
4. Do not hardcode department lists in multiple locations
5. Ensure dropdowns and selectors maintain alphabetical order

### For Backend Developers
1. Reference the `HAITI_DEPARTMENTS` constant in `server.js`
2. Use `isValidDepartment()` function to validate department inputs
3. Maintain alphabetical ordering when adding features
4. Keep the `getDepartmentsResponse()` function up to date

### For Mobile App Developers
1. Use `HaitiDepartments.all` from `department.dart`
2. Use `findByCode()` to look up departments by code
3. Use `findByName()` to look up by French or Kreyòl name
4. Display departments using the `name` property (French) or `nameKreyol` property

## Data Validation

All department inputs must match exactly one of the 10 official department names (case-insensitive matching is acceptable):

```javascript
// Backend validation (server.js)
function isValidDepartment(department) {
  return department && HAITI_DEPARTMENTS.includes(department);
}
```

```dart
// Flutter validation (department.dart)
static Department? findByName(String name) {
  try {
    return all.firstWhere(
      (dept) => dept.name.toLowerCase() == name.toLowerCase() || 
                dept.nameKreyol.toLowerCase() == name.toLowerCase()
    );
  } catch (e) {
    return null;
  }
}
```

## Historical Note

Prior to this standardization, different parts of the application used different ordering schemes:
- **Backend**: Alphabetical order ✅
- **Flutter App**: Custom order starting with Ouest (most populous) ❌
- **HTML Files**: Mixed ordering ❌

This caused confusion and potential bugs. The alphabetical standard was adopted for consistency and predictability.

## Testing Checklist

When making changes involving departments, verify:

- [ ] Backend `/api/public/departments` returns departments in alphabetical order
- [ ] Backend `/api/departments` returns departments in alphabetical order  
- [ ] Flutter app displays departments alphabetically in all dropdowns
- [ ] Seller dashboard shows departments alphabetically
- [ ] Buyer portal loads departments alphabetically
- [ ] Admin page filters show departments alphabetically
- [ ] Department validation accepts all 10 departments (case-insensitive)
- [ ] Kreyòl names display correctly where implemented
- [ ] Department codes match between backend and Flutter
- [ ] API response includes both `departments` and `departmentsDetailed` fields

## Related Files

- `/raffle-app/server.js` - Backend department constant and validation
- `/flutter_app/lib/models/department.dart` - Flutter department model
- `/raffle-app/public/seller.html` - Seller dashboard
- `/raffle-app/public/admin.html` - Admin dashboard
- `/raffle-app/public/buyers.html` - Buyer portal

## References

- [Departments of Haiti - Wikipedia](https://en.wikipedia.org/wiki/Departments_of_Haiti)
- [ISO 3166-2:HT](https://en.wikipedia.org/wiki/ISO_3166-2:HT) - ISO country subdivision codes for Haiti

---

**Last Updated:** February 2026  
**Maintained By:** Raffle App Development Team
