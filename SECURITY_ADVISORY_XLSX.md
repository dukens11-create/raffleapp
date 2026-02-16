# Security Advisory: xlsx Dependency Vulnerabilities

## Status: KNOWN ISSUE - AWAITING PATCH

## Summary
The project uses `xlsx` version 0.18.5, which has two known vulnerabilities. However, the patched versions are not yet available in the npm registry.

## Vulnerabilities

### 1. SheetJS Regular Expression Denial of Service (ReDoS)
- **Severity**: Medium
- **Affected Versions**: < 0.20.2
- **Required Fix**: Upgrade to xlsx@0.20.2 or higher
- **Status**: Patch version 0.20.2 not yet published to npm (latest is 0.18.5)

### 2. Prototype Pollution in sheetJS
- **Severity**: High
- **Affected Versions**: < 0.19.3
- **Required Fix**: Upgrade to xlsx@0.19.3 or higher
- **Status**: Patch version 0.19.3 not yet published to npm (latest is 0.18.5)

## Current Usage
The `xlsx` package is used in:
- `raffle-app/services/importExportService.js` - For generating Excel templates and processing ticket imports/exports
- Used only by authenticated administrators with proper access controls

## Risk Assessment

### Low Risk Factors
1. **Limited Exposure**: xlsx is used only in admin-authenticated endpoints
2. **Controlled Input**: File uploads are restricted to authenticated administrators
3. **File Size Limits**: Multer enforces file size restrictions
4. **Input Validation**: Files are validated before processing

### Attack Scenarios
1. **ReDoS**: Malicious Excel file with crafted formulas could cause regex denial of service
2. **Prototype Pollution**: Crafted Excel file could pollute JavaScript prototypes

## Mitigation Measures (Currently Implemented)

### 1. Authentication & Authorization
```javascript
// Only admin users can access import/export endpoints
router.post('/api/admin/import', adminAuthMiddleware, uploadMiddleware, ...);
```

### 2. File Size Limits
```javascript
// Multer configuration limits file size
const upload = multer({
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB max
});
```

### 3. Rate Limiting
```javascript
// Express rate limiting prevents abuse
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP
}));
```

### 4. Input Validation
- Files are validated for proper Excel format
- Data is sanitized before database insertion
- Error handling prevents information disclosure

## Recommended Actions

### Immediate (Implemented)
- ✅ Document the vulnerability
- ✅ Verify authentication on all xlsx-using endpoints
- ✅ Ensure rate limiting is active
- ✅ Monitor for unusual activity in import/export logs

### Short-term (When Available)
- [ ] Monitor npm for xlsx@0.19.3 or higher release
- [ ] Upgrade immediately when patched version is published
- [ ] Run security scan after upgrade to verify fix

### Alternative Solutions (If patch delayed)
1. **Replace with exceljs**: More actively maintained, no known vulnerabilities
   - Pros: Similar API, better maintained, TypeScript support
   - Cons: Requires code refactoring, breaking changes
   
2. **Sandbox xlsx processing**: Run in isolated process
   - Pros: Contains potential exploits
   - Cons: Complexity, performance overhead

3. **Disable import feature**: Temporary measure
   - Pros: Eliminates risk completely
   - Cons: Loses functionality

## Monitoring

Monitor these areas for potential exploitation:
1. **Server logs**: Watch for unusual CPU spikes during Excel processing
2. **Error logs**: Look for repeated parsing failures
3. **Admin activity**: Monitor admin import/export operations
4. **Memory usage**: Watch for unexpected memory growth

## Action Items

- [ ] Set up npm package watch for xlsx updates
- [ ] Create alert when xlsx@0.19.3+ becomes available
- [ ] Schedule security review when upgrade is performed
- [ ] Consider alternative packages if patch significantly delayed (>60 days)

## References

- SheetJS GitHub: https://github.com/SheetJS/sheetjs
- npm xlsx package: https://www.npmjs.com/package/xlsx
- Latest available version: 0.18.5 (as of 2026-02-16)

## Version History

- **2026-02-16**: Initial documentation
  - Current xlsx version: 0.18.5
  - Required patched versions not yet available
  - Mitigation measures documented and implemented

---

**Last Updated**: 2026-02-16  
**Next Review**: When xlsx@0.19.3+ becomes available  
**Responsible**: Development Team
