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
    bool undecided = halfOpenedOrientation.screenWithCameraPositionUndecided;
    final playerOne = halfOpenedOrientation.screenWithCameraPosition ==
        ScreenWithCameraPosition.uprightVertical;

    final yourBoard = GameBoard(playerOne: playerOne, info: 'This is your board. It always sits at the top',);
    final opponentBoard = GameBoard(playerOne: playerOne, info: 'This is your opponent\'s board. It always sits at the bottom',);
    const flipInstructions = Material(
      color: Colors.black12,
      child: Center(
        child: Text('Place the device on a table in laptop mode.'),
      ),
    );

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

class GameBoard extends StatelessWidget {
  const GameBoard({
    Key? key,
    required this.playerOne,
    required this.info,
  }) : super(key: key);

  final bool playerOne;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: playerOne ? Colors.blue[300] : Colors.orange[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(info),
          SizedBox(height: 32),
          Text('You are player'),
          Text(
            playerOne ? "1" : "2",
            style: const TextStyle(fontSize: 124),
          )
        ],
      ),
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
  late bool halfOpened;
  ScreenWithCameraPosition screenWithCameraPosition =
      ScreenWithCameraPosition.uprightVertical;
  bool screenWithCameraPositionUndecided = true;
  LayoutOrientation layoutOrientation = LayoutOrientation.cameraOnLeft;
  TargetPlatform platform = TargetPlatform.android;

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
    halfOpened = MediaQuery.of(context).displayFeatures.any((displayFeature) =>
        displayFeature.state == DisplayFeatureState.postureHalfOpened);
    checkNativeOrientationChange();
    super.didChangeDependencies();
  }

  void onAcceleratorEvent(AccelerometerEvent event) {
    // Interval to consider things are unclear. Should be below 0.9
    const double UNDECIDED_TRESHOLD = 0.7;

    // Will be below 0.5 for uprightVertical and above 0.5 for flatOnTable
    final double zPosition = (event.z - 3.0) / (9.5 - 3.0);

    // Will be below 0.5 for flatOnTable and above 0.5 for uprightVertical
    final double xPosition = event.x / 9.5;

    // Will be below 0 for uprightVertical and above 0 for flatOnTable
    // Between -UNDECIDED_TRESHOLD and UNDECIDED_TRESHOLD we consider it
    // undecided. -1 ad +1 are the decisive values
    final double position = zPosition - xPosition;

    final undecided =
        position > -UNDECIDED_TRESHOLD && position < UNDECIDED_TRESHOLD;
    late ScreenWithCameraPosition latestCameraPosition;

    if (position < 0) {
      latestCameraPosition = ScreenWithCameraPosition.uprightVertical;
    } else {
      latestCameraPosition = ScreenWithCameraPosition.flatOnTable;
    }

    if ((latestCameraPosition != screenWithCameraPosition) ||
        (screenWithCameraPositionUndecided != undecided)) {
      setState(() {
        screenWithCameraPosition = latestCameraPosition;
        screenWithCameraPositionUndecided = undecided;
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
      screenWithCameraPositionUndecided:
          !halfOpened || screenWithCameraPositionUndecided,
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
  final bool screenWithCameraPositionUndecided;

  HalfOpenedOrientationData({
    required this.screenWithCameraPosition,
    required this.layoutOrientation,
    required this.screenWithCameraPositionUndecided,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HalfOpenedOrientationData &&
          runtimeType == other.runtimeType &&
          screenWithCameraPosition == other.screenWithCameraPosition &&
          layoutOrientation == other.layoutOrientation &&
          screenWithCameraPositionUndecided ==
              other.screenWithCameraPositionUndecided;

  @override
  int get hashCode =>
      screenWithCameraPosition.hashCode ^
      layoutOrientation.hashCode ^
      screenWithCameraPositionUndecided.hashCode;
}

/// Describes the position of the screen that has the camera on it (2nd screen),
/// when the posture of the device is half opened.
enum ScreenWithCameraPosition {
  /// The screen carrying the camera is flat on the table. The other screen is upright.
  flatOnTable,

  /// The screen carying the camera is upright. The other screen is flat on the table.
  uprightVertical,
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
