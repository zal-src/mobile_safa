import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_validators.dart';

// =============================================================================
// AddressForm
// - ฟอร์มที่อยู่สำหรับสัญญา (หมวด 02):
//   บ้านเลขที่, หมู่, ถนน, ตำบล, อำเภอ, จังหวัด, รหัสไปรษณีย์
// =============================================================================

class AddressForm extends StatelessWidget {
  final bool isLoading;
  final TextEditingController houseNumberController;
  final TextEditingController villageController;
  final TextEditingController roadController;
  final TextEditingController subdistrictController;
  final TextEditingController districtController;
  final TextEditingController provinceController;
  final TextEditingController postalCodeController;

  const AddressForm({
    super.key,
    required this.isLoading,
    required this.houseNumberController,
    required this.villageController,
    required this.roadController,
    required this.subdistrictController,
    required this.districtController,
    required this.provinceController,
    required this.postalCodeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // บ้านเลขที่
        TextFormField(
          controller: houseNumberController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'บ้านเลขที่',
            hintText: 'เช่น 123/45',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'กรุณากรอกบ้านเลขที่';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // หมู่ (ไม่บังคับ)
        TextFormField(
          controller: villageController,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'หมู่ (ไม่บังคับ)',
            hintText: 'เช่น 5',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // ถนน (ไม่บังคับ)
        TextFormField(
          controller: roadController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'ถนน (ไม่บังคับ)',
            hintText: 'เช่น ถนนกาญจนวนิช',
            prefixIcon: Icon(Icons.add_road_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // ตำบล / แขวง
        TextFormField(
          controller: subdistrictController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'ตำบล / แขวง',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'กรุณากรอกตำบล / แขวง';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // อำเภอ / เขต
        TextFormField(
          controller: districtController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'อำเภอ / เขต',
            prefixIcon: Icon(Icons.location_city_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'กรุณากรอกอำเภอ / เขต';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // จังหวัด
        TextFormField(
          controller: provinceController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'จังหวัด',
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'กรุณากรอกจังหวัด';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // รหัสไปรษณีย์
        TextFormField(
          controller: postalCodeController,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          maxLength: 5,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: const InputDecoration(
            labelText: 'รหัสไปรษณีย์',
            hintText: 'เช่น 90110',
            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: RegisterValidators.validatePostalCode,
        ),
      ],
    );
  }
}
