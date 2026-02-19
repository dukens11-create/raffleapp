import 'package:flutter/material.dart';
import '../utils/haiti_departments.dart';

/// A searchable dropdown widget for selecting Haiti departments
/// 
/// Features:
/// - All 10 Haiti departments
/// - Searchable for easy selection
/// - Consistent UI with Material Design 3
/// - Required field validation
class DepartmentSelectorWidget extends StatefulWidget {
  final String? selectedDepartment;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final String? errorText;
  final bool required;

  const DepartmentSelectorWidget({
    super.key,
    this.selectedDepartment,
    required this.onChanged,
    this.labelText = 'Department',
    this.hintText = 'Select your department',
    this.enabled = true,
    this.errorText,
    this.required = false,
  });

  @override
  State<DepartmentSelectorWidget> createState() => _DepartmentSelectorWidgetState();
}

class _DepartmentSelectorWidgetState extends State<DepartmentSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: widget.selectedDepartment,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: widget.selectedDepartment != null && widget.enabled
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => widget.onChanged(null),
              )
            : null,
      ),
      items: HaitiDepartments.all.map((String department) {
        return DropdownMenuItem<String>(
          value: department,
          child: Text(department),
        );
      }).toList(),
      onChanged: widget.enabled ? widget.onChanged : null,
      validator: widget.required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a department';
              }
              return null;
            }
          : null,
      isExpanded: true,
    );
  }
}

/// A searchable dialog for department selection (for better UX on large lists)
class SearchableDepartmentSelector extends StatefulWidget {
  final String? selectedDepartment;
  final ValueChanged<String?> onChanged;

  const SearchableDepartmentSelector({
    super.key,
    this.selectedDepartment,
    required this.onChanged,
  });

  @override
  State<SearchableDepartmentSelector> createState() =>
      _SearchableDepartmentSelectorState();
}

class _SearchableDepartmentSelectorState
    extends State<SearchableDepartmentSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredDepartments = HaitiDepartments.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDepartments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDepartments = HaitiDepartments.all;
      } else {
        _filteredDepartments = HaitiDepartments.all
            .where((dept) =>
                dept.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search departments',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterDepartments,
          ),
        ),
        // Department list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredDepartments.length,
            itemBuilder: (context, index) {
              final department = _filteredDepartments[index];
              final isSelected = department == widget.selectedDepartment;

              return ListTile(
                title: Text(department),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: isSelected,
                onTap: () {
                  widget.onChanged(department);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Helper function to show searchable department picker dialog
Future<String?> showDepartmentPicker(
  BuildContext context, {
  String? selectedDepartment,
}) async {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      String? selected = selectedDepartment;
      return AlertDialog(
        title: const Text('Select Department'),
        content: SizedBox(
          width: double.maxFinite,
          child: SearchableDepartmentSelector(
            selectedDepartment: selectedDepartment,
            onChanged: (value) {
              selected = value;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
