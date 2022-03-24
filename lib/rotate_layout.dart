import 'dart:math';

import 'package:flutter/widgets.dart';

/// Rotates the layout at right angles, but while also rebuilding the layout to
/// fill the available space.
///
/// Problem: Given a 100x50 space, if we rotate the child filling it by 90 deg,
/// we would obtain a 50x100 child sitting in a 100x50 parent, causing it to
/// overflow top-bottom and not fill the parent left-right.
///
/// Solution: This widget rotates the given child, but also gives it constraits
/// such that it fills the parent while rotated. In the above example, the child
/// is rotated, but it still maintains a 100x50 size, perfectly matching the
/// parent.
class RotateLayoutBy90 extends StatelessWidget {
  final SquareRotation rotation;
  final Widget child;

  const RotateLayoutBy90(
      {Key? key, required this.rotation, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          switch (rotation) {
            case SquareRotation.left:
              return Transform.rotate(
                angle: -pi / 2,
                child: OverflowBox(
                  minWidth: height,
                  maxWidth: height,
                  minHeight: width,
                  maxHeight: width,
                  child: child,
                ),
              );
              break;
            case SquareRotation.right:
              return Transform.rotate(
                angle: pi / 2,
                child: OverflowBox(
                  minWidth: height,
                  maxWidth: height,
                  minHeight: width,
                  maxHeight: width,
                  child: child,
                ),
              );
              break;
            case SquareRotation.normal:
              return child;
              break;
            case SquareRotation.upsideDown:
              return Transform.rotate(
                angle: pi,
                child: child,
              );
              break;
          }
        });
  }
}

enum SquareRotation { left, right, normal, upsideDown }