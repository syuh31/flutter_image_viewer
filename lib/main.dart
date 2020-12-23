import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' show Vector3;

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Widget> images = [
    Image.asset('assets/image/001.jpg'),
    Image.asset('assets/image/002.jpg'),
    Image.asset('assets/image/001.jpg'),
    Image.asset('assets/image/002.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ImageViewer(
          images,
        ),
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  ImageViewer(this.images);

  final List<Widget> images;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with TickerProviderStateMixin {
  PageController _pageController;
  Size viewerSize;
  Offset viewerOffset;
  List<TransformationController> _transformationControllers = [
    TransformationController(),
    TransformationController(),
  ];
  List<Vector3> _translations = [
    Vector3.zero(),
    Vector3.zero(),
  ];
  List<double> _scales = [
    1.0,
    1.0,
  ];

  Animation<Matrix4> _resetAnimationMatrix;
  AnimationController _resetController;
  Animation _resetAnimation;
  final GlobalKey viewerKey = GlobalKey();
  List<OverlayEntry> _positionOverlays = <OverlayEntry>[];

  final _positionBarWidth = 4.0;

  // Vector3 translation;
  // double scale;

  bool canScrollPage = false;

  double get currentPage =>
      _pageController.hasClients ? _pageController.page ?? .0 : .0;
  int storageIndex = 0;

  TransformationController get currentTransitionController {
    return _transformationControllers[storageIndex % 2];
  }

  TransformationController get nextTransitionController {
    return _transformationControllers[(storageIndex + 1) % 2];
  }

  Vector3 get currentTranslation {
    return _translations[storageIndex % 2];
  }

  set currentTranslation(Vector3 value) {
    _translations[storageIndex % 2] = value;
  }

  Vector3 get nextTranslation {
    return _translations[(storageIndex + 1) % 2];
  }

  set nextTranslation(Vector3 value) {
    _translations[(storageIndex + 1) % 2] = value;
  }

  double get currentScale {
    return _scales[storageIndex % 2];
  }

  set currentScale(double value) {
    _scales[storageIndex % 2] = value;
  }

  double get nextScale {
    return _scales[(storageIndex + 1) % 2];
  }

  set nextScale(double value) {
    _scales[(storageIndex + 1) % 2] = value;
  }

  void _onPageChanged(int newPage) {}

  void _switchStorage() {
    storageIndex = (storageIndex + 1) % 2;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resetAnimation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final transformationController = currentTransitionController;
        currentTranslation = transformationController.value.getTranslation();
        final normalMatrix = transformationController.value.getNormalMatrix();
        currentScale = normalMatrix.getRow(0)[0];
        RenderBox renderBox = viewerKey.currentContext.findRenderObject();
        viewerSize = renderBox.size;
        viewerOffset = renderBox
            .localToGlobal(Offset.zero)
            .translate(0, MediaQuery.of(context).padding.top);

        final _horizontalPositionOverlay = OverlayEntry(
          builder: (BuildContext context) {
            return Positioned(
              top: viewerOffset.dy + viewerSize.height - _positionBarWidth,
              left: viewerOffset.dx +
                  (currentTranslation[0] * currentScale).abs(),
              child: Offstage(
                offstage: currentScale == 1.0,
                child: Container(
                  width: viewerSize.width * currentScale,
                  height: _positionBarWidth,
                  decoration: BoxDecoration(
                      border: Border(
                    top: BorderSide(
                        color: Colors.black54, width: _positionBarWidth),
                  )),
                ),
              ),
            );
          },
        );

        final _verticalPositionOverlay = OverlayEntry(
          builder: (BuildContext context) {
            return Positioned(
              top: viewerOffset.dy +
                  (currentTranslation[1] * currentScale).abs(),
              left: viewerOffset.dx + viewerSize.width - _positionBarWidth,
              child: Offstage(
                offstage: currentScale == 1.0,
                child: Container(
                  width: _positionBarWidth,
                  height: viewerSize.height * currentScale,
                  decoration: BoxDecoration(
                      border: Border(
                    left: BorderSide(
                        color: Colors.black54, width: _positionBarWidth),
                  )),
                ),
              ),
            );
          },
        );

        _positionOverlays
            .addAll([_horizontalPositionOverlay, _verticalPositionOverlay]);
        Navigator.of(context).overlay.insertAll(_positionOverlays);
      });
    });
  }

  @override
  void dispose() {
    for (OverlayEntry entry in _positionOverlays) entry.remove();
    _resetController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Offset _tapPosition = Offset(0, 0);

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    setState(() {
      _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(children: [
            Column(
              children: [
                Text('$_tapPosition'),
                Text('$currentScale'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: PageView(
                key: viewerKey,
                controller: _pageController,
                physics: canScrollPage
                    ? ScrollPhysics()
                    : NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  for (int i = 0; i < widget.images.length; i++)
                    ClipRect(
                      child: GestureDetector(
                        onTapDown: _handleTapDown,
                        onTap: tapScale,
                        child: InteractiveViewer(
                          transformationController: currentTransitionController,
                          onInteractionStart: _onInteractionStart,
                          onInteractionUpdate: (_) {
                            updateTransitionAndScale();
                            for (OverlayEntry entry in _positionOverlays)
                              entry.markNeedsBuild();
                          },
                          onInteractionEnd: (_) {
                            updateTransitionAndScale();
                            for (OverlayEntry entry in _positionOverlays)
                              entry.markNeedsBuild();
                          },
                          maxScale: 5,
                          child: Center(child: widget.images[i]),
                        ),
                      ),
                    )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      currentTranslation = Vector3.zero();
                      currentScale = 1.0;
                      nextTransitionController.value = Matrix4.identity();
                      for (OverlayEntry entry in _positionOverlays)
                        entry.markNeedsBuild();
                      _pageController
                          .previousPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOutCirc)
                          .then((_) {
                        _switchStorage();
                        for (OverlayEntry entry in _positionOverlays)
                          entry.markNeedsBuild();
                      });
                    },
                    color: Theme.of(context).colorScheme.surface,
                    icon: const Icon(
                      Icons.arrow_left,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    focusColor: Colors.blue,
                    hoverColor: Colors.red,
                    highlightColor: Colors.purple,
                    onPressed: () {
                      currentTranslation = Vector3.zero();
                      currentScale = 1.0;
                      nextTransitionController.value = Matrix4.identity();
                      for (OverlayEntry entry in _positionOverlays)
                        entry.markNeedsBuild();
                      _pageController
                          .nextPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOutCirc)
                          .then((_) {
                        _switchStorage();
                        for (OverlayEntry entry in _positionOverlays)
                          entry.markNeedsBuild();
                      });
                    },
                    color: Theme.of(context).colorScheme.surface,
                    icon: const Icon(
                      Icons.arrow_right,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    onPressed: _resetViewerMatrix,
                    color: Theme.of(context).colorScheme.surface,
                    icon: const Icon(
                      Icons.replay,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
        buildBottomImages(context),
      ],
    );
  }

  void tapScale() {
    setState(() {
      final transitionController = currentTransitionController;
      if (currentScale != 1.0) {
        transitionController.value = Matrix4.identity();
      } else {
        final transitionController = currentTransitionController;
        final matrix = transitionController.value;
        final newScale = 3.0;
        matrix.scale(newScale);
        final iniX = (viewerSize.width * newScale) - (viewerSize.width);
        final xOffset =
            (viewerSize.width - (_tapPosition.dx - viewerOffset.dx)) * newScale;
        var newX = (iniX - xOffset + viewerSize.width / 2);
        if (newX < 0) {
          newX = 0;
        }
        if (iniX < newX) {
          newX = iniX;
        }
        final iniY = (viewerSize.height * newScale) - (viewerSize.height);
        final yOffset =
            (viewerSize.height - (_tapPosition.dy - viewerOffset.dy)) *
                newScale;
        var newY = (iniY - yOffset + viewerSize.height / 2);
        if (newY < 0) {
          newY = 0;
        }
        if (iniY < newY) {
          newY = iniY;
        }
        matrix.setTranslationRaw(-newX, -newY, 0);
        transitionController.value = matrix;
      }
      updateTransitionAndScale();
      for (OverlayEntry entry in _positionOverlays) entry.markNeedsBuild();
    });
  }

  void updateTransitionAndScale() {
    final transformationController = currentTransitionController;
    currentTranslation = transformationController.value.getTranslation();
    final normalMatrix = transformationController.value.getNormalMatrix();
    currentScale = normalMatrix.getRow(0)[0];
  }

  void onChangedResetControllerMatrix() {
    final transformationController = currentTransitionController;

    transformationController.value = _resetAnimationMatrix.value;

    if (!_resetController.isAnimating) {
      _resetAnimationMatrix?.removeListener(onChangedResetControllerMatrix);
      _resetAnimationMatrix = null;
      _resetController.reset();
    }
  }

  void _resetViewerMatrix() {
    final transformationController = currentTransitionController;

    _resetController.reset();
    _resetAnimationMatrix = Matrix4Tween(
      begin: transformationController.value,
      end: Matrix4.identity(),
    ).animate(_resetAnimation);
    _resetAnimationMatrix.addListener(onChangedResetControllerMatrix);
    _resetController.forward();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_resetController.status == AnimationStatus.forward) {
      _resetController.stop();
      _resetAnimationMatrix?.removeListener(onChangedResetControllerMatrix);
      _resetAnimationMatrix = null;
      _resetController.reset();
    }
  }

  Widget buildBottomImages(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSelectBorder(
          itemNum: widget.images.length,
          pageController: _pageController,
          itemWidth: 40,
          top: 40,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < widget.images.length; i++)
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOutCirc,
                    );
                  },
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: widget.images[i],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedSelectBorder extends StatefulWidget {
  AnimatedSelectBorder({
    this.itemNum,
    this.pageController,
    this.itemWidth,
    this.top,
  });

  final int itemNum;
  final double itemWidth;
  final PageController pageController;
  final double top;

  @override
  _AnimatedSelectBorderState createState() => _AnimatedSelectBorderState();
}

class _AnimatedSelectBorderState extends State<AnimatedSelectBorder> {
  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderSpaceWidth = widget.itemWidth * widget.itemNum;
    final borderLeftOffset =
        (MediaQuery.of(context).size.width - borderSpaceWidth) / 2;
    final color = IconTheme.of(context).color;

    double page = widget.pageController.page ?? 0;

    return Positioned(
      left: borderLeftOffset + widget.itemWidth * page,
      top: widget.top,
      child: Container(
        width: widget.itemWidth,
        decoration: BoxDecoration(
            color: color,
            border: Border(bottom: BorderSide(color: color, width: 4))),
      ),
    );
  }
}
