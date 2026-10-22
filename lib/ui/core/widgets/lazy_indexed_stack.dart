import 'package:flutter/widgets.dart';

/// An [IndexedStack] that builds a child only after it is first selected.
///
/// Screens in the shell own their view models and start network reads as soon
/// as they are built. Building every destination up front made the whole app
/// load data on launch; this keeps the state of visited tabs while deferring
/// the initial load of the others.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  List<bool> _built = const [];

  @override
  void initState() {
    super.initState();
    _built = List<bool>.filled(widget.children.length, false);
    _markBuilt(widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _built = List<bool>.filled(widget.children.length, false);
    }
    _markBuilt(widget.index);
  }

  void _markBuilt(int index) {
    if (index >= 0 && index < _built.length) {
      _built[index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          if (_built[index])
            widget.children[index]
          else
            const SizedBox.shrink(),
      ],
    );
  }
}
