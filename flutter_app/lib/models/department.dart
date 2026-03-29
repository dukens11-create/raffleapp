class Department {
  final String code;
  final String name;
  final String nameKreyol;

  Department({
    required this.code,
    required this.name,
    required this.nameKreyol,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: json['code'] as String,
      name: json['name'] as String,
      nameKreyol: json['name_kreyol'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'name_kreyol': nameKreyol,
    };
  }

  @override
  String toString() => name;
}

// Haiti departments list (alphabetically ordered)
class HaitiDepartments {
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

  static Department? findByCode(String code) {
    try {
      return all.firstWhere((dept) => dept.code == code);
    } catch (e) {
      return null;
    }
  }

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
}
