import 'package:boatfight/half_opened_orientation.dart';
import 'package:boatfight/rotate_layout.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/widgets.dart';

/// Uses rotation and TwoPane parameters to ensure that [topPane] is *always*
/// on the top screen when the device is in the half-opened posture. This works
/// even if the device is in landscape or portrait and rotations are made to
/// account for them.
class BuoyantTwoPane extends StatelessWidget {
  final Widget topPane, bottomPane;

  const BuoyantTwoPane(
      {Key? key, required this.topPane, required this.bottomPane})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final halfOpenedOrientation = HalfOpenedOrientation.of(context);

    //      Rotation    flatOnTable     uprightVertical
    //  cameraOnLeft    left            right
    //  cameraOnTop     upsideDown      normal
    //  cameraOnBottom  normal          upsideDown

    //    PanelOrder    flatOnTable     uprightVertical
    //  cameraOnLeft    horiz. ltr      horiz. rtl
    //  cameraOnTop     vertic. up      vertic. down
    //  cameraOnBottom  vertic. down    vertic up

    late SquareRotation rotation = SquareRotation.normal;
    late VerticalDirection verticalDirection = VerticalDirection.down;
    late TextDirection horizontalDirection = TextDirection.ltr;

    switch (halfOpenedOrientation.screenWithCameraPosition) {
      case ScreenWithCameraPosition.flatOnTable:
        switch (halfOpenedOrientation.layoutOrientation) {
          case LayoutOrientation.cameraOnLeft:
            rotation = SquareRotation.left;
            horizontalDirection = TextDirection.ltr;
            break;
          case LayoutOrientation.cameraOnTop:
            rotation = SquareRotation.upsideDown;
            verticalDirection = VerticalDirection.up;
            break;
          case LayoutOrientation.cameraOnBottom:
            rotation = SquareRotation.normal;
            verticalDirection = VerticalDirection.down;
            break;
        }
        break;
      case ScreenWithCameraPosition.uprightVertical:
        switch (halfOpenedOrientation.layoutOrientation) {
          case LayoutOrientation.cameraOnLeft:
            rotation = SquareRotation.right;
            horizontalDirection = TextDirection.rtl;
            break;
          case LayoutOrientation.cameraOnTop:
            rotation = SquareRotation.normal;
            verticalDirection = VerticalDirection.down;
            break;
          case LayoutOrientation.cameraOnBottom:
            rotation = SquareRotation.upsideDown;
            verticalDirection = VerticalDirection.up;
            break;
        }
        break;
      default:
        rotation = SquareRotation.normal;
        verticalDirection = VerticalDirection.down;
        horizontalDirection = TextDirection.ltr;
        break;
    }

    return TwoPane(
      startPane: RotateLayoutBy90(
        rotation: rotation,
        child: topPane,
      ),
      endPane: RotateLayoutBy90(
        rotation: rotation,
        child: bottomPane,
      ),
      textDirection: horizontalDirection,
      verticalDirection: verticalDirection,
    );
  }

  SquareRotation _flip(SquareRotation rotation) {
    switch (rotation) {
      case SquareRotation.left:
        return SquareRotation.right;
        break;
      case SquareRotation.right:
        return SquareRotation.left;
        break;
      case SquareRotation.normal:
        return SquareRotation.upsideDown;
        break;
      case SquareRotation.upsideDown:
        return SquareRotation.normal;
        break;
    }
  }
}