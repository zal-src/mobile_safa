import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ข้อมูลของแต่ละ step ใน spotlight tutorial
class TutorialStep {
  /// ชื่อหัวข้อของ step นี้
  final String title;

  /// คำอธิบายของ step นี้
  final String description;

  /// GlobalKey ของ widget ที่ต้องการ spotlight
  /// ถ้าเป็น null จะแสดงเป็น full-screen tutorial card แทน
  final GlobalKey? targetKey;

  /// padding รอบๆ spotlight (default: 8 ทุกด้าน)
  final EdgeInsets spotlightPadding;

  /// รัศมีมุมโค้งของ spotlight
  final double spotlightRadius;

  const TutorialStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.spotlightPadding = const EdgeInsets.all(8),
    this.spotlightRadius = 16,
  });
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final double spotlightRadius;
  final double animValue;

  _SpotlightPainter({
    required this.spotlightRect,
    required this.spotlightRadius,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Colors.black.withValues(alpha: 0.65 * animValue);
    final overlayPaint = Paint()..color = overlayColor;

    if (spotlightRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
      return;
    }

    // วาด overlay แบบเจาะรู (Path.fillType = evenOdd)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        spotlightRect!,
        Radius.circular(spotlightRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // วาดขอบ spotlight กลอ
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * animValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect!, Radius.circular(spotlightRadius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlightRect != spotlightRect ||
      old.animValue != animValue;
}

// ---------------------------------------------------------------------------
// Main overlay widget
// ---------------------------------------------------------------------------

class SpotlightTutorial extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;

  const SpotlightTutorial({
    super.key,
    required this.steps,
    this.onCompleted,
    this.onSkipped,
  });

  /// แสดง Spotlight Tutorial ทับบนหน้าจอปัจจุบัน
  static Future<void> show(
    BuildContext context, {
    required List<TutorialStep> steps,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
  }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => SpotlightTutorial(
        steps: steps,
        onCompleted: () {
          entry.remove();
          onCompleted?.call();
        },
        onSkipped: () {
          entry.remove();
          onSkipped?.call();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<SpotlightTutorial> createState() => _SpotlightTutorialState();
}

class _SpotlightTutorialState extends State<SpotlightTutorial>
    with TickerProviderStateMixin {
  int _currentStep = 0;

  late AnimationController _overlayCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _spotCtrl;

  late Animation<double> _overlayAnim;
  late Animation<double> _cardAnim;
  late Animation<double> _spotAnim;

  Rect? _spotlightRect;

  @override
  void initState() {
    super.initState();

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _spotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _overlayAnim = CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut);
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack);
    _spotAnim = CurvedAnimation(parent: _spotCtrl, curve: Curves.easeInOut);

    // เริ่ม animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computeSpotlight();
      _overlayCtrl.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _spotCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _cardCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _overlayCtrl.dispose();
    _cardCtrl.dispose();
    _spotCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // คำนวณตำแหน่ง spotlight จาก GlobalKey
  // ---------------------------------------------------------------------------
  void _computeSpotlight() {
    final step = widget.steps[_currentStep];
    if (step.targetKey == null) {
      setState(() => _spotlightRect = null);
      return;
    }

    final key = step.targetKey!;
    final ctx = key.currentContext;
    if (ctx == null) {
      setState(() => _spotlightRect = null);
      return;
    }

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      setState(() => _spotlightRect = null);
      return;
    }

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final padding = step.spotlightPadding;

    setState(() {
      _spotlightRect = Rect.fromLTWH(
        pos.dx - padding.left,
        pos.dy - padding.top,
        size.width + padding.horizontal,
        size.height + padding.vertical,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------
  Future<void> _goNext() async {
    if (_currentStep < widget.steps.length - 1) {
      await _cardCtrl.reverse();
      await _spotCtrl.reverse();
      setState(() => _currentStep++);
      _computeSpotlight();
      _spotCtrl.forward();
      _cardCtrl.forward();
    } else {
      await _dismiss();
      widget.onCompleted?.call();
    }
  }

  Future<void> _goBack() async {
    if (_currentStep > 0) {
      await _cardCtrl.reverse();
      await _spotCtrl.reverse();
      setState(() => _currentStep--);
      _computeSpotlight();
      _spotCtrl.forward();
      _cardCtrl.forward();
    }
  }

  Future<void> _skip() async {
    await _dismiss();
    widget.onSkipped?.call();
  }

  Future<void> _dismiss() async {
    await Future.wait([
      _cardCtrl.reverse(),
      _spotCtrl.reverse(),
    ]);
    await _overlayCtrl.reverse();
  }

  // ---------------------------------------------------------------------------
  // หาตำแหน่งที่ดีที่สุดของ tutorial card
  // ---------------------------------------------------------------------------
  bool get _cardAboveSpotlight {
    if (_spotlightRect == null) return false;
    final screenH = MediaQuery.sizeOf(context).height;
    // ถ้า spotlight อยู่ใต้กึ่งกลางหน้าจอ → card อยู่บน
    return _spotlightRect!.center.dy > screenH * 0.5;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final total = widget.steps.length;
    final isLast = _currentStep == total - 1;
    final isFirst = _currentStep == 0;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _overlayAnim,
        builder: (context, child) {
          return Stack(
            children: [
              // ----- Spotlight overlay -----
              AnimatedBuilder(
                animation: _spotAnim,
                builder: (_, child) => CustomPaint(
                  painter: _SpotlightPainter(
                    spotlightRect: _spotlightRect,
                    spotlightRadius: step.spotlightRadius,
                    animValue: _overlayAnim.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),

              // ----- Tutorial card -----
              Positioned(
                left: 12,
                right: 12,
                bottom: _cardAboveSpotlight
                    ? null
                    : MediaQuery.of(context).padding.bottom + 16,
                top: _cardAboveSpotlight
                    ? MediaQuery.of(context).padding.top + (_spotlightRect?.bottom ?? 0) + 12
                    : null,
              child: AnimatedBuilder(
                animation: _cardAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 20 * (1 - _cardAnim.value)),
                  child: Opacity(
                    opacity: _cardAnim.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: _buildCard(step, total, isFirst, isLast),
              ),
              ),

              // ----- Arrow indicator -----
              if (_spotlightRect != null)
                _buildArrow(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrow() {
    if (_spotlightRect == null) return const SizedBox.shrink();

    final rect = _spotlightRect!;
    final screenH = MediaQuery.sizeOf(context).height;
    final above = _cardAboveSpotlight;

    // ตำแหน่ง arrow ชี้ไปยัง spotlight
    final arrowX = rect.center.dx - 12;
    final arrowY = above ? rect.top - 40 : rect.bottom + 8;

    if (arrowY < 0 || arrowY > screenH) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _spotAnim,
      builder: (_, child) => Positioned(
        left: arrowX.clamp(8.0, MediaQuery.sizeOf(context).width - 32),
        top: arrowY,
        child: Opacity(
          opacity: _spotAnim.value,
          child: Icon(
            above ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(TutorialStep step, int total, bool isFirst, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step counter + close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentStep + 1} / $total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _skip,
                child: const Icon(Icons.close, color: AppColors.muted, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 18),

          // Footer
          Row(
            children: [
              // Skip
              GestureDetector(
                onTap: _skip,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'ข้าม',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Progress dots
              Row(
                children: List.generate(total, (i) {
                  final active = i == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Back
              if (!isFirst) ...[
                OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('กลับ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Next / Done
              FilledButton(
                onPressed: _goNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  minimumSize: Size.zero,
                ),
                child: isLast
                    ? const Text('เริ่มใช้งาน')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('ถัดไป'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
