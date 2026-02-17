import '../models/department.dart';

class DepartmentService {
  /// Get all Haiti departments
  List<Department> getAllDepartments() {
    return HaitiDepartments.all;
  }

  /// Find department by code
  Department? getDepartmentByCode(String code) {
    return HaitiDepartments.findByCode(code);
  }

  /// Find department by name (French or Kreyòl)
  Department? getDepartmentByName(String name) {
    return HaitiDepartments.findByName(name);
  }

  /// Get department names for dropdown
  List<String> getDepartmentNames({bool useKreyol = false}) {
    return HaitiDepartments.all
        .map((dept) => useKreyol ? dept.nameKreyol : dept.name)
        .toList();
  }

  /// Get department codes
  List<String> getDepartmentCodes() {
    return HaitiDepartments.all.map((dept) => dept.code).toList();
  }
}
