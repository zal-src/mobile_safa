import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'login_page.dart';

/// หน้าจอเปิดแอป Safa — ออกแบบด้วยแนวคิด Craftsmanship & Human Touch
/// - หลีกเลี่ยงสูตรสำเร็จของ AI (ไม่ใช้จอดำนีออน/ไซเบอร์พังก์/แถบโหลดหลอก)
/// - ใช้โทนสีสว่าง สะอาด สบายตา ตรงตามบริบทของสัญญา Qard Hasan
/// - ตราสัญลักษณ์ "พันธสัญญาแห่งความไว้วางใจ" วาดสดด้วย CustomPainter
/// - ถ่ายทอดข้อความที่อบอุ่น จริงใจ และเชื่อมต่อความรู้สึกของผู้ใช้งาน
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // แอนิเมชันตามลำดับเวลา
  late final Animation<double> _strokeProgress; // 0.0 -> 0.65 เส้นสัญลักษณ์ค่อยๆ วาดขึ้น
  late final Animation<double> _bloomProgress;  // 0.45 -> 0.85 จุดศูนย์กลางคลี่ตัวเบาๆ
  late final Animation<double> _textFade;       // 0.50 -> 0.85 ข้อความปรากฏขึ้นอย่างนุ่มนวล
  late final Animation<Offset> _textSlide;      // 0.50 -> 0.90 เลื่อนขึ้นเล็กน้อยอย่างเป็นธรรมชาติ
  late final Animation<double> _footerFade;     // 0.70 -> 1.00 สโลแกนและคำทักทายด้านล่าง

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    // 1. เส้นสัญลักษณ์ค่อยๆ วาดตัวเอง (Line Tracing Animation)
    _strokeProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.60, curve: Curves.easeInOutCubic),
    );

    // 2. แกนกลางของตราสัญลักษณ์ผลิบานเบาๆ (Center Leaf Bloom)
    _bloomProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOutBack),
    );

    // 3. ชื่อแบรนด์และคำอธิบายค่อยๆ ปรากฏ
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // 4. สโลแกนและความรู้สึกส่วนท้าย
    _footerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToLogin();
      }
    });

    _controller.forward();
  }

  void _navigateToLogin() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // ใช้ FadeTransition ธรรมดาเพื่อความนุ่มนวล ไม่หมุน ไม่เด้งหลอกตา
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page, // สีพื้นหลังสะอาดตา สอดคล้องกับหน้า Login
      body: GestureDetector(
        onTap: _navigateToLogin, // แตะที่ใดก็ได้เพื่อเริ่มใช้งานทันที
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              // -------------------------------------------------------------
              // 1. ลายน้ำบางเบาเชิงวัฒนธรรม (Subtle Geometric Texture)
              // -------------------------------------------------------------
              Positioned.fill(
                child: CustomPaint(
                  painter: _SubtleBackgroundPatternPainter(),
                ),
              ),

              // -------------------------------------------------------------
              // 2. เนื้อหาหลักใจกลางหน้าจอ (Editorial & Human Layout)
              // -------------------------------------------------------------
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // ตราสัญลักษณ์พันธสัญญาที่วาดสดขึ้นมา (Bespoke Seal)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: CustomPaint(
                              painter: TrustSealPainter(
                                strokeProgress: _strokeProgress.value,
                                bloomProgress: _bloomProgress.value,
                                primaryColor: AppColors.primary,
                                accentColor: AppColors.accent,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // กลุ่มชื่อแบรนด์และข้อความแนะนำ
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              // ชื่อภาษาอังกฤษและไทยในจังหวะที่ลงตัว
                              Text(
                                'Safa',
                                style: GoogleFonts.prompt(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ศอฟา • ความบริสุทธิ์และความโปร่งใส',
                                style: GoogleFonts.prompt(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                  letterSpacing: 0.3,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ขีดเส้นคั่นมินิมอลแสดงความประณีต
                              Container(
                                width: 36,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBorder,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // พันธกิจของแอปที่สื่อสารด้วยภาษามนุษย์ ไม่ใช่ภาษาหุ่นยนต์
                              Text(
                                'บันทึกสัญญาเงินกู้ปลอดดอกเบี้ย (Qard Hasan)\nเพื่อรักษาทั้งมิตรภาพและความสบายใจ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.prompt(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.text,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // ---------------------------------------------------------
                      // 3. ส่วนท้ายที่อบอุ่น (Calm Human Footnote)
                      // ---------------------------------------------------------
                      FadeTransition(
                        opacity: _footerFade,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'แตะที่ใดก็ได้เพื่อเริ่มต้น',
                                  style: GoogleFonts.prompt(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Custom Painters: สร้างชิ้นงานเฉพาะตัวด้วยโค้ดคณิตศาสตร์ (Crafted Geometry)
// =============================================================================

/// ตัววาดตราสัญลักษณ์ "The Seal of Trust" (สองเส้นโค้งประสานกันเป็นเมล็ดพันธุ์แห่งความดี)
class TrustSealPainter extends CustomPainter {
  final double strokeProgress; // 0.0 -> 1.0 การวาดเส้นโครงร่าง
  final double bloomProgress;  // 0.0 -> 1.0 การบานของจุดกึ่งกลาง
  final Color primaryColor;
  final Color accentColor;

  TrustSealPainter({
    required this.strokeProgress,
    required this.bloomProgress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // 1. วาดวงแหวนรอบนอกบางเบา
    final ringPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12 * strokeProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius + 8, ringPaint);

    // 2. เส้นโค้งหลัก 2 สายที่โค้งมาพบกัน (ผู้ให้กู้และผู้กู้มาพบกันด้วยความไว้วางใจ)
    final mainPath = Path();

    // สร้างเส้นโค้งเชื่อมสองฝั่ง (Loop of mutual benevolence)
    mainPath.moveTo(center.dx, center.dy - radius);
    mainPath.cubicTo(
      center.dx + radius * 1.1, center.dy - radius * 0.7,
      center.dx + radius * 1.1, center.dy + radius * 0.7,
      center.dx, center.dy + radius,
    );
    mainPath.cubicTo(
      center.dx - radius * 1.1, center.dy + radius * 0.7,
      center.dx - radius * 1.1, center.dy - radius * 0.7,
      center.dx, center.dy - radius,
    );

    // ใช้ PathMetric เพื่อดึงความยาวเส้นตาม progress จริง (Line Drawing Effect)
    if (strokeProgress > 0) {
      final metrics = mainPath.computeMetrics().toList();
      for (final metric in metrics) {
        final extracted = metric.extractPath(0.0, metric.length * strokeProgress);

        final strokePaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0;

        canvas.drawPath(extracted, strokePaint);
      }
    }

    // 3. จุดกึ่งกลาง (The Seed of Barakah / ดอกไม้แห่งความบริสุทธิ์)
    if (bloomProgress > 0) {
      final seedRadius = 5.0 * bloomProgress;

      // เงาเรืองแสงสีทองอบอุ่น
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.35 * bloomProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, seedRadius + 3, glowPaint);

      // เมล็ดแกนกลางสีทอง
      final seedPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, seedRadius, seedPaint);

      // ใบงอกงาม 2 ข้างเล็กๆ
      final leafPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * bloomProgress
        ..strokeCap = StrokeCap.round;

      final leafHeight = 11.0 * bloomProgress;
      canvas.drawLine(
        Offset(center.dx, center.dy - 6),
        Offset(center.dx, center.dy - 6 - leafHeight),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrustSealPainter oldDelegate) {
    return oldDelegate.strokeProgress != strokeProgress ||
        oldDelegate.bloomProgress != bloomProgress;
  }
}

/// ลวดลายพื้นหลังที่แผ่วเบา สไตล์เรขาคณิตลายน้ำแบบกระดาษสา
class _SubtleBackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.42);
    final radii = [60.0, 120.0, 180.0, 240.0];

    for (final r in radii) {
      canvas.drawCircle(center, r, paint);
    }

    // เส้นทแยงมุมบางๆ สร้างจังหวะแบบพิมพ์เขียวศิลป์
    canvas.drawLine(
      Offset(center.dx - 100, center.dy - 100),
      Offset(center.dx + 100, center.dy + 100),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + 100, center.dy - 100),
      Offset(center.dx - 100, center.dy + 100),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
