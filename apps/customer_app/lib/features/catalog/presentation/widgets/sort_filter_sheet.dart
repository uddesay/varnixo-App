import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';

const List<(String, String)> _sortOptions = [
  ('newest', 'Newest'),
  ('price_asc', 'Price: Low to High'),
  ('price_desc', 'Price: High to Low'),
  ('rating', 'Customer Rating'),
  ('popularity', 'Popularity'),
];

/// Bottom sheet for sort + basic price/rating filters, shared by category
/// browsing and search results.
class SortFilterSheet extends StatefulWidget {
  const SortFilterSheet({
    required this.currentSort,
    required this.onApply,
    super.key,
    this.currentPriceMin,
    this.currentPriceMax,
    this.currentRating,
  });

  final String currentSort;
  final int? currentPriceMin;
  final int? currentPriceMax;
  final double? currentRating;
  final void Function(String sort, int? priceMin, int? priceMax, double? rating) onApply;

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  late String _sort = widget.currentSort;
  late RangeValues _priceRange = RangeValues(
    (widget.currentPriceMin ?? 0) / 100,
    (widget.currentPriceMax ?? 500000) / 100,
  );
  late double? _rating = widget.currentRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort & Filter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Sort by', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option.$2),
                    selected: _sort == option.$1,
                    onSelected: (_) => setState(() => _sort = option.$1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Price range (₹)', style: Theme.of(context).textTheme.labelLarge),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500000,
            divisions: 50,
            labels: RangeLabels(
              '₹${_priceRange.start.round()}',
              '₹${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 12),
          Text('Minimum rating', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [4.0, 3.0, 2.0].map((value) {
              return ChoiceChip(
                label: Text('$value+ ★'),
                selected: _rating == value,
                onSelected: (_) => setState(() => _rating = _rating == value ? null : value),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Apply',
            onPressed: () {
              widget.onApply(
                _sort,
                (_priceRange.start * 100).round(),
                (_priceRange.end * 100).round(),
                _rating,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
