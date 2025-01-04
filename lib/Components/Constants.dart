import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';

const kTextfielDecoration = InputDecoration(
  fillColor: Colors.white,
  filled: true,
  contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(7.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xffa4392f), width: 1.5),
    borderRadius: BorderRadius.all(Radius.circular(16.0)),
  ),
);

class RoundedButton extends StatelessWidget {
  const RoundedButton(
      {super.key,
      required this.colour,
      required this.title,
      required this.onPressed,
      required this.icon});

  final Color colour;
  final String title;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Material(
        elevation: 10.0,
        color: colour,
        borderRadius: BorderRadius.circular(8.0),
        child: MaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onPressed: onPressed,
          minWidth: 325,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const ArabicTextStyle(
                    arabicFont: ArabicFont.cairo,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(
                width: 7,
              ),
              Icon(
                icon,
                color: Colors.white,
                weight: 12,
              )
            ],
          ),
        ),
      ),
    );
  }
}
