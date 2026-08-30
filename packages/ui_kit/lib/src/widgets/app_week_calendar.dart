import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_kit/src/atoms/app_icon_button.dart';
import 'package:ui_kit/src/atoms/app_surface.dart';
import 'package:ui_kit/src/theme/context_extensions.dart';
import 'package:ui_kit/src/theme/ringo_icons.dart';

/// A compact, token-aware week calendar for selecting a day in a time series.
///
/// The component keeps week navigation local while the selected day remains
/// controlled by its parent. Supply [eventLoader] to show a discreet marker on
/// days with data, such as sleep sessions or workout entries.
class AppWeekCalendar<T> extends StatefulWidget {
  const AppWeekCalendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.focusedDay,
    this.firstDay,
    this.lastDay,
    this.eventLoader,
    this.enabledDayPredicate,
  });

  /// The currently selected calendar day.
  final DateTime selectedDay;

  /// Called after the person selects a day. The second value identifies the
  /// week that should remain visible.
  final OnDaySelected onDaySelected;

  /// The day whose week is initially visible. Defaults to [selectedDay].
  final DateTime? focusedDay;

  /// Inclusive lower bound for navigation. Defaults to five years ago.
  final DateTime? firstDay;

  /// Inclusive upper bound for navigation. Defaults to one year from today.
  final DateTime? lastDay;

  /// Returns records associated with [DateTime] for the data marker.
  final List<T> Function(DateTime day)? eventLoader;

  /// Determines whether a day can be selected.
  final bool Function(DateTime day)? enabledDayPredicate;

  @override
  State<AppWeekCalendar<T>> createState() => _AppWeekCalendarState<T>();
}

class _AppWeekCalendarState<T> extends State<AppWeekCalendar<T>> {
  late DateTime _focusedDay;

  DateTime get _firstDay {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(
      widget.firstDay ?? DateTime(today.year - 5, today.month, today.day),
    );
  }

  DateTime get _lastDay {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(
      widget.lastDay ?? DateTime(today.year + 1, today.month, today.day),
    );
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateUtils.dateOnly(widget.focusedDay ?? widget.selectedDay);
  }

  @override
  void didUpdateWidget(covariant AppWeekCalendar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedDay != oldWidget.focusedDay &&
        widget.focusedDay != null) {
      _focusedDay = DateUtils.dateOnly(widget.focusedDay!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    final typography = context.typography;
    final visibleWeekStart = _startOfWeek(
      _focusedDay,
      MaterialLocalizations.of(context).firstDayOfWeekIndex,
    );
    final canShowPrevious = !_focusedDay
        .subtract(const Duration(days: 7))
        .isBefore(_firstDay);
    final canShowNext = !_focusedDay
        .add(const Duration(days: 7))
        .isAfter(_lastDay);

    return AppSurface(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        tokens.spacing.sm,
        tokens.spacing.md,
        tokens.spacing.md,
      ),
      child: Semantics(
        container: true,
        label: 'Weekly calendar',
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _weekRangeLabel(context, visibleWeekStart),
                    style: typography.titleLg.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
                AppIconButton.ghost(
                  icon: const Icon(RingoIcons.chevron_left),
                  onPressed: canShowPrevious ? () => _changeWeek(-1) : null,
                  tooltip: 'Previous week',
                ),
                SizedBox(width: tokens.spacing.xxs),
                AppIconButton.ghost(
                  icon: const Icon(RingoIcons.chevron_right),
                  onPressed: canShowNext ? () => _changeWeek(1) : null,
                  tooltip: 'Next week',
                ),
              ],
            ),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: TableCalendar<T>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                currentDay: DateUtils.dateOnly(DateTime.now()),
                calendarFormat: CalendarFormat.week,
                availableCalendarFormats: const {CalendarFormat.week: 'Week'},
                headerVisible: false,
                startingDayOfWeek: _startingDayOfWeek(
                  MaterialLocalizations.of(context).firstDayOfWeekIndex,
                ),
                availableGestures: AvailableGestures.horizontalSwipe,
                pageAnimationDuration: tokens.durations.normal,
                pageAnimationCurve: Curves.easeOutCubic,
                rowHeight: 56,
                daysOfWeekHeight: 24,
                selectedDayPredicate: (day) =>
                    DateUtils.isSameDay(day, widget.selectedDay),
                enabledDayPredicate: widget.enabledDayPredicate,
                eventLoader: widget.eventLoader,
                onDaySelected: widget.onDaySelected,
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = DateUtils.dateOnly(focusedDay));
                },
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: typography.caption.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: typography.caption.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  isTodayHighlighted: false,
                  cellMargin: EdgeInsets.zero,
                  cellPadding: EdgeInsets.zero,
                  markersMaxCount: 1,
                  markerSize: 5,
                  markerDecoration: BoxDecoration(
                    color: colors.info,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders<T>(
                  defaultBuilder: (context, day, _) => _DayCell(
                    day: day,
                    isToday: DateUtils.isSameDay(day, DateTime.now()),
                  ),
                  selectedBuilder: (context, day, _) =>
                      _DayCell(day: day, isSelected: true),
                  todayBuilder: (context, day, _) =>
                      _DayCell(day: day, isToday: true),
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final selected = DateUtils.isSameDay(
                      day,
                      widget.selectedDay,
                    );
                    return Positioned(
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primaryForeground
                              : colors.info,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 5, height: 5),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeWeek(int direction) {
    final destination = _focusedDay.add(Duration(days: 7 * direction));
    if (destination.isBefore(_firstDay) || destination.isAfter(_lastDay)) {
      return;
    }
    setState(() => _focusedDay = destination);
  }

  String _weekRangeLabel(BuildContext context, DateTime weekStart) {
    final localizations = MaterialLocalizations.of(context);
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month == weekEnd.month) {
      return localizations.formatMonthYear(weekStart);
    }
    return '${localizations.formatMonthYear(weekStart)} – '
        '${localizations.formatMonthYear(weekEnd)}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.isSelected = false,
    this.isToday = false,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.tokens;
    return Center(
      child: AnimatedContainer(
        duration: tokens.durations.fast,
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: tokens.radius.borderFull,
          border: isToday && !isSelected
              ? Border.all(color: colors.ring, width: tokens.border.thin)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: context.typography.bodySm.copyWith(
            color: isSelected ? colors.primaryForeground : colors.foreground,
            fontWeight: isSelected || isToday
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

DateTime _startOfWeek(DateTime day, int firstDayOfWeekIndex) {
  final normalized = DateUtils.dateOnly(day);
  final offset =
      (normalized.weekday % DateTime.daysPerWeek -
          firstDayOfWeekIndex +
          DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  return normalized.subtract(Duration(days: offset));
}

StartingDayOfWeek _startingDayOfWeek(int firstDayOfWeekIndex) =>
    switch (firstDayOfWeekIndex) {
      DateTime.monday => StartingDayOfWeek.monday,
      DateTime.tuesday => StartingDayOfWeek.tuesday,
      DateTime.wednesday => StartingDayOfWeek.wednesday,
      DateTime.thursday => StartingDayOfWeek.thursday,
      DateTime.friday => StartingDayOfWeek.friday,
      DateTime.saturday => StartingDayOfWeek.saturday,
      _ => StartingDayOfWeek.sunday,
    };
