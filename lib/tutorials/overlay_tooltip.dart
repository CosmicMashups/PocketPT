import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'tutorial_models.dart';

enum _SequenceCommand { next, previous, skip, done }

/// Lightweight custom overlay implementation for guided tutorials.
class TutorialOverlay {
  TutorialOverlay._();

  static final TutorialOverlay instance = TutorialOverlay._();

  OverlayEntry? _activeEntry;
  Completer<_SequenceCommand>? _activeCompleter;

  /// Displays a multi-step tutorial sequence with overlay bubbles.
  Future<void> showSequence({
    required BuildContext context,
    required List<TutorialStep> steps,
    String? flowId,
    required TutorialEventEmitter emit,
  }) async {
    if (steps.isEmpty) return;

    var index = 0;
    while (index >= 0 && index < steps.length) {
      final step = steps[index];
      emit(
        TutorialEventType.stepShown,
        step,
        flowId: flowId,
        payload: <String, Object?>{
          'index': index + 1,
          'total': steps.length,
        },
      );

      final hasPrevious = index > 0;
      final hasNext = index < steps.length - 1;
      final result = await _presentStep(
        context: context,
        step: step,
        flowId: flowId,
        hasPrevious: hasPrevious,
        hasNext: hasNext,
        emit: emit,
      );

      switch (result) {
        case _SequenceCommand.previous:
          emit(
            TutorialEventType.stepAdvanced,
            step,
            flowId: flowId,
            payload: const <String, Object?>{'direction': 'previous'},
          );
          index = max(0, index - 1);
          break;
        case _SequenceCommand.next:
          emit(
            TutorialEventType.stepAdvanced,
            step,
            flowId: flowId,
            payload: const <String, Object?>{'direction': 'next'},
          );
          index += 1;
          break;
        case _SequenceCommand.skip:
          emit(
            TutorialEventType.tutorialSkipped,
            step,
            flowId: flowId,
            payload: <String, Object?>{'index': index + 1},
          );
          return;
        case _SequenceCommand.done:
          return;
      }
    }
  }

  /// Displays a single tutorial step as an overlay tooltip.
  Future<void> showStep({
    required BuildContext context,
    required TutorialStep step,
    String? flowId,
    required TutorialEventEmitter emit,
  }) async {
    emit(
      TutorialEventType.stepShown,
      step,
      flowId: flowId,
      payload: const <String, Object?>{'index': 1, 'total': 1},
    );

    final result = await _presentStep(
      context: context,
      step: step,
      flowId: flowId,
      hasPrevious: false,
      hasNext: false,
      emit: emit,
    );

    if (result == _SequenceCommand.skip) {
      emit(
        TutorialEventType.tutorialSkipped,
        step,
        flowId: flowId,
        payload: const <String, Object?>{'index': 1},
      );
    }
  }

  Future<_SequenceCommand> _presentStep({
    required BuildContext context,
    required TutorialStep step,
    required bool hasPrevious,
    required bool hasNext,
    required TutorialEventEmitter emit,
    String? flowId,
  }) async {
    _removeActiveEntry();

    final overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) {
      debugPrint('TutorialOverlay: No overlay found, cannot display tutorial step "${step.id}"');
      return _SequenceCommand.done;
    }
    
    final completer = Completer<_SequenceCommand>();
    _activeCompleter = completer;

    final mediaQuery = MediaQuery.of(context);
    final anchorRect = _resolveAnchorRect(step.anchorKey);

    final entry = OverlayEntry(
      builder: (overlayContext) {
        return MediaQuery(
          data: mediaQuery,
          child: _TutorialStepOverlay(
            step: step,
            anchorRect: anchorRect,
            hasPrevious: hasPrevious,
            hasNext: hasNext,
            onNext: () {
              if (!completer.isCompleted) {
                completer.complete(_SequenceCommand.next);
              }
            },
            onPrevious: () {
              if (!completer.isCompleted) {
                completer.complete(_SequenceCommand.previous);
              }
            },
            onSkip: () {
              if (!completer.isCompleted) {
                completer.complete(_SequenceCommand.skip);
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(_SequenceCommand.done);
              }
            },
            emit: emit,
            flowId: flowId,
          ),
        );
      },
    );

    overlayState.insert(entry);
    _activeEntry = entry;

    final command = await completer.future;
    _removeActiveEntry();
    return command;
  }

  void _removeActiveEntry() {
    _activeEntry?.remove();
    _activeEntry = null;
    _activeCompleter?.complete(_SequenceCommand.done);
    _activeCompleter = null;
  }

  Rect? _resolveAnchorRect(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }
}

class _TutorialStepOverlay extends StatefulWidget {
  const _TutorialStepOverlay({
    required this.step,
    required this.anchorRect,
    required this.hasPrevious,
    required this.hasNext,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onDone,
    required this.emit,
    this.flowId,
  });

