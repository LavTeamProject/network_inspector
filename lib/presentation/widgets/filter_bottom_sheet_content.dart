import 'package:flutter/material.dart';

import '../../const/network_inspector_value.dart';
import '../controllers/activity_filter_provider.dart';
import 'container_label.dart';

class FilterBottomSheetContent extends StatefulWidget {
  final Map<int?, int> responseStatusCodes;
  final Map<String, int> baseUrls;
  final Map<String, int> paths;
  final Map<String, int> methods;
  final Function(
      List<int?> statusCodes,
      List<String> baseUrls,
      List<String> paths,
      List<String> methods,
      ) onTapApplyFilter;
  final ActivityFilterProvider provider;

  const FilterBottomSheetContent({
    super.key,
    required this.responseStatusCodes,
    required this.baseUrls,
    required this.paths,
    required this.methods,
    required this.onTapApplyFilter,
    required this.provider,
  });

  @override
  State<FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<FilterBottomSheetContent> {
  late ActivityFilterProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;

    // Добавляем слушатель для обновления UI
    _provider.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _provider.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Code Filter
                _buildChipFilterSection(
                  title: 'Status Code',
                  items: widget.responseStatusCodes,
                  isSelected: (key) => _provider.selectedStatusCodes.contains(key),
                  onTap: (key) => _provider.onChangeSelectedStatusCode(key),
                  chipBuilder: (key) => _buildStatusCodeChip(
                    context,
                    key,
                    _provider.selectedStatusCodes.contains(key),
                  ),
                  countBuilder: (key) => '(${widget.responseStatusCodes[key]})',
                ),

                const SizedBox(height: 24),

                // Method Filter - с чипами
                _buildChipFilterSection(
                  title: 'Method',
                  items: widget.methods,
                  isSelected: (key) => _provider.selectedMethods.contains(key),
                  onTap: (key) => _provider.onChangeSelectedMethod(key),
                  chipBuilder: (key) => _buildMethodChip(
                    context,
                    key,
                    _provider.selectedMethods.contains(key),
                    widget.methods[key] ?? 0,
                  ),
                  countBuilder: (key) => '(${widget.methods[key]})',
                ),

                const SizedBox(height: 24),

                // Base URL Filter - оставляем как есть (чекбоксы)
                _buildCheckboxFilterSection(
                  title: 'Base URL',
                  items: widget.baseUrls,
                  isChecked: (key) => _provider.selectedBaseUrls.contains(key),
                  onChanged: (key) => _provider.onChangeSelectedBaseUrl(key),
                  labelBuilder: (key) => Text(
                    key,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  countBuilder: (key) => '(${widget.baseUrls[key]})',
                ),

                const SizedBox(height: 24),

                // Path Filter - оставляем как есть (чекбоксы)
                _buildCheckboxFilterSection(
                  title: 'Path',
                  items: widget.paths,
                  isChecked: (key) => _provider.selectedPaths.contains(key),
                  onChanged: (key) => _provider.onChangeSelectedPath(key),
                  labelBuilder: (key) => Text(
                    key,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  countBuilder: (key) => '(${widget.paths[key]})',
                ),
              ],
            ),
          ),
        ),

        // Buttons Row
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              // Clear Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _provider.hasActiveFilters
                      ? () {
                    _provider.clearAllFilters();
                  }
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Clear All',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _provider.hasActiveFilters
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Apply Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onTapApplyFilter(
                      _provider.selectedStatusCodes,
                      _provider.selectedBaseUrls,
                      _provider.selectedPaths,
                      _provider.selectedMethods,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    'Apply Filter',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Виджет для фильтров с чипами (Status Code и Method)
  Widget _buildChipFilterSection<T>({
    required String title,
    required Map<T, int> items,
    required bool Function(T) isSelected,
    required Function(T) onTap,
    required Widget Function(T) chipBuilder,
    required String Function(T) countBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.keys.map((key) {
            return GestureDetector(
              onTap: () => onTap(key),
              child: chipBuilder(key),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Виджет для фильтров с чекбоксами (Base URL и Path)
  Widget _buildCheckboxFilterSection<T>({
    required String title,
    required Map<T, int> items,
    required bool Function(T) isChecked,
    required Function(T) onChanged,
    required Widget Function(T) labelBuilder,
    required String Function(T) countBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final key = items.keys.elementAt(index);
            return CheckboxListTile(
              value: isChecked(key),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              title: Row(
                children: [
                  Expanded(child: labelBuilder(key)),
                  const SizedBox(width: 8),
                  Text(
                    countBuilder(key),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onChanged: (_) => onChanged(key),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCodeChip(BuildContext context, int? statusCode, bool isSelected) {
    final text = statusCode != null ? '$statusCode' : 'N/A';
    final count = widget.responseStatusCodes[statusCode] ?? 0;

    return Chip(
      padding: EdgeInsets.all(0),
      // labelPadding: EdgeInsets.zero,
      label: ContainerLabel(
        text: text,
        color: isSelected
            ? NetworkInspectorValue.containerColor(statusCode ?? 0)
            : Colors.grey.shade300,
        textColor: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      backgroundColor: isSelected
          ? NetworkInspectorValue.containerColor(statusCode ?? 0)
          : Colors.grey.shade300,
      side: BorderSide.none, // Полное удаление границы
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

    );
  }

  // Чип для метода
  Widget _buildMethodChip(BuildContext context, String method, bool isSelected, int count) {
    Color getMethodColor(String method) {
      switch (method.toUpperCase()) {
        case 'GET':
          return Colors.blue;
        case 'POST':
          return Colors.green;
        case 'PUT':
          return Colors.orange;
        case 'DELETE':
          return Colors.red;
        case 'PATCH':
          return Colors.purple;
        default:
          return Colors.grey;
      }
    }

    final color = getMethodColor(method);

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            method,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
      backgroundColor: isSelected ? color : Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: 1,
      ),
    );
  }
}