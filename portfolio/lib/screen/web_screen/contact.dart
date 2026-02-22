import 'package:flutter/material.dart';
import 'package:portfolio/widgets/details_screen.dart';
import 'package:portfolio/widgets/socialmedia_icon.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isSubmitting = false;

  Future<void> submitForm() async {
    // Validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Email validation
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final success = await ApiService.submitContactForm(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        contact: contactController.text.trim(),
        message: messageController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message sent successfully! ✓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form
          nameController.clear();
          emailController.clear();
          contactController.clear();
          messageController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Contact Form & Image
          isMobile 
            ? Column(
                children: [
                  Image.asset(
                    'assets/contact.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 300,
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.contact_mail, size: 80, color: Colors.grey),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  GlassContainer(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    child: DetailSection(
                      nameController: nameController,
                      emailController: emailController,
                      contactController: contactController,
                      messageController: messageController,
                      text: isSubmitting ? "Sending..." : "Send Message",
                      onPressed: isSubmitting ? null : () { submitForm(); },
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Image.asset(
                      'assets/contact.png',
                      width: 500,
                      height: 600,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 500,
                          height: 600,
                          color: Colors.grey.withOpacity(0.2),
                          child: const Icon(Icons.contact_mail, size: 100, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  Flexible(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(40),
                      child: DetailSection(
                        nameController: nameController,
                        emailController: emailController,
                        contactController: contactController,
                        messageController: messageController,
                        text: isSubmitting ? "Sending..." : "Send Message",
                        onPressed: isSubmitting ? null : () { submitForm(); },
                      ),
                    ),
                  ),
                ],
              ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SocialMediaIcon(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Last updated: JAN 2026",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  SizedBox(width: 40),
                  Text(
                    "© 2026 MyPortfolio",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    messageController.dispose();
    super.dispose();
  }
}