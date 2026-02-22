import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' show FaIcon, FontAwesomeIcons;

class SocialMediaIcon extends StatelessWidget {
  const SocialMediaIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon:
              FaIcon(FontAwesomeIcons.squarePhone, color: Colors.blue),
          onPressed: () {
            // Add your Instagram link
          },
        ),
        SizedBox(
          width: 20,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.instagram, color: Colors.blue),
          onPressed: () {
            // Add your Instagram link
          },
        ),
        SizedBox(
          width: 20,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.github, color: Colors.blue),
          onPressed: () {
            // Add your Twitter link
          },
        ),
        SizedBox(
          width: 20,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.linkedin, color: Colors.blue),
          onPressed: () {
            // Add your LinkedIn link
          },
        ),
      ],
    );
  }
}
