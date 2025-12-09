import 'package:flutter/material.dart';

class PriceRangeFilterWidget extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final Function(double min, double max) onApply;

  const PriceRangeFilterWidget({
    Key? key,
    this.minPrice = 0,
    this.maxPrice = 100000,
    required this.onApply,
  }) : super(key: key);

  @override
  State<PriceRangeFilterWidget> createState() => _PriceRangeFilterWidgetState();
}

class _PriceRangeFilterWidgetState extends State<PriceRangeFilterWidget> {
  late RangeValues _currentRange;
  late double _min;
  late double _max;

  @override
  void initState() {
    super.initState();
    _min = widget.minPrice;
    _max = widget.maxPrice;
    _currentRange = RangeValues(_min, _max);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fiyat Aralığı',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fiyat gösterimi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceCard('Min', _currentRange.start),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              _buildPriceCard('Max', _currentRange.end),
            ],
          ),
          const SizedBox(height: 20),

          // Slider
          RangeSlider(
            values: _currentRange,
            min: 0,
            max: _max,
            divisions: 100,
            labels: RangeLabels(
              '${_currentRange.start.toStringAsFixed(0)} ₺',
              '${_currentRange.end.toStringAsFixed(0)} ₺',
            ),
            onChanged: (RangeValues values) {
              setState(() => _currentRange = values);
            },
          ),

          // Hızlı seçenekler
          const SizedBox(height: 16),
          const Text(
            'Hızlı Seçim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickOption('0 - 1000', 0, 1000),
              _buildQuickOption('1K - 5K', 1000, 5000),
              _buildQuickOption('5K - 10K', 5000, 10000),
              _buildQuickOption('10K+', 10000, _max),
            ],
          ),
          const SizedBox(height: 24),

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentRange = RangeValues(0, _max);
                    });
                  },
                  child: const Text('Temizle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_currentRange.start, _currentRange.end);
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)} ₺',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(String label, double min, double max) {
    final isSelected = _currentRange.start == min && _currentRange.end == max;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _currentRange = RangeValues(min, max));
        }
      },
    );
  }
}

// Helper function - Kolayca açmak için
void showPriceRangeFilter(
  BuildContext context, {
  double minPrice = 0,
  double maxPrice = 100000,
  required Function(double min, double max) onApply,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PriceRangeFilterWidget(
      minPrice: minPrice,
      maxPrice: maxPrice,
      onApply: onApply,
    ),
  );
}
