import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_models.dart';
import '../utils/api_text_formatter.dart';
import '../widgets/api_fit_image.dart';
import 'crop_detection_screen.dart';

class AgriPlaceholderScreen extends StatelessWidget {
  final AgriTitle agriTitle;

  const AgriPlaceholderScreen({
    super.key,
    required this.agriTitle,
  });

  static Widget buildDirectDetectionScreen(AgriTitle agriTitle) {
    final entry = _buildDetectionEntryFor(agriTitle);
    return CropDetectionScreen(
      category: entry.category,
      crop: entry.crop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(agriTitle.color);
    final entry = _buildDetectionEntryFor(agriTitle);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(
          agriTitle.title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CropDetectionScreen(
                  category: entry.category,
                  crop: entry.crop,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ApiFitImage(
                        imageUrl: agriTitle.imageUrl,
                        fit: BoxFit.cover,
                        fallback: Icon(
                          Icons.image_not_supported_rounded,
                          size: 56,
                          color: color.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ApiTextFormatter.format(agriTitle.title),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to capture or upload image',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CropDetectionScreen(
                            category: entry.category,
                            crop: entry.crop,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: Text(
                        'Upload / Capture',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static _AgriDetectionEntry _buildDetectionEntryFor(AgriTitle agriTitle) {
    final normalizedTitle = agriTitle.normalizedTitle;

    if (agriTitle.id == 2 || normalizedTitle.contains('potted')) {
      return _AgriDetectionEntry(
        category: _buildCategory(agriTitle, 'Potted Plant Disease Scan'),
        crop: _buildCrop(agriTitle, 'Tomato', 'tomato'),
      );
    }
    if (agriTitle.id == 3 || normalizedTitle.contains('plant identification')) {
      return _AgriDetectionEntry(
        category: _buildCategory(agriTitle, 'Plant Identification'),
        crop: _buildCrop(agriTitle, 'Potato', 'potato'),
      );
    }
    if (agriTitle.id == 4 || normalizedTitle.contains('food grains')) {
      return _AgriDetectionEntry(
        category: _buildCategory(agriTitle, 'Food Grains Identification'),
        crop: _buildCrop(agriTitle, 'Brinjal', 'brinjal'),
      );
    }
    return _AgriDetectionEntry(
      category:
          _buildCategory(agriTitle, 'Vegetable & Spinach Identification'),
      crop: _buildCrop(agriTitle, 'Chili', 'chili'),
    );
  }

  static DetectionCategory _buildCategory(
      AgriTitle agriTitle, String fallbackTitle) {
    return DetectionCategory(
      backendId: 0,
      agriId: agriTitle.id,
      agriTitle: agriTitle.title,
      id: 'leaf',
      apiPath: 'leafs',
      title: agriTitle.title.isNotEmpty ? agriTitle.title : fallbackTitle,
      icon: agriTitle.icon,
      color: agriTitle.color,
      crops: const <String>[],
    );
  }

  static CropOption _buildCrop(
      AgriTitle agriTitle, String title, String cropKey) {
    return CropOption(
      id: 0,
      categoryId: 0,
      categoryTitle: agriTitle.title,
      title: title,
      cropKey: cropKey,
    );
  }
}

class _AgriDetectionEntry {
  final DetectionCategory category;
  final CropOption crop;

  const _AgriDetectionEntry({
    required this.category,
    required this.crop,
  });
}
