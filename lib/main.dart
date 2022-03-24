import 'dart:math';
import 'dart:ui';

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boat Fight for Surface Duo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HalfOpenedOrientation(child: BoatGame()),
    );
  }
}

class BoatGame extends StatelessWidget {
  const BoatGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final halfOpenedOrientation = HalfOpenedOrientation.of(context);
    final player = halfOpenedOrientation.screenWithCameraPosition ==
            ScreenWithCameraPosition.uprightVertical
        ? "ONE"
        : "TWO";
    final yourBoard = Container(
      color: Colors.green[300],
      child: Center(
        child: Text('This is your board. You are player $player'),
      ),
    );
    final opponentBoard = Container(
      color: Colors.blue[300],
      child: Center(
        child: Text('This is your opponent\'s board.'),
      ),
    );
    final flipInstructions = Container(
      color: Colors.teal[300],
      child: Center(
        child: Text(
            'Have the device in laptop shape. Players take turns flipping the device to their side.'),
      ),
    );
    bool undecided = halfOpenedOrientation.screenWithCameraPosition ==
        ScreenWithCameraPosition.undecidedUprightVertical || halfOpenedOrientation.screenWithCameraPosition ==
        ScreenWithCameraPosition.undecidedFlatOnTable;
    return BuoyantTwoPane(
      topPane: undecided
          ? Transform.rotate(
              angle: pi,
              child: flipInstructions,
            )
          : yourBoard,
      bottomPane: undecided ? flipInstructions : opponentBoard,
    );
  }
}

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

    ///      Rotation    flatOnTable     uprightVertical
    ///  cameraOnLeft    left            right
    ///  cameraOnTop     upsideDown      normal
    ///  cameraOnBottom  normal          upsideDown

    ///    PanelOrder    flatOnTable     uprightVertical
    ///  cameraOnLeft    horiz. ltr      horiz. rtl
    ///  cameraOnTop     vertic. up      vertic. down
    ///  cameraOnBottom  vertic. down    vertic up

    late SquareRotation rotation = SquareRotation.normal;
    late VerticalDirection verticalDirection = VerticalDirection.down;
    late TextDirection horizontalDirection = TextDirection.ltr;

    switch (halfOpenedOrientation.screenWithCameraPosition) {
      case ScreenWithCameraPosition.flatOnTable:
      case ScreenWithCameraPosition.undecidedFlatOnTable:
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
      case ScreenWithCameraPosition.undecidedUprightVertical:
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

    return Material(
      child: TwoPane(
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
      ),
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

class HalfOpenedOrientation extends StatefulWidget {
  final Widget child;

  const HalfOpenedOrientation({Key? key, required this.child})
      : super(key: key);

  static HalfOpenedOrientationData of(BuildContext context) {
    final _HalfOpenedOrientation? result =
        context.dependOnInheritedWidgetOfExactType<_HalfOpenedOrientation>();
    assert(result != null, 'No HalfOpenedOrientation found in context');
    return result!.data;
  }

  @override
  _HalfOpenedOrientationState createState() => _HalfOpenedOrientationState();
}

class _HalfOpenedOrientationState extends State<HalfOpenedOrientation> {
  static const double MOVEMENT_TRESHOLD = 2;
  static const int MOVEMENT_DEBOUNCE_MS = 250;
  late bool isSpanned;
  ScreenWithCameraPosition screenWithCameraPosition =
      ScreenWithCameraPosition.undecidedUprightVertical;
  LayoutOrientation layoutOrientation = LayoutOrientation.cameraOnLeft;
  TargetPlatform platform = TargetPlatform.android;
  AccelerometerEvent lastAcceleration = AccelerometerEvent(0, 0, 0);
  DateTime ignoreAccelerationUntil = DateTime.now();


  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      accelerometerEvents.listen(onAcceleratorEvent);
    });
  }

  @override
  void didChangeDependencies() {
    platform = Theme.of(context).platform;
    isSpanned = MediaQuery.of(context).displayFeatures.any((displayFeature) =>
        displayFeature.type == DisplayFeatureType.hinge ||
        displayFeature.state == DisplayFeatureState.postureHalfOpened);
    checkNativeOrientationChange();
    super.didChangeDependencies();
  }

  void onAcceleratorEvent(AccelerometerEvent event) {
    if (DateTime.now().isBefore(ignoreAccelerationUntil)) {
      return;
    }

    final movement = (event.x - lastAcceleration.x).abs() +
        // (event.y - lastAcceleration.y).abs() +
        (event.z - lastAcceleration.z).abs();
    lastAcceleration = event;

    print("Tresholds are $MOVEMENT_TRESHOLD and $MOVEMENT_DEBOUNCE_MS and movement is ${movement.toStringAsFixed(2)} and X = ${event.x.toStringAsFixed(2)} and Z = ${event.z.toStringAsFixed(2)}");

    final cameraUp = event.x > 8;
    final cameraDown = event.z > 8;
    final undecided = movement > MOVEMENT_TRESHOLD || (!cameraUp && !cameraDown);

    late ScreenWithCameraPosition latestCameraPosition;

    if (undecided && event.x > event.z) {
      latestCameraPosition = ScreenWithCameraPosition.undecidedUprightVertical;
    } else if (undecided && event.x <= event.z) {
      latestCameraPosition = ScreenWithCameraPosition.undecidedFlatOnTable;
    } else if (event.x > event.z) {
      latestCameraPosition = ScreenWithCameraPosition.uprightVertical;
    } else if (event.x <= event.z) {
      latestCameraPosition = ScreenWithCameraPosition.flatOnTable;
    } else {
      latestCameraPosition = ScreenWithCameraPosition.undecidedUprightVertical;
    }

    if (undecided) {
      ignoreAccelerationUntil = DateTime.now().add(const Duration(milliseconds: MOVEMENT_DEBOUNCE_MS));
    }

    if (latestCameraPosition != screenWithCameraPosition) {
      setState(() {
        screenWithCameraPosition = latestCameraPosition;
      });
    }
  }

  void checkNativeOrientationChange() async {
    late NativeDeviceOrientation nativeOrientation;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      nativeOrientation = NativeDeviceOrientation.landscapeLeft;
    } else {
      nativeOrientation =
          await NativeDeviceOrientationCommunicator().orientation();
    }

    print('Platform: $platform');
    print('Native orientation: $nativeOrientation');

    late LayoutOrientation latestLayoutOrientation;
    switch (nativeOrientation) {
      case NativeDeviceOrientation.landscapeLeft:
        latestLayoutOrientation = LayoutOrientation.cameraOnLeft;
        break;
      case NativeDeviceOrientation.portraitUp:
        latestLayoutOrientation = LayoutOrientation.cameraOnTop;
        break;
      case NativeDeviceOrientation.portraitDown:
        latestLayoutOrientation = LayoutOrientation.cameraOnBottom;
        break;
      default:
        latestLayoutOrientation = LayoutOrientation.cameraOnLeft;
        break;
    }

    print('Layout orientation: $latestLayoutOrientation');

    if (latestLayoutOrientation != layoutOrientation) {
      setState(() {
        layoutOrientation = latestLayoutOrientation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    HalfOpenedOrientationData data = HalfOpenedOrientationData(
      screenWithCameraPosition: screenWithCameraPosition,
      layoutOrientation: layoutOrientation,
    );
    // final child = Material(
    //   child: Padding(
    //     padding: const EdgeInsets.all(32.0),
    //     child: Text(
    //         'All data: \n spanned: $isSpanned \n nativeOrientation: $nativeOrientation \n   Gravity[x]: ${lastAcceleration!.x}\n   Gravity[y]: ${lastAcceleration!.y}\n   Gravity[z]: ${lastAcceleration!.z}'),
    //   ),
    // );
    return _HalfOpenedOrientation(child: widget.child, data: data);
  }
}

class _HalfOpenedOrientation extends InheritedWidget {
  final HalfOpenedOrientationData data;

  const _HalfOpenedOrientation({
    Key? key,
    required Widget child,
    required this.data,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_HalfOpenedOrientation oldWidget) {
    return oldWidget.data != data;
  }
}

class HalfOpenedOrientationData {
  final ScreenWithCameraPosition screenWithCameraPosition;
  final LayoutOrientation layoutOrientation;

  HalfOpenedOrientationData({
    required this.screenWithCameraPosition,
    required this.layoutOrientation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HalfOpenedOrientationData &&
          runtimeType == other.runtimeType &&
          screenWithCameraPosition == other.screenWithCameraPosition &&
          layoutOrientation == other.layoutOrientation;

  @override
  int get hashCode =>
      screenWithCameraPosition.hashCode ^ layoutOrientation.hashCode;
}

/// Describes the position of the screen that has the camera on it (2nd screen),
/// when the posture of the device is half opened.
enum ScreenWithCameraPosition {
  /// The screen carrying the camera is flat on the table. The other screen is upright.
  flatOnTable,

  /// The screen carying the camera is upright. The other screen is flat on the table.
  uprightVertical,

  /// The setup is unclear but it is likely to be [flatOnTable], which can
  /// happen when:
  ///
  ///   * the angle of the hinge is too wide, making the posture flat or not
  ///   "closed" enough for the purpose of this game. Display feature posture is
  ///   not used, but the angle of the hinge is used directly for finer control.
  ///   * the accelerometer reports unclear data, meaning that none of the two
  ///   screens is a clear candidate for the being considered flat on the table.
  ///   * accelerometer data is in "movement", meaning that the screens are
  ///   being manipulated and moved around.
  undecidedFlatOnTable,

  /// The setup is unclear but it is likely to be [uprightVertical], which can
  /// happen when:
  ///
  ///   * the angle of the hinge is too wide, making the posture flat or not
  ///   "closed" enough for the purpose of this game. Display feature posture is
  ///   not used, but the angle of the hinge is used directly for finer control.
  ///   * the accelerometer reports unclear data, meaning that none of the two
  ///   screens is a clear candidate for the being considered flat on the table.
  ///   * accelerometer data is in "movement", meaning that the screens are
  ///   being manipulated and moved around.
  undecidedUprightVertical,
}

/// Orientation of the layout in relation to the hardware screens.
///
/// The data coming from [ScreenWithCameraPosition] is not enough to know what
/// to render on each screen. Double-landscape can mean that the screen carrying
/// the camera can be at the top or at the bottom and we can't know which
/// scenario we are in unless we look at the [NativeDeviceOrientation].
enum LayoutOrientation {
  /// Device is in double-portrait, with the charging port at the bottom and the
  /// camera on the left screen.
  cameraOnLeft,

  /// Device is in double-landscape, with the charging port on the right and the
  /// camera on the top screen.
  cameraOnTop,

  /// Device is in double-landscape, with the charging port on the left and the
  /// camera on the bottom screen.
  cameraOnBottom,
}
