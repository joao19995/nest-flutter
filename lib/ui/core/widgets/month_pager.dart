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

/// A horizontally swipeable, effectively unbounded pager of months.
///
/// Each page is built for a shifted `YYYY-MM` key and receives the callbacks
/// that animate the pager one month back or forward, so a month screen can
/// drive its own period stepper.
class MonthPager extends StatefulWidget {
  const MonthPager({
    super.key,
    required this.title,
    required this.month,
    required this.pageBuilder,
  });

  /// The app bar title.
  final String title;

  /// The month of the anchor page, formatted `YYYY-MM`.
  final String month;

  final MonthPageBuilder pageBuilder;

  @override
  State<MonthPager> createState() => _MonthPagerState();
}

class _MonthPagerState extends State<MonthPager> {
  /// The page whose month is [MonthPager.month]. Pages shift from here, so the
  /// carousel is effectively unbounded.
  static const int _anchor = 1000;

  late final PageController _controller = PageController(initialPage: _anchor);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateBy(int delta) {
    if (!_controller.hasClients) {
      return;
    }
    final current = _controller.page?.round() ?? _anchor;
    _controller.animateToPage(
      current + delta,
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
                MonthKey.shift(widget.month, index - _anchor),
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
