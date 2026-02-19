# Phase 2 Testing Checklist

## Pre-Testing Setup

- [ ] Ensure backend server is running
- [ ] Verify all API endpoints are available
- [ ] Have test accounts ready:
  - [ ] Admin account
  - [ ] Seller account (approved)
  - [ ] Seller account (pending)
- [ ] Run `flutter pub get` to install dependencies
- [ ] Run `flutter analyze` to check for code issues

## Admin Features Testing

### Statistics Dashboard
- [ ] Login as admin
- [ ] Navigate to Statistics (first menu item)
- [ ] Verify overview cards display correct data:
  - [ ] Total Tickets count
  - [ ] Total Sold count
  - [ ] Total Revenue (in HTG)
  - [ ] Active Raffles count
- [ ] Test category pie chart:
  - [ ] Chart renders without errors
  - [ ] All 6 categories displayed with colors
  - [ ] Percentages add up to 100%
  - [ ] Legend shows correct data
- [ ] Test department bar chart:
  - [ ] Chart renders without errors
  - [ ] Bars display correct heights
  - [ ] Touch tooltips work
  - [ ] Department names visible
- [ ] Test seller leaderboard:
  - [ ] Top sellers displayed
  - [ ] Rankings correct (1, 2, 3, etc.)
  - [ ] Medal colors for top 3
  - [ ] Revenue and commission displayed
- [ ] Test pull-to-refresh:
  - [ ] Swipe down refreshes data
  - [ ] Loading indicator appears
  - [ ] Data updates after refresh
- [ ] Test error handling:
  - [ ] Disconnect network
  - [ ] Verify error message displays
  - [ ] Retry button works

### Seller Management
- [ ] Navigate to Sellers (menu item)
- [ ] Verify seller list displays:
  - [ ] All sellers shown
  - [ ] Names, phones visible
  - [ ] Status badges correct
  - [ ] Sales and commission displayed
- [ ] Test status filter:
  - [ ] Filter by "All Sellers"
  - [ ] Filter by "Approved"
  - [ ] Filter by "Pending"
  - [ ] Filter by "Rejected"
- [ ] Test seller details:
  - [ ] Tap on a seller
  - [ ] Details screen opens
  - [ ] All information correct
  - [ ] Performance cards display
- [ ] Test pull-to-refresh on seller list

### Seller Details
- [ ] Open seller details
- [ ] Verify all fields:
  - [ ] Name, phone, email
  - [ ] Department
  - [ ] Registration date
  - [ ] Status badge
- [ ] Verify statistics:
  - [ ] Total Sales
  - [ ] Commission Earned
  - [ ] Active Tickets
  - [ ] Total Revenue (if stats available)
- [ ] Test actions menu:
  - [ ] Edit option available
  - [ ] Delete option available
- [ ] For pending sellers:
  - [ ] Approve button visible
  - [ ] Reject button visible
  - [ ] Test approve action:
    - [ ] Confirmation dialog appears
    - [ ] Cancel works
    - [ ] Approve completes
    - [ ] Success message shown
    - [ ] Navigate back to list
  - [ ] Test reject action:
    - [ ] Reason dialog appears
    - [ ] Requires reason text
    - [ ] Reject completes
    - [ ] Success message shown
- [ ] Test delete action:
  - [ ] Confirmation dialog appears
  - [ ] Warning message shown
  - [ ] Delete completes
  - [ ] Navigate back to list

### Seller Approvals
- [ ] Navigate to Approvals
- [ ] Verify pending requests displayed
- [ ] Test empty state (if no pending):
  - [ ] Green checkmark icon
  - [ ] "No pending requests" message
- [ ] For each pending request:
  - [ ] Name and details visible
  - [ ] Registration date shown
  - [ ] Tap opens details screen
  - [ ] Reject button works:
    - [ ] Opens reason dialog
    - [ ] Requires reason
    - [ ] Rejects successfully
    - [ ] Request removed from list
  - [ ] Approve button works:
    - [ ] Shows confirmation
    - [ ] Approves successfully
    - [ ] Request removed from list
- [ ] Test pull-to-refresh
- [ ] Verify list updates after actions

## Seller Features Testing

### Seller Statistics
- [ ] Login as seller
- [ ] Navigate to Stats tab
- [ ] Tap "View Statistics" button
- [ ] Verify overview cards:
  - [ ] Total Sales count
  - [ ] Revenue in HTG
  - [ ] Commission in HTG
  - [ ] Active Tickets count
- [ ] Test sales by category:
  - [ ] Each category listed
  - [ ] Ticket counts correct
  - [ ] Revenue amounts correct
  - [ ] Category colors match
- [ ] Test daily sales:
  - [ ] Recent 7 days shown
  - [ ] Dates formatted correctly
  - [ ] Counts and revenue correct
- [ ] Test pull-to-refresh
- [ ] Test error handling

