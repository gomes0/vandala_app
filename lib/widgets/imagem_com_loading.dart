
import 'package:flutter/material.dart';

class ImagemComLoading extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget placeholder;

  const ImagemComLoading({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      frameBuilder: (context, child, frame, sincronouslyLoaded) {
        if (sincronouslyLoaded || frame != null) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Color(0xFFD90429),
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder;
      },
    );
  }
}
