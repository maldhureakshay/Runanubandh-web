import 'package:flutter/material.dart';

/// Firebase Storage / cross-origin URLs on Flutter Web fail with default
/// [Image.network] (statusCode 0 / CORS). Uses the HTML img renderer on web.
class AdminNetworkImage extends StatelessWidget {
  const AdminNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    Widget child = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
      errorBuilder: (_, __, ___) =>
          error ??
          SizedBox(
            width: width,
            height: height,
            child: Icon(
              Icons.broken_image_outlined,
              size: (width != null && height != null)
                  ? (width! < height! ? width! : height!) * 0.45
                  : 20,
              color: Colors.grey.shade500,
            ),
          ),
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}
