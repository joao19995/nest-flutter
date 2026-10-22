import 'package:flutter/material.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Builds one page of a [MonthPager].
typedef MonthPageBuilder =
    Widget Function(
      BuildContext context,
      String month,
      VoidCallback onPreviousMonth,
      VoidCallback onNextMonth,
    );

/// A horizontally swipeable pager of months, bounded to a supported range.
///
/// Each page is built for its `YYYY-MM` key and receives the callbacks that
/// move the pager one month back or forward, so a month screen can drive its
/// own period stepper.
class MonthPager extends StatefulWidget {
  const MonthPager({
    super.key,
    required this.title,
    required this.month,
    required this.pageBuilder,
    this.firstMonth = '2000-01',
    this.lastMonth,
  });

  /// The app bar title.
  final String title;

  /// The month of the initial page, formatted `YYYY-MM`.
  final String month;

  final MonthPageBuilder pageBuilder;

  /// The earliest reachable month.
  final String firstMonth;

  /// The latest reachable month; defaults to December of next year.
  final String? lastMonth;

  @override
  State<MonthPager> createState() => _MonthPagerState();
}

class _MonthPagerState extends State<MonthPager> {
  late final String _lastMonth;
  late final int _pageCount;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _lastMonth =
        widget.lastMonth ??
        MonthKey.of(DateTime.now().year + 1, DateTime.december);
    _pageCount = MonthKey.monthsBetween(widget.firstMonth, _lastMonth) + 1;
    final initialPage = MonthKey.monthsBetween(
      widget.firstMonth,
      widget.month,
    ).clamp(0, _pageCount - 1).toInt();
    _controller = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateBy(int delta) {
    if (!_controller.hasClients) {
      return;
    }
    final current = _controller.page?.round() ?? 0;
    final target = current + delta;
    if (target < 0 || target >= _pageCount) {
      return;
    }
    _controller.animateToPage(
      target,
      duration: AppMotion.dialog,
      curve: AppMotion.easing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PageView.builder(
        controller: _controller,
        itemCount: _pageCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: widget.pageBuilder(
                context,
                MonthKey.shift(widget.firstMonth, index),
                () => _animateBy(-1),
                () => _animateBy(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