### Sales History
- [ ] Navigate to Sales tab
- [ ] Tap "View Sales" button
- [ ] Verify sales list:
  - [ ] All sales displayed
  - [ ] Ticket numbers shown
  - [ ] Category displayed
  - [ ] Buyer name shown
  - [ ] Sale date/time formatted
  - [ ] Price in HTG
  - [ ] Commission displayed
- [ ] Test empty state (if no sales):
  - [ ] Icon displayed
  - [ ] "No sales yet" message
- [ ] Test pull-to-refresh
- [ ] Test scrolling with many sales

### Commission Details
- [ ] Navigate to Commission tab
- [ ] Tap "View Commission" button
- [ ] Verify total commission card:
  - [ ] Large display
  - [ ] Correct amount in HTG
  - [ ] Green theme
- [ ] Verify details cards:
  - [ ] Commission rate percentage
  - [ ] Total sales count
  - [ ] Total revenue in HTG
- [ ] If pending payment exists:
  - [ ] Pending payment card shown
  - [ ] Amount displayed
  - [ ] Orange theme
  - [ ] Explanation text
- [ ] Test pull-to-refresh

### Seller Dashboard
- [ ] Check dashboard overview:
  - [ ] Quick stats cards
  - [ ] Sales, Revenue, Available, Commission
- [ ] Test bottom navigation:
  - [ ] Dashboard tab
  - [ ] My Tickets tab
  - [ ] Sales tab navigation
  - [ ] Stats tab navigation
  - [ ] Commission tab navigation
- [ ] Verify each tab opens correct screen

## Navigation Testing

### Admin Navigation
- [ ] Test drawer menu:
  - [ ] Opens smoothly
  - [ ] All items clickable
  - [ ] Selected item highlighted
  - [ ] Closes after selection
- [ ] Test back navigation:
  - [ ] Back button works on all screens
  - [ ] Returns to correct parent
- [ ] Test deep linking (if applicable):
  - [ ] `/admin/statistics` works
  - [ ] `/admin/sellers` works
  - [ ] `/admin/sellers/approval` works

### Seller Navigation
- [ ] Test bottom tabs:
  - [ ] All tabs clickable
  - [ ] Selected tab highlighted
  - [ ] Content changes correctly
- [ ] Test nested navigation:
  - [ ] From tab to detail screen
  - [ ] Back button returns to tab
- [ ] Test deep linking (if applicable):
  - [ ] `/seller/sales` works
  - [ ] `/seller/stats` works
  - [ ] `/seller/commission` works

## Integration Testing

### Role-Based Access
- [ ] Admin can access:
  - [ ] Statistics
  - [ ] Seller management
  - [ ] Seller approvals
- [ ] Admin cannot access:
  - [ ] Seller-only features
- [ ] Seller can access:
  - [ ] Own statistics
  - [ ] Own sales
  - [ ] Own commission
- [ ] Seller cannot access:
  - [ ] Admin features
  - [ ] Other sellers' data

### Data Consistency
- [ ] Statistics match backend data
- [ ] Charts display correct values
- [ ] Seller counts accurate
- [ ] Commission calculations correct
- [ ] Sales history complete

### Error Scenarios
- [ ] Network timeout handling
- [ ] 401 Unauthorized handling
- [ ] 404 Not Found handling
- [ ] 500 Server Error handling
- [ ] Invalid data handling
- [ ] Empty response handling

## Performance Testing

### Load Times
- [ ] Statistics screen loads < 2 seconds
- [ ] Seller list loads < 2 seconds
- [ ] Charts render smoothly
- [ ] No janky animations

### Memory Usage
- [ ] No memory leaks on navigation
- [ ] Images disposed properly
- [ ] Providers cleaned up

### Responsiveness
- [ ] Works on different screen sizes
- [ ] Tablets display correctly
- [ ] Landscape mode works
- [ ] Small screens readable

## Accessibility Testing

- [ ] All buttons have semantic labels
- [ ] Images have descriptions
- [ ] Colors have sufficient contrast
- [ ] Touch targets are 48x48dp minimum
- [ ] Screen reader compatible

## Edge Cases

### Empty States
- [ ] No statistics data
- [ ] No sellers
- [ ] No pending approvals
- [ ] No sales history
- [ ] No commission

### Boundary Values
- [ ] Very large numbers (revenue)
- [ ] Zero values
- [ ] Negative values (if any)
- [ ] Very long names
- [ ] Special characters in text

### Concurrent Actions
- [ ] Multiple refreshes
- [ ] Rapid navigation
- [ ] Approve while viewing details
- [ ] Network changes during load

## Bug Tracking

### Issues Found
Record any issues discovered:
1. 
2. 
3. 

### Resolved Issues
Track fixes:
1. 
2. 
3. 

## Sign-Off

- [ ] All critical features tested
- [ ] No blocking bugs
- [ ] Performance acceptable
- [ ] Ready for production
- [ ] Documentation complete

**Tester:** _______________  
**Date:** _______________  
**Signature:** _______________
