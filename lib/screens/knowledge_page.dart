import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';

class KnowledgePage extends StatelessWidget {
  final User user;

  const KnowledgePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(),
          const SizedBox(height: 32),
          _buildHeader(),
          const SizedBox(height: 24),
            _buildSection(
              title: 'กฎหมายที่ควรรู้',
              subtitle: 'เข้าใจสิทธิของตัวเอง ป้องกันปัญหาในอนาคต',
              icon: Icons.gavel_rounded,
              iconColor: const Color(0xFF4B39EF),
              iconBgColor: const Color(0xFFEEECFF),
              badgeText: 'ดอกเบี้ย 0%',
              items: [
                _buildGridItem(
                  title: 'สัญญายืมเงิน',
                  subtitle: 'แบบฟอร์มและตัวอย่าง\nสัญญาอย่างถูกต้อง',
                  icon: Icons.description_outlined,
                ),
                _buildGridItem(
                  title: 'สิทธิและหน้าที่',
                  subtitle: 'สิทธิผู้ยืม-ผู้ให้ยืม\nตามกฎหมาย',
                  icon: Icons.balance_outlined,
                ),
                _buildGridItem(
                  title: 'หลักฐานการยืมเงิน',
                  subtitle: 'เอกสารที่ควรเก็บไว้\nเพื่อความปลอดภัย',
                  icon: Icons.folder_open_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'จัดการเงินของฉัน',
              subtitle: 'วางแผนวันนี้ เพื่ออนาคตที่มั่นคง',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF087443),
              iconBgColor: const Color(0xFFE8F7F1),
              badgeText: 'ดอกเบี้ย 0%',
              items: [
                _buildGridItem(
                  title: 'รายรับ-รายจ่าย',
                  subtitle: 'บันทึกรายรับ รายจ่าย\nของคุณ',
                  icon: Icons.receipt_long_outlined,
                ),
                _buildGridItem(
                  title: 'วางแผนเงิน',
                  subtitle: 'ตั้งเป้าหมาย จัดสรร\nให้เหมาะสม',
                  icon: Icons.calendar_month_outlined,
                ),
                _buildGridItem(
                  title: 'เงินสำรองฉุกเฉิน',
                  subtitle: 'เตรียมพร้อมในวันที่\nไม่คาดคิด',
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildListSection(
              title: 'ความรู้เรื่องหนี้',
              subtitle: 'บทความและสาระน่ารู้ เพื่อการเงินที่ดีขึ้น',
              icon: Icons.menu_book_outlined,
              iconColor: const Color(0xFF5A4FCF),
              iconBgColor: const Color(0xFFF1EEFF),
              badgeText: 'ดอกเบี้ย 0%',
              items: [
                _buildListItem(
                  title: 'ก่อนยืมเงินควรเช็กอะไรบ้าง?',
                  subtitle: 'ดูให้รอบด้าน ลดความเสี่ยง สร้างความมั่นใจ',
                  icon: Icons.fact_check_outlined,
                ),
                _buildListItem(
                  title: 'ถ้าชำระไม่ทันควรทำอย่างไร?',
                  subtitle: 'มีทางออก ไม่ใช่จุดจบ มาดูวิธีรับมือกัน',
                  icon: Icons.handshake_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAssessmentBanner(),
          ],
        ),
      );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, color: const Color(0xFF4B6F60), size: 28),
            const SizedBox(width: 8),
            const Text(
              'Qard Hasan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1C3D),
              ),
            ),
          ],
        ),
        const Icon(Icons.notifications_none, size: 28, color: Color(0xFF101828)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ความรู้และการจัดการเงิน',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'รู้สิทธิ วางแผนเงิน จัดการหนี้อย่างมีวินัย',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.eco,
            color: Color(0xFF087443),
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco, color: Color(0xFF087443), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF087443),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                          right: entry.key != items.length - 1 ? 12 : 0),
                      child: entry.value,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco, color: Color(0xFF087443), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF087443),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                        bottom: entry.key != items.length - 1 ? 12 : 0),
                    child: entry.value,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF475467), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF667085),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.chevron_right, size: 18, color: Color(0xFF98A2B3)),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5A4FCF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF98A2B3)),
        ],
      ),
    );
  }

  Widget _buildAssessmentBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF087443).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                color: Color(0xFF087443), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'เช็กสุขภาพการเงิน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'รู้สถานะการเงินของคุณ พร้อมคำแนะนำ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF101828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('เริ่มประเมิน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
