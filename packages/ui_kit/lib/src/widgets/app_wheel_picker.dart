import 'package:flutter/material.dart';
import 'package:ui_kit/src/theme/context_extensions.dart';

/// A token-driven wheel control for choosing one item from a short or long list.
///
/// The centred item is framed by a high-contrast selection band and receives
/// stronger type treatment, keeping the active choice clear while the wheel is
/// in motion. Use [onSelectedItemChanged] to keep the owning screen's pending
/// value in sync.
class AppWheelPicker<T> extends StatefulWidget {
  const AppWheelPicker({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.onSelectedItemChanged,
    this.initialItem = 0,
    this.semanticsLabel,
    this.itemExtent = 52,
    this.visibleItemCount = 3,
  }) : assert(items.length > 0, 'items must not be empty'),
       assert(initialItem >= 0 && initialItem < items.length),
       assert(visibleItemCount > 0 && visibleItemCount % 2 == 1);

  /// Values represented by the wheel, in display order.
  final List<T> items;

  /// Converts an item to its visible and accessible label.
  final String Function(T item) itemLabel;

  /// Called whenever the centred item changes.
  final ValueChanged<T> onSelectedItemChanged;

  /// The initially centred item index.
  final int initialItem;

  /// Optional accessible name for the control, such as "Height picker".
  final String? semanticsLabel;

  /// Height of each wheel row. Defaults to the design-system xxl rhythm.
  final double itemExtent;

  /// Number of visible rows. Must be odd so one row can remain centred.
  final int visibleItemCount;

  @override
  State<AppWheelPicker<T>> createState() => _AppWheelPickerState<T>();
}

class _AppWheelPickerState<T> extends State<AppWheelPicker<T>> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialItem;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant AppWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItem != oldWidget.initialItem) {
      _selectedIndex = widget.initialItem;
      _controller.jumpToItem(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
    widget.onSelectedItemChanged(widget.items[index]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final height = widget.itemExtent * widget.visibleItemCount;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : tokens.durations.fast;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.itemLabel(widget.items[_selectedIndex]),
      child: SizedBox(
        height: height,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: widget.itemExtent,
          perspective: 0.003,
          useMagnifier: true,
          magnification: 1.04,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: _select,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.items.length,
            builder: (context, index) {
              final isSelected = index == _selectedIndex;
              return AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeOut,
                height: widget.itemExtent,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: tokens.spacing.xs),
                alignment: Alignment.center,
                decoration: isSelected
                    ? BoxDecoration(color: colors.muted, borderRadius: tokens.radius.borderMd)
                    : null,
                child: AnimatedDefaultTextStyle(
                  duration: animationDuration,
                  curve: Curves.easeOut,
                  style: (isSelected ? context.typography.headingSm : context.typography.titleLg)
                      .copyWith(
                        color: isSelected ? colors.foreground : colors.mutedForeground,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: isSelected ? 1 : 0.56,
                    child: Text(widget.itemLabel(widget.items[index])),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
