import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  /// Interval to consider things are unclear. Should be below 1.0
  static const double UNDECIDED_THRESHOLD = 0.9;

  /// If device is halfOpened. If not, we cannot decide the [screenWithCameraPosition]
  late bool halfOpened;

  /// Position of the screen carrying the camera
  ScreenWithCameraPosition screenWithCameraPosition = ScreenWithCameraPosition.uprightVertical;

  /// If the [screenWithCameraPosition] is decisive or in-between positions
  bool screenWithCameraPositionUndecided = true;

  /// he orientation of the app relative to the hardware
  LayoutOrientation layoutOrientation = LayoutOrientation.cameraOnLeft;

  /// OS we are running on. Adaptations are needed for the web version. TBD
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
    // Will be below 0.5 for uprightVertical and above 0.5 for flatOnTable
    final double zPosition = (event.z - 3.0) / (9.5 - 3.0);

    // Will be below 0.5 for flatOnTable and above 0.5 for uprightVertical
    final double xPosition = event.x / 9.5;

    // Will be below 0 for uprightVertical and above 0 for flatOnTable
    // Between -UNDECIDED_TRESHOLD and UNDECIDED_TRESHOLD we consider it
    // undecided. -1 ad +1 are the decisive values
    final double position = zPosition - xPosition;

    final undecided =
        position > -UNDECIDED_THRESHOLD && position < UNDECIDED_THRESHOLD;
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