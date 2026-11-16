import 'package:flutter/material.dart';

import '../services/public_holiday_service.dart';

class SwipeableWeekCalendarWidget extends StatefulWidget {
  const SwipeableWeekCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventText = 'No upcoming events.',
    this.holidays = const [],
    this.holidaysOffline = false,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String eventText;
  final List<PublicHoliday> holidays;
  final bool holidaysOffline;

  static const Color maroonColor = Color(0xFF800000);

  @override
  State<SwipeableWeekCalendarWidget> createState() =>
      _SwipeableWeekCalendarWidgetState();
}

class _SwipeableWeekCalendarWidgetState
    extends State<SwipeableWeekCalendarWidget> {
  static const int _initialPage = 5000;
  late final PageController _pageController;
  late DateTime _referenceMonday;
  late DateTime _currentDisplayedMonth;

  @override
  void initState() {
    super.initState();
    // Anchor reference Monday to the Monday of widget.selectedDate
    _referenceMonday = _findMonday(widget.selectedDate);
    _currentDisplayedMonth = widget.selectedDate;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant SwipeableWeekCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _currentDisplayedMonth = widget.selectedDate;
      final newMonday = _findMonday(widget.selectedDate);
      final differenceInDays = newMonday.difference(_referenceMonday).inDays;
      final targetPage = _initialPage + (differenceInDays / 7).round();
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetPage) {
        _pageController.jumpToPage(targetPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _findMonday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getMondayForPage(int page) {
    final weekOffset = page - _initialPage;
    return _referenceMonday.add(Duration(days: weekOffset * 7));
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _weekdayAbbreviation(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  Future<void> _openMonthYearPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final appTheme = Theme.of(context);
        final isDark = appTheme.brightness == Brightness.dark;
        return Theme(
          data: appTheme.copyWith(
            colorScheme: appTheme.colorScheme.copyWith(
              primary: isDark
                  ? const Color(0xFFE0B0B0)
                  : SwipeableWeekCalendarWidget.maroonColor,
              onPrimary: isDark ? const Color(0xFF171717) : Colors.white,
              onSurface: appTheme.colorScheme.onSurface,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      widget.onDateSelected(picked);
      final targetMonday = _findMonday(picked);
      final offset = (targetMonday.difference(_referenceMonday).inDays / 7)
          .round();
      final targetPage = _initialPage + offset;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      setState(() {
        _currentDisplayedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayedTitle =
        '${_monthName(_currentDisplayedMonth.month)} ${_currentDisplayedMonth.year}';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month/Year Picker Button Header
          InkWell(
            onTap: _openMonthYearPicker,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayedTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFE0B0B0)
                        : const Color(0xFF800000),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Swipeable Week View (PageView)
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                final monday = _getMondayForPage(page);
                final nextSelectedDate = monday.add(
                  Duration(days: widget.selectedDate.weekday - 1),
                );
                setState(() {
                  _currentDisplayedMonth = nextSelectedDate;
                });
                widget.onDateSelected(nextSelectedDate);
              },
              itemBuilder: (context, page) {
                final monday = _getMondayForPage(page);
                final days = List.generate(
                  7,
                  (i) => monday.add(Duration(days: i)),
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: days.map((day) {
                    final hasHoliday = widget.holidays.any(
                      (holiday) => DateUtils.isSameDay(holiday.date, day),
                    );
                    final isSelected =
                        day.year == widget.selectedDate.year &&
                        day.month == widget.selectedDate.month &&
                        day.day == widget.selectedDate.day;

                    return GestureDetector(
                      onTap: () {
                        widget.onDateSelected(day);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _weekdayAbbreviation(day.weekday),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? const Color(0xFFE0B0B0)
                                        : SwipeableWeekCalendarWidget
                                              .maroonColor)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (isDark
                                          ? const Color(0xFF171717)
                                          : Colors.white)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: hasHoliday
                                  ? (isSelected
                                        ? theme.colorScheme.onPrimary
                                        : SwipeableWeekCalendarWidget
                                              .maroonColor)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _buildSelectedDateEvents(theme),
        ],
      ),
    );
  }

  Widget _buildSelectedDateEvents(ThemeData theme) {
    final selectedHolidays = widget.holidays
        .where(
          (holiday) => DateUtils.isSameDay(holiday.date, widget.selectedDate),
        )
        .toList();
    if (selectedHolidays.isNotEmpty) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: selectedHolidays
            .map(
              (holiday) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9EAEA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.celebration_outlined,
                      size: 14,
                      color: SwipeableWeekCalendarWidget.maroonColor,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        holiday.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SwipeableWeekCalendarWidget.maroonColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    final message = widget.holidaysOffline
        ? widget.holidays.isEmpty
              ? 'Holiday dates are unavailable offline. Reconnect to sync.'
              : 'Offline · Showing saved Nager.Date holidays.'
        : widget.eventText;
    return Text(
      message,
      style: TextStyle(
        fontSize: 11,
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
