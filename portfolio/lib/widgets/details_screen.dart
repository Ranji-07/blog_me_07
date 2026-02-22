import 'package:flutter/material.dart';

class DetailSection extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? contactController;
  final TextEditingController? messageController;

  const DetailSection({
    super.key,
    required this.text,
    required this.onPressed,
    this.nameController,
    this.emailController,
    this.contactController,
    this.messageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTextField('Your name', nameController),
        const SizedBox(height: 16),
        _buildTextField('Your email', emailController),
        const SizedBox(height: 16),
        _buildTextField('Your Contact', contactController),
        const SizedBox(height: 16),
        _buildTextField('Message', messageController, maxLines: 5),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? Colors.grey.withOpacity(0.5) : const Color(0xFF00C6FF),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF00C6FF).withOpacity(0.5),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController? controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      cursorColor: Colors.white,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}