
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;
  
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth ?? (width != null ? (width! * 2).toInt() : null),
      memCacheHeight: cacheHeight ?? (height != null ? (height! * 2).toInt() : null),
      
      
      placeholder: (context, url) {
        return placeholder ?? Container(
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: width != null ? width! * 0.3 : 40,
              height: height != null ? height! * 0.3 : 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
      
      
      errorWidget: (context, url, error) {
        return errorWidget ?? Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: (width != null ? width! : 48) * 0.5,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  
  const AvatarImage({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Text(
          name?.substring(0, 1) ?? '?',
          style: TextStyle(fontSize: size * 0.5),
        ),
      );
    }
    
    return ClipOval(
      child: OptimizedImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(),
        cacheHeight: (size * 2).toInt(),
      ),
    );
  }
}


class ThumbnailImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  
  const ThumbnailImage({
    super.key,
    this.imageUrl,
    this.size = 80,
  });
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image,
          size: size * 0.5,
          color: Colors.grey.shade400,
        ),
      );
    }
    
    return OptimizedImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * 2).toInt(),
      cacheHeight: (size * 2).toInt(),
    );
  }
}


class ImagePreview extends StatelessWidget {
  final String imageUrl;
  
  const ImagePreview({
    super.key,
    required this.imageUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: OptimizedImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
