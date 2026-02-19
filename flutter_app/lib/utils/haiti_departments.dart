/// List of 10 administrative departments of Haiti
/// 
/// Used for user registration, profile management, and statistics tracking
class HaitiDepartments {
  /// List of all 10 Haiti departments in alphabetical order
  static const List<String> all = [
    'Artibonite',
    'Centre',
    'Grand\'Anse',
    'Nippes',
    'Nord',
    'Nord-Est',
    'Nord-Ouest',
    'Ouest',
    'Sud',
    'Sud-Est',
  ];

  /// Get department display name (same as value for Haiti departments)
  static String getDisplayName(String department) {
    return department;
  }

  /// Validate if a department name is valid
  static bool isValid(String department) {
    return all.contains(department);
  }

  /// Get department at index (for dropdown selection)
  static String getAt(int index) {
    if (index < 0 || index >= all.length) {
      return all[0];
    }
    return all[index];
  }

  /// Get index of department (for dropdown selection)
  static int indexOf(String department) {
    return all.indexOf(department);
  }
}