  final TutorialStep step;
  final Rect? anchorRect;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onDone;
  final TutorialEventEmitter emit;
  final String? flowId;

  @override
  State<_TutorialStepOverlay> createState() => _TutorialStepOverlayState();
}

enum _ArrowDirection { none, up, down, left, right }

class _TutorialStepOverlayState extends State<_TutorialStepOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _bubbleKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'tutorial_focus');
  Offset? _bubbleOffset;
  _ArrowDirection _arrowDirection = _ArrowDirection.none;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _recalculatePosition();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scheduleRecalculate();
  }

  void _scheduleRecalculate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recalculatePosition();
      }
    });
  }

  void _recalculatePosition() {
    final renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      setState(() {
        _bubbleOffset = null;
      });
      return;
    }

    final offset = _calculateBubbleOffset(renderBox.size);
    setState(() {
      _bubbleOffset = offset.offset;
      _arrowDirection = offset.direction;
    });
  }

  (_ArrowDirection direction, Offset offset) _calculateFallback(Size bubbleSize) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final alignment = widget.step.fallback.alignment;
    final margin = widget.step.fallback.margin;
    final dx = (((alignment.x + 1) / 2) * (size.width - margin.horizontal - bubbleSize.width)) +
        margin.left;
    final dy = (((alignment.y + 1) / 2) * (size.height - margin.vertical - bubbleSize.height)) +
        margin.top;
    return (_ArrowDirection.none, Offset(dx, dy));
  }

  _PositionResult _calculateBubbleOffset(Size bubbleSize) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final padding = mq.padding;
    final Rect safeRect = Rect.fromLTWH(
      padding.left + 16,
      padding.top + 16,
      size.width - padding.horizontal - 32,
      size.height - padding.vertical - 32,
    );

    final anchor = widget.anchorRect;
    if (anchor == null) {
      final fallback = _calculateFallback(bubbleSize);
      return _PositionResult(fallback.$2, fallback.$1);
    }

    TutorialPlacement placement = widget.step.placement;
    if (placement == TutorialPlacement.auto) {
      placement = anchor.center.dy < size.height / 2
          ? TutorialPlacement.bottom
          : TutorialPlacement.top;
    }

    Offset offset;
    _ArrowDirection direction;

    switch (placement) {
      case TutorialPlacement.top:
        offset = Offset(
          anchor.center.dx - bubbleSize.width / 2,
          anchor.top - bubbleSize.height - 16,
        );
        direction = _ArrowDirection.down;
        break;
      case TutorialPlacement.bottom:
        offset = Offset(
          anchor.center.dx - bubbleSize.width / 2,
          anchor.bottom + 16,
        );
        direction = _ArrowDirection.up;
        break;
      case TutorialPlacement.left:
        offset = Offset(
          anchor.left - bubbleSize.width - 16,
          anchor.center.dy - bubbleSize.height / 2,
        );
        direction = _ArrowDirection.right;
        break;
      case TutorialPlacement.right:
        offset = Offset(
          anchor.right + 16,
          anchor.center.dy - bubbleSize.height / 2,
        );
        direction = _ArrowDirection.left;
        break;
      case TutorialPlacement.auto:
        offset = Offset.zero;
        direction = _ArrowDirection.none;
    }

    // Avoid covering the camera preview by positioning outside the anchor when requested.
    if (widget.step.cameraSafe) {
      if (placement == TutorialPlacement.bottom &&
          offset.dy < anchor.bottom + 24) {
        offset = offset.translate(0, bubbleSize.height + 24);
      }
      if (placement == TutorialPlacement.top &&
          offset.dy + bubbleSize.height > anchor.top - 24) {
        offset = offset.translate(0, -(bubbleSize.height + 24));
      }
    }

    final clampedDx = offset.dx.clamp(
      safeRect.left,
      safeRect.right - bubbleSize.width,
    );
    final clampedDy = offset.dy.clamp(
      safeRect.top,
      safeRect.bottom - bubbleSize.height,
    );

    if (clampedDy == safeRect.top && placement == TutorialPlacement.top) {
      direction = _ArrowDirection.none;
    }
    if (clampedDy == safeRect.bottom - bubbleSize.height &&
        placement == TutorialPlacement.bottom) {
      direction = _ArrowDirection.none;
    }

    return _PositionResult(Offset(clampedDx, clampedDy), direction);
  }

  @override
  Widget build(BuildContext context) {
    final anchor = widget.anchorRect;
    final highlight = anchor != null
        ? _HighlightData(rect: anchor.inflate(8), shape: widget.step.highlightShape)
        : null;

    return Material(
      color: Colors.black.withOpacity(0.55),
      child: Stack(
        children: [
          if (highlight != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HighlightPainter(highlight),
                ),
              ),
            ),
          Positioned.fill(
            child: _buildBubble(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    final step = widget.step;

    final fallback = Align(
      alignment: step.fallback.alignment,
      child: Padding(
        padding: step.fallback.margin,
        child: _buildTooltipContent(
          title: step.title,
          description: step.description,
          longText: step.longText,
          semanticsLabel: step.fallback.semanticLabel,
        ),
      ),
    );

    if (_bubbleOffset == null) {
      return fallback;
    }

    return Stack(
      children: [
        Positioned(
          left: _bubbleOffset!.dx,
          top: _bubbleOffset!.dy,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: step.maxWidth),
            child: _buildTooltipContent(
              key: _bubbleKey,
              title: step.title,
              description: step.description,
              longText: step.longText,
              semanticsLabel: step.semanticsLabel,
              arrowDirection: _arrowDirection,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipContent({
    Key? key,
    required String title,
    required String description,
    String? longText,
    String? semanticsLabel,
    _ArrowDirection arrowDirection = _ArrowDirection.none,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        );

    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
          height: 1.4,
        ) ??
        const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14);

    final semanticLabel = semanticsLabel ?? description;

    final bubble = FocusScope(
      node: FocusScopeNode(),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.hasNext ? widget.onNext() : widget.onDone();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && widget.hasPrevious) {
            widget.onPrevious();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onSkip();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedScale(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(_controller).value,
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: _controller.value,
            duration: const Duration(milliseconds: 200),
            child: Semantics(
              container: true,
              liveRegion: true,
              label: semanticLabel,
              hint: widget.hasNext
                  ? 'Press next or right arrow to continue, escape to skip.'
                  : 'Press done or enter to close, escape to skip.',
              child: Column(
                key: key,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (arrowDirection == _ArrowDirection.down)
                    CustomPaint(
                      painter: _ArrowPainter(color: const Color(0xFF1F1F1F), direction: arrowDirection),
                      size: const Size(24, 12),
                    ),
                  Material(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(16),
                    elevation: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: titleStyle),
                          const SizedBox(height: 8),
                          Text(description, style: bodyStyle),
                          if (longText != null) ...[
                            const SizedBox(height: 8),
                            Text(longText, style: bodyStyle.copyWith(color: Colors.white60)),
                          ],
                          const SizedBox(height: 16),
                          _buildControls(),
                        ],
                      ),
                    ),
                  ),
                  if (arrowDirection != _ArrowDirection.none && arrowDirection != _ArrowDirection.down)
                    CustomPaint(
                      painter: _ArrowPainter(color: const Color(0xFF1F1F1F), direction: arrowDirection),
                      size: const Size(24, 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return bubble;
  }

  Widget _buildControls() {
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    final controls = <Widget>[
      if (widget.hasPrevious)
        TextButton(
          onPressed: widget.onPrevious,
          style: buttonStyle,
          child: const Text('Previous'),
        ),
      const Spacer(),
      TextButton(
        onPressed: widget.onSkip,
        style: buttonStyle.copyWith(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white54),
        ),
        child: const Text('Skip'),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: widget.hasNext ? widget.onNext : widget.onDone,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC24A4A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(widget.hasNext ? 'Next' : 'Done'),
      ),
    ];

    return Row(children: controls);
  }
}

class _PositionResult {
  _PositionResult(this.offset, this.direction);

  final Offset offset;
  final _ArrowDirection direction;
}

class _HighlightData {
  _HighlightData({required this.rect, required this.shape});

  final Rect rect;
  final TutorialHighlightShape shape;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.data);

  final _HighlightData data;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Offset.zero & size);
    Path hole;
    switch (data.shape) {
      case TutorialHighlightShape.circle:
        final radius = max(data.rect.width, data.rect.height) / 2 + 12;
        hole = Path()..addOval(Rect.fromCircle(center: data.rect.center, radius: radius));
        break;
      case TutorialHighlightShape.roundedRect:
        hole = Path()
          ..addRRect(RRect.fromRectAndRadius(data.rect, const Radius.circular(16)));
        break;
      case TutorialHighlightShape.rect:
        hole = Path()..addRect(data.rect);
        break;
    }

    final overlayPath = Path.combine(PathOperation.difference, background, hole);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.data.rect != data.rect || oldDelegate.data.shape != data.shape;
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color, required this.direction});

  final Color color;
  final _ArrowDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    switch (direction) {
      case _ArrowDirection.up:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..close();
        break;
      case _ArrowDirection.down:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();
        break;
      case _ArrowDirection.left:
        path
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        break;
      case _ArrowDirection.right:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close();
        break;
      case _ArrowDirection.none:
        return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction;
  }
}

