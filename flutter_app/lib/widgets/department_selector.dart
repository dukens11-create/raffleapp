import 'package:flutter/material.dart';
import '../models/department.dart';
import '../services/department_service.dart';

class DepartmentSelector extends StatefulWidget {
  final String? selectedDepartment;
  final Function(Department?) onDepartmentChanged;
  final bool useKreyol;
  final String? label;
  final String? hint;
  final bool required;

  const DepartmentSelector({
    super.key,
    this.selectedDepartment,
    required this.onDepartmentChanged,
    this.useKreyol = false,
    this.label,
    this.hint,
    this.required = false,
  });

  @override
  State<DepartmentSelector> createState() => _DepartmentSelectorState();
}

class _DepartmentSelectorState extends State<DepartmentSelector> {
  final DepartmentService _departmentService = DepartmentService();
  Department? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDepartment != null) {
      _selectedDepartment = _departmentService.getDepartmentByCode(widget.selectedDepartment!) ??
                           _departmentService.getDepartmentByName(widget.selectedDepartment!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = _departmentService.getAllDepartments();

    return DropdownButtonFormField<Department>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        labelText: widget.label ?? (widget.useKreyol ? 'Depatman' : 'Département'),
        hintText: widget.hint ?? (widget.useKreyol ? 'Chwazi depatman' : 'Sélectionnez un département'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.location_on),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: departments.map((department) {
        return DropdownMenuItem<Department>(
          value: department,
          child: Text(
            widget.useKreyol ? department.nameKreyol : department.name,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (Department? newValue) {
        setState(() {
          _selectedDepartment = newValue;
        });
        widget.onDepartmentChanged(newValue);
      },
      validator: widget.required
          ? (value) {
              if (value == null) {
                return widget.useKreyol 
                    ? 'Tanpri chwazi yon depatman'
                    : 'Veuillez sélectionner un département';
              }
              return null;
            }
          : null,
    );
  }
}

/// Simple department dropdown without FormField
class DepartmentDropdown extends StatelessWidget {
  final String? selectedCode;
  final Function(String?) onChanged;
  final bool useKreyol;

  const DepartmentDropdown({
    super.key,
    this.selectedCode,
    required this.onChanged,
    this.useKreyol = false,
  });

  @override
  Widget build(BuildContext context) {
    final departments = HaitiDepartments.all;

    return DropdownButton<String>(
      value: selectedCode,
      hint: Text(useKreyol ? 'Chwazi depatman' : 'Sélectionnez'),
      isExpanded: true,
      items: departments.map((dept) {
        return DropdownMenuItem<String>(
          value: dept.code,
          child: Text(useKreyol ? dept.nameKreyol : dept.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
