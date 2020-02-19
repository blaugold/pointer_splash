import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: RaySplashScreen(),
    );
  }
}

class RaySplashScreen extends StatefulWidget {
  @override
  _RaySplashScreenState createState() => _RaySplashScreenState();
}

class _RaySplashScreenState extends State<RaySplashScreen>
    with TickerProviderStateMixin {
  final List<SplashController> _splashes = [];
  SplashController _lastSplash;

  double _rays = 6;
  double _radius = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (details) => _startSplash(details.position),
        onPointerCancel: (_) => _finishSplash(),
        onPointerUp: (_) => _finishSplash(),
        child: Container(
          child: Stack(
            children: [
              ..._buildSplashes(),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  void _startSplash(Offset position) {
    SplashController splash;

    splash = SplashController(
      position: position,
      holdDuration: Duration(seconds: 5),
      finishDuration: Duration(milliseconds: 500),
      onFinish: () {
        splash.dispose();
        if (_lastSplash == splash) {
          _lastSplash = null;
        }
        _splashes.remove(splash);
      },
      vsync: this,
    );

    splash.hold();

    setState(() {
      _lastSplash = splash;
      _splashes.add(splash);
    });
  }

  void _finishSplash() {
    _lastSplash?.finish();
  }

  List<SizedBox> _buildSplashes() {
    return _splashes.map((splash) {
      return SizedBox.expand(
        child: RaySplash(
          controller: splash,
          rays: _rays.toInt(),
          radius: _radius,
          color: Colors.blue,
        ),
      );
    }).toList();
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Ray Count (${_rays.toInt()})'),
        ),
        Slider(
          min: 0,
          max: 50,
          value: _rays,
          onChanged: (newRays) {
            setState(() {
              _rays = newRays;
            });
          },
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Radius ($_radius)'),
        ),
        Slider(
          min: 0,
          max: 500,
          value: _radius,
          onChanged: (newRadius) {
            setState(() {
              _radius = newRadius;
            });
          },
        )
      ],
    );
  }
}

typedef OnSplashFinish = void Function();

class SplashController {
  SplashController({
    this.position,
    this.holdDuration,
    this.finishDuration,
    this.onFinish,
    this.curve = Curves.easeInOut,
    this.vsync,
  }) : _animationController = AnimationController(vsync: vsync);

  final Offset position;
  final Duration holdDuration;
  final Duration finishDuration;
  final OnSplashFinish onFinish;
  final Curve curve;
  final TickerProvider vsync;

  Animation<double> get animation =>
      _animationController.drive(CurveTween(curve: curve));

  final AnimationController _animationController;

  void hold() {
    _animationController.value = 0;
    _animationController
        .animateTo(1, duration: holdDuration)
        .then((_) => onFinish?.call());
  }

  void finish() {
    final remainingFinishDuration =
        finishDuration * (1 - _animationController.value);

    _animationController
        .animateTo(1, duration: remainingFinishDuration)
        .then((_) => onFinish?.call());
  }

  void dispose() {
    _animationController.dispose();
  }
}

class RaySplash extends StatelessWidget {
  const RaySplash({
    this.controller,
    this.rays,
    this.radius,
    this.color,
  });

  final SplashController controller;
  final int rays;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RaySplashPainter(
        animation: controller.animation,
        center: controller.position,
        rays: rays,
        radius: radius,
        color: color,
      ),
    );
  }
}

class RaySplashPainter extends CustomPainter {
  RaySplashPainter({
    this.animation,
    this.center,
    this.radius,
    this.strokeWidth = 3.0,
    this.color = Colors.orange,
    this.rays,
    this.rayCenterOffset = .25,
    this.rayHeight = .5,
    this.circleRadius = .5,
  }) : super(repaint: animation) {
    final rayTrackStart = Offset(0, -radius * rayCenterOffset);
    final rayTrackEnd = Offset(0, -radius);
    final rayTrackLength = (rayTrackStart - rayTrackEnd).distance;

    _circleColor = animation.drive(TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(begin: color.withOpacity(0), end: color),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: color, end: color.withOpacity(.0)),
        weight: 9,
      ),
    ]));
    _circleRadius = animation.drive(Tween(
      begin: strokeWidth,
      end: radius * circleRadius,
    ));

    _rayCenter = animation.drive(Tween(
      begin: rayTrackStart,
      end: rayTrackEnd,
    ));

    final fullRayHeight = rayTrackLength * rayHeight;
    final rayHeightTween = TweenSequence([
      TweenSequenceItem(
        weight: 1,
        tween: Tween(begin: 0.0, end: fullRayHeight),
      ),
      TweenSequenceItem(
        weight: 1,
        tween: Tween(begin: fullRayHeight, end: 0.0),
      ),
    ]);

    _rayHeight = animation.drive(rayHeightTween);

    _rayColor = animation.drive(TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(begin: color.withOpacity(0), end: color),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ConstantTween(color),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: color, end: color.withOpacity(.0)),
        weight: 1,
      ),
    ]));
  }

  final Animation<double> animation;
  final Offset center;
  final double radius;
  final double strokeWidth;
  final Color color;
  final int rays;
  final rayCenterOffset;
  final double rayHeight;
  final double circleRadius;

  Animation<double> _circleRadius;
  Animation<Color> _circleColor;

  Animation<Offset> _rayCenter;
  Animation<double> _rayHeight;
  Animation<Color> _rayColor;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCircle(canvas);
    _drawRays(canvas);
  }

  void _drawCircle(Canvas canvas) {
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _circleColor.value
      ..strokeWidth = strokeWidth;

    final circle = Path();
    circle.addOval(Rect.fromCircle(
      center: center,
      radius: _circleRadius.value,
    ));
    canvas.drawPath(circle, circlePaint);
  }

  void _drawRays(Canvas canvas) {
    final rayPaint = Paint()
      ..color = _rayColor.value
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.save();

    canvas.translate(center.dx, center.dy);

    final rayCircleSegment = 2 * pi / rays;

    for (var ray = 0; ray < rays; ray++) {
      canvas.rotate(rayCircleSegment);
      _drawRay(canvas, rayPaint);
    }

    canvas.restore();
  }

  void _drawRay(Canvas canvas, Paint rayPaint) {
    final start = _rayCenter.value.translate(0, _rayHeight.value / 2);
    final end = _rayCenter.value.translate(0, -_rayHeight.value / 2);

    canvas.drawLine(start, end, rayPaint);
  }

  @override
  bool shouldRepaint(RaySplashPainter old) {
    return animation == old.animation &&
        center == old.center &&
        radius == old.radius &&
        strokeWidth == old.strokeWidth &&
        color == old.color &&
        rays == old.rays &&
        rayCenterOffset == old.rayCenterOffset &&
        rayHeight == old.rayHeight &&
        circleRadius == old.circleRadius;
  }
}
