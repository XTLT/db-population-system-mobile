import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/relation_list.dart';
import 'person_form_data.dart';

/// 人员编辑页的通用表单组件。
///
/// 从 `person_edit_page.dart` 抽出来：只负责布局与交互外观，
/// 不持有业务状态，传入什么就渲染什么。
class PersonFormWidgets {
  const PersonFormWidgets._();

  static Widget section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  static Widget textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
          filled: !enabled,
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }

  static Widget dropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty == true ? null : value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        menuMaxHeight: 300,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item.isEmpty ? null : item,
            child: Text(item.isEmpty ? '请选择' : item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// 与户主关系：标准下拉；存量不在标准列表的旧值自动并入选项，避免丢失。
  static Widget relationDropdown({
    required String current,
    required void Function(String?) onChanged,
  }) {
    final items = <String>[...kRelations];
    if (current.isNotEmpty && !items.contains(current)) {
      items.insert(0, current);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: current.isEmpty ? null : current,
        decoration: const InputDecoration(
          labelText: '与户主关系',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final r in items) DropdownMenuItem(value: r, child: Text(r)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  static Widget gradeDropdown({
    required String? value,
    required void Function(String?) onChanged,
  }) {
    final normalized = value != null && value.isEmpty ? null : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: normalized,
        menuMaxHeight: 300,
        decoration: const InputDecoration(
          labelText: '年级',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('请选择')),
          ...kGradeOptions.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
