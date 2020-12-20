import 'package:flutter/material.dart';

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
  List<TransformationController> _transformationControllers = [
    TransformationController(),
    TransformationController()
  ];

  Animation<Matrix4> _resetAnimationMatrix;
  AnimationController _resetController;
  Animation _resetAnimation;

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
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(children: [
            PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < widget.images.length; i++)
                  ClipRect(
                    child: InteractiveViewer(
                      transformationController:
                          _transformationControllers[(i + 1) % 2],
                      onInteractionStart: _onInteractionStart,
                      maxScale: 20,
                      child: Center(child: widget.images[i]),
                    ),
                  )
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      _transformationControllers[
                              _pageController.page.toInt() % 2]
                          .value = Matrix4.identity();
                      _pageController.previousPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOutCirc);
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
                      _transformationControllers[
                              _pageController.page.toInt() % 2]
                          .value = Matrix4.identity();
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOutCirc);
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

  void onChangedResetControllerMatrix() {
    final transformationController =
        _transformationControllers[(_pageController.page.toInt() + 1) % 2];

    transformationController.value = _resetAnimationMatrix.value;

    if (!_resetController.isAnimating) {
      _resetAnimationMatrix?.removeListener(onChangedResetControllerMatrix);
      _resetAnimationMatrix = null;
      _resetController.reset();
    }
  }

  void _resetViewerMatrix() {
    final transformationController =
        _transformationControllers[(_pageController.page.toInt() + 1) % 2];

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
          itemWidth: 30,
          top: 30,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ...widget.images.map((e) => SizedBox(
                    width: 30,
                    height: 30,
                    child: e,
                  )),
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
