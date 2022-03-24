import 'dart:async';
import 'dart:math';

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class HingeHaptics extends StatefulWidget {
  final Widget child;
  const HingeHaptics({Key? key, required this.child}) : super(key: key);

  @override
  _HingeHapticsState createState() => _HingeHapticsState();
}

class _HingeHapticsState extends State<HingeHaptics> {

  /// Synthetic data, produced by interpolation
  double usedAngle = 0;
  double lastUsedAngle = 0;

  /// Stread of angle values
  StreamSubscription? hingeSubscription;

  // Interpolation data
  double interpolateAngleStart = 0;
  double interpolateAngleEnd = 0;
  DateTime interpolateStart = DateTime.now();
  DateTime interpolateEnd = DateTime.now();
  Timer? interpolator;

  // Position of "teeth" on the hinge
  late List<double> teethPosition;

  @override
  void initState() {
    super.initState();
    const teeth = 36;
    const toothSize = 360 / teeth;
    teethPosition = List.generate(teeth, (index) => index * toothSize);
    hingeSubscription = DualScreenInfo.hingeAngleEvents.listen(onHingeAngleChange);
    interpolator = Timer.periodic(const Duration(milliseconds: 5), (timer) {interpolate();});
  }

  void interpolate() {
    DateTime now = DateTime.now();
    bool done = (interpolateAngleEnd - usedAngle).abs() < 0.00000001;
    if (done) {
      return;
    }
    if (now.isAfter(interpolateEnd)) {
      setUsedAngle(interpolateAngleEnd);
      return;
    }
    final interval = interpolateEnd.difference(interpolateStart).inMicroseconds;
    final past = now.difference(interpolateStart).inMicroseconds;
    final progress = past / interval;
    setUsedAngle((interpolateAngleEnd - interpolateAngleStart) * progress + interpolateAngleStart);
  }

  void setUsedAngle(double angle) {
    usedAngle = angle;
    interpretUsedAngle(usedAngle);
  }

  void interpretUsedAngle(double angle) {
    bool toothHit = teethPosition.any((tooth) => (tooth < lastUsedAngle && tooth > angle) || (tooth < angle && tooth > lastUsedAngle));
    lastUsedAngle = angle;
    if (toothHit) {
      HapticFeedback.heavyImpact();
    }
  }

  void onHingeAngleChange(double angle) async {
    DateTime now = DateTime.now();
    interpolateAngleEnd = angle;
    interpolateAngleStart = lastUsedAngle;
    interpolateStart = now;
    interpolateEnd = now.add(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    hingeSubscription?.cancel();
    interpolator?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
