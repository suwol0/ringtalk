import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 이미지 전체화면 뷰어
///
/// 사용법:
/// ```dart
/// Navigator.of(context).push(ImageViewerPage.route(
///   imageUrl: url,
///   heroTag: 'msg-${message.id}',
///   caption: '오후 2:30',
/// ));
/// ```
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.caption,
  });

  final String imageUrl;
  final String heroTag;
  final String? caption;

  static Route<void> route({
    required String imageUrl,
    required String heroTag,
    String? caption,
  }) {
    return PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => ImageViewerPage(
        imageUrl: imageUrl,
        heroTag: heroTag,
        caption: caption,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  late final AnimationController _bgAnimController;
  late final Animation<double> _bgOpacity;

  // 스와이프 다운 닫기 관련
  Offset _dragStart = Offset.zero;
  double _dragY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // 상태바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _bgOpacity = _bgAnimController;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  bool get _isZoomed =>
      _transformationController.value.getMaxScaleOnAxis() > 1.05;

  void _onDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      // 원래 크기로 복원
      _transformationController.value = Matrix4.identity();
    } else {
      // 탭 위치 기준 3배 확대
      final position = details.localPosition;
      final x = -position.dx * 2;
      final y = -position.dy * 2;
      _transformationController.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(3.0);
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isZoomed) return;
    _dragStart = details.globalPosition;
    _isDragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final dy = details.globalPosition.dy - _dragStart.dy;
    if (dy < 0) return; // 위로 드래그는 무시

    setState(() => _dragY = dy);

    // 드래그량에 따라 배경 투명도 감소
    final progress = (dy / 200).clamp(0.0, 1.0);
    _bgAnimController.value = 1.0 - progress * 0.8;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    if (_dragY > 100 || velocity > 600) {
      // 충분히 드래그하거나 빠르게 스와이프 → 닫기
      Navigator.of(context).pop();
    } else {
      // 원위치 복원
      setState(() => _dragY = 0);
      _bgAnimController.animateTo(1.0);
    }
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgOpacity,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: _bgOpacity.value),
          body: Stack(
            children: [
              // ── 이미지 영역 ───────────────────────────────────────
              GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onDoubleTapDown: _onDoubleTap,
                onDoubleTap: () {}, // DoubleTapDown 트리거용
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _dragY),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      clipBehavior: Clip.none,
                      child: Hero(
                        tag: widget.heroTag,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  color: Colors.white38, size: 64),
                              SizedBox(height: 8),
                              Text('이미지를 불러올 수 없어요',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 상단 AppBar 영역 ──────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _openExternal(context),
                        icon: const Icon(Icons.open_in_new_rounded),
                        color: Colors.white,
                        tooltip: '외부에서 열기',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 하단 캡션 (시간/상태) ────────────────────────────
              if (widget.caption != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Text(
                        widget.caption!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      // 외부 앱 없으면 URL 클립보드 복사
      await Clipboard.setData(ClipboardData(text: widget.imageUrl));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 URL이 클립보드에 복사됐어요.')),
        );
      }
    }
  }
}
