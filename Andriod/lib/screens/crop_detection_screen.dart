import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/crop_tips_provider.dart';
import '../providers/detection_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/products_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/api_text_formatter.dart';
import '../utils/app_constants.dart';
import '../utils/detection_localizer.dart';
import '../utils/tts_language_mapper.dart';
import '../widgets/app_skeleton.dart';
import 'wallet_screen.dart';
import '../widgets/api_fit_image.dart';
import '../widgets/fitted_app_text.dart';

class CropDetectionScreen extends ConsumerStatefulWidget {
  final DetectionCategory category;
  final CropOption crop;

  const CropDetectionScreen({
    super.key,
    required this.category,
    required this.crop,
  });

  @override
  ConsumerState<CropDetectionScreen> createState() =>
      _CropDetectionScreenState();
}

class _CropDetectionScreenState extends ConsumerState<CropDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _currentTtsLang;
  String? _resolvedCropImageUrl;

  Color get _headerColor => Color(widget.category.color);

  Color get _headerColorEnd => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.22),
        _headerColor,
      );

  String get _cropLabel => DetectionLocalizer.cropLabel(
        context,
        widget.crop.cropKey,
        fallbackLabel: widget.crop.title,
      );

  String? get _effectiveCropImageUrl {
    final primary = widget.crop.imageUrl?.trim();
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }
    final resolved = _resolvedCropImageUrl?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    return null;
  }

  // --- Regex Helper for formatting (0.91) to 91 seamlessly ---
  String _formatApiDecimalToPercent(String text) {
    return text.replaceAllMapped(RegExp(r'0\.\d+'), (match) {
      final double? val = double.tryParse(match.group(0)!);
      if (val != null) {
        return '${(val * 100).round()}';
      }
      return match.group(0)!;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(detectionProvider.notifier).clearAll();
      ref.read(detectionProvider.notifier).selectCrop(widget.crop.cropKey);
      // ── Load crop-specific tips once on screen open ──────────────────
      ref.read(cropTipsProvider.notifier).fetchForCrop(widget.crop.cropKey);
    });
    _resolveCropImageFromApi();
    _initTts();
  }

  Future<void> _resolveCropImageFromApi({bool force = false}) async {
    if (!force && widget.crop.imageUrl?.trim().isNotEmpty == true) {
      return;
    }

    if (!force && _resolvedCropImageUrl?.trim().isNotEmpty == true) {
      return;
    }

    final api = ref.read(apiServiceProvider);
    final cropRes = await api.getCropSubcategories();
    if (!mounted || !cropRes.isSuccess || cropRes.data == null) {
      return;
    }

    final targetCropKey =
        DetectionCategory.normalizeCropKey(widget.crop.cropKey.trim());
    final targetCategoryKey = DetectionCategory.normalizeCropKey(
      widget.category.id.trim(),
    );

    CropOption? bestMatch;
    for (final option in cropRes.data!) {
      final optionCropKey =
          DetectionCategory.normalizeCropKey(option.cropKey.trim());
      if (optionCropKey != targetCropKey) {
        continue;
      }

      if (option.imageUrl == null || option.imageUrl!.trim().isEmpty) {
        continue;
      }

      final optionCategoryKey =
          _normalizedCategoryKeyFromTitle(option.categoryTitle);

      bestMatch ??= option;
      if (optionCategoryKey == targetCategoryKey) {
        bestMatch = option;
        break;
      }
    }

    if (bestMatch == null || !mounted) {
      return;
    }

    setState(() {
      _resolvedCropImageUrl = bestMatch!.imageUrl;
    });
  }

  Future<void> _refreshCropDetails() async {
    await Future.wait<void>([
      ref.read(cropTipsProvider.notifier).fetchForCrop(
            widget.crop.cropKey,
            force: true,
          ),
      ref.read(productsProvider.notifier).fetch(),
      _resolveCropImageFromApi(force: true),
    ]);
    await ref.read(detectionProvider.notifier).refreshCurrentResultProducts();
  }

  String _normalizedCategoryKeyFromTitle(String rawTitle) {
    final normalized = rawTitle
        .trim()
        .toLowerCase()
        .replaceAll('analyse', 'analyze')
        .replaceAll('analysis', '')
        .replaceAll('analyze', '')
        .replaceAll('detection', '')
        .replaceAll('detector', '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    if (normalized.contains('leaf')) return 'leaf';
    if (normalized.contains('fruit')) return 'fruit';
    if (normalized.contains('flower')) return 'flower';
    if (normalized.contains('veg')) return 'vegetable';
    if (normalized.contains('soil')) return 'soil';
    if (normalized.contains('plant')) return 'plant';
    return DetectionCategory.normalizeCropKey(normalized);
  }

  Future<void> _initTts() async {
    final langCode = ref.read(localeProvider).languageCode;
    _currentTtsLang = await _resolveTtsLanguage(langCode);
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 768,
      );
      if (picked != null && mounted) {
        ref.read(detectionProvider.notifier).setImage(File(picked.path));
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).t('could_not_pick_image'));
    }
  }

  Future<void> _analyze() async {
    if (!ref.read(authProvider.notifier).hasEnoughCredits) {
      _showNoCreditsDialog();
      return;
    }

    final success = await ref.read(detectionProvider.notifier).analyze(
          categoryPath: widget.category.apiPath,
        );

    if (!success && mounted) {
      final error = ref.read(detectionProvider).error;
      if (error != null && error.trim().isNotEmpty) {
        _showSnack(error);
      }
    }
  }

  Future<void> _speak(DetectionResult result) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    final langCode = ref.read(localeProvider).languageCode;
    final ttsLang = await _resolveTtsLanguage(langCode);
    if (_currentTtsLang != ttsLang) {
      if (!mounted) return;
      _currentTtsLang = ttsLang;
    }

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final spokenCropLabel =
        widget.crop.title.trim().isNotEmpty ? widget.crop.title : _cropLabel;

    // Apply decimal-to-percent formatting for TTS as well
    final localizedDiseaseName =
        _formatApiDecimalToPercent(result.diseaseName.trim());
    final localizedDescription = result.description.trim();
    final localizedFertilizers = result.fertilizers;
    final localizedPesticides = result.pesticides;
    final localizedSteps = result.actionSteps;
    final localizedPredictionText =
        _formatApiDecimalToPercent(result.predictionText.trim());
    final localizedSeverity = _localizedSeverity(result.severity);
    final confidence = (result.confidence * 100).clamp(0, 100).round();

    final text = <String>[
      spokenCropLabel,
      '${l.speakResult}: $localizedDiseaseName',
      if (confidence > 0) '${l.confident}: $confidence%',
      if (localizedSeverity.trim().isNotEmpty) localizedSeverity,
      if (localizedPredictionText.trim().isNotEmpty)
        localizedPredictionText.replaceAll('\n', '. '),
      if (localizedDescription.trim().isNotEmpty) localizedDescription,
      if (localizedFertilizers.isNotEmpty)
        '${l.fertilizer}: ${localizedFertilizers.join('. ')}',
      if (localizedPesticides.isNotEmpty)
        '${l.pesticide}: ${localizedPesticides.join('. ')}',
      if (localizedSteps.isNotEmpty)
        '${l.actionSteps}: ${localizedSteps.join('. ')}',
    ].join('. ');

    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  Future<String> _resolveTtsLanguage(String langCode) async {
    final candidates = TtsLanguageMapper.getLanguageCandidates(langCode);

    try {
      final available = await _tts.getLanguages;
      final normalizedAvailable = <String>{
        ...(available ?? const <dynamic>[]).map(
          (item) => item.toString().trim().toLowerCase(),
        ),
      };

      for (final candidate in candidates) {
        final normalizedCandidate = candidate.toLowerCase();
        final candidateBase = normalizedCandidate.split('-').first;
        final matched = normalizedAvailable.any((language) {
          return language == normalizedCandidate ||
              language.startsWith('$normalizedCandidate-') ||
              language == candidateBase ||
              language.startsWith('$candidateBase-');
        });
        if (matched) {
          await _tts.setLanguage(candidate);
          return candidate;
        }
      }
    } catch (_) {
      // Fall through to preferred/fallback languages below.
    }

    for (final candidate in candidates) {
      try {
        await _tts.setLanguage(candidate);
        return candidate;
      } catch (_) {
        // Try the next fallback.
      }
    }

    await _tts.setLanguage('en-IN');
    return 'en-IN';
  }

  void _showImagePicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFFAFAF5),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.t('select_image_source'),
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceBtn(
                      icon: Icons.camera_alt_rounded,
                      label: l.t('camera'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _imageSourceBtn(
                      icon: Icons.photo_library_rounded,
                      label: l.t('gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _headerColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _headerColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _headerColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: _headerColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoCreditsDialog() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFAFAF5),
        title: Text(
          l.notEnoughCredits,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5D4037),
          ),
        ),
        content: Text(
          l.creditsMsg,
          style: GoogleFonts.nunito(color: const Color(0xFF5D4037)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.cancel,
              style: GoogleFonts.nunito(color: const Color(0xFF5D4037)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9A825),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l.addCredits,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5D4037),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(detectionProvider);
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final cropTipsState = ref.watch(cropTipsProvider); // ← separate state
    final l = AppLocalizations.of(context);
    final credits = walletState.credits > 0
        ? walletState.credits
        : (authState.user?.credits ?? 0);

    return Stack(children: [
      Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        body: RefreshIndicator(
          onRefresh: _refreshCropDetails,
          color: const Color(0xFF2E7D32),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App bar ──────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 170,
                floating: false,
                pinned: true,
                backgroundColor: _headerColor,
                leading: Container(
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12, top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFFFB74D)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '$credits',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF5D4037),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipPath(
                    clipper: _CurvedClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_headerColor, _headerColorEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(72, 8, 20, 34),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _CropVisual(
                                      crop: widget.crop,
                                      color: _headerColor,
                                      imageUrl: _effectiveCropImageUrl,
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        _cropLabel,
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l.t('upload_image_detect'),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body content ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedCropCard()
                          .animate()
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 20),

                      _buildImageArea(detectionState)
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 320.ms),

                      const SizedBox(height: 20),

                      if (detectionState.result != null) ...[
                        const SizedBox(height: 14),
                        _buildResultCard(detectionState.result!),
                      ],

                      const SizedBox(height: 40),

                      if (detectionState.selectedImage != null &&
                          detectionState.result == null &&
                          !detectionState.isLoading)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _analyze,
                            icon: const Icon(Icons.search_rounded,
                                color: Colors.white),
                            label: FittedAppText(
                              '${l.t('analyze_image')} (${AppConstants.creditsPerScan} ${l.t('credits_unit')})',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _headerColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: _headerColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ).animate().fadeIn(delay: 140.ms),

                      // 6️⃣ Error banner
                      if (detectionState.error != null &&
                          detectionState.error!.trim().isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF9A825)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFF9A825)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  detectionState.error!,
                                  style: GoogleFonts.nunito(
                                      color: const Color(0xFF5D4037)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      _buildCropTipsSection(cropTipsState, l)
                          .animate()
                          .fadeIn(delay: 60.ms, duration: 350.ms),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (detectionState.isLoading)
        GlassScanningOverlay(message: l.t('analyzing_crop'))
    ]);
  }

  // ── Crop Tips Section ─────────────────────────────────────────────────────

  Widget _buildCropTipsLoadingSkeleton() {
    return SizedBox(
      height: 160,
      child: AppShimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _headerColor.withValues(alpha: 0.12)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSkeletonBox(
                        width: 20,
                        height: 20,
                        shape: BoxShape.circle,
                      ),
                      SizedBox(width: 8),
                      Expanded(child: AppSkeletonBox(height: 14)),
                    ],
                  ),
                  SizedBox(height: 10),
                  AppSkeletonBox(width: double.infinity, height: 10),
                  SizedBox(height: 8),
                  AppSkeletonBox(width: 170, height: 10),
                  SizedBox(height: 8),
                  AppSkeletonBox(width: 150, height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCropTipsSection(CropTipsState tipsState, AppLocalizations l) {
    // Loading
    if (tipsState.isLoading) {
      return _tipsSectionShell(
        l,
        child: _buildCropTipsLoadingSkeleton(),
      );
    }

    // API failed — hide gracefully, don't crash
    if (tipsState.error != null && tipsState.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    // No tips for this crop
    if (tipsState.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _tipsSectionShell(
      l,
      child: SizedBox(
        height: 160,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 4),
            itemCount: tipsState.tips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = tipsState.tips[index];
              return SizedBox(
                width: 220,
                child: _buildTipCard(tip, index),
              );
            }),
      ),
    );
  }

  Widget _tipsSectionShell(AppLocalizations l, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _headerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('💡', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ApiTextFormatter.format(
                        '$_cropLabel ${l.t('farming_tips')}'),
                    softWrap: true,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _headerColor,
                    ),
                  ),
                  Text(
                    l.t('tips_for_better_yield'),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTipCard(CropTip tip, int index) {
    const icons = ['💧', '🌞', '🌿', '🌱', '🌾', '💊', '🔬', '🪴', '☀️', '🧪'];
    final icon = icons[index % icons.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _headerColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: _headerColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  ApiTextFormatter.format(tip.tipTitle),
                  softWrap: true,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: _headerColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              ApiTextFormatter.format(tip.tipDescription),
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: const Color(0xFF5D4037),
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 300.ms);
  }

  // ── Existing widgets (unchanged) ──────────────────────────────────────────

  Widget _buildSelectedCropCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _headerColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _headerColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _CropVisual(
            crop: widget.crop,
            color: _headerColor,
            imageUrl: _effectiveCropImageUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DetectionLocalizer.categoryTitle(
                    context,
                    widget.category.id,
                    fallbackTitle: widget.category.title,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cropLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _headerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(DetectionState state) {
    final l = AppLocalizations.of(context);

    return GestureDetector(
      onTap: _showImagePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: state.selectedImage != null ? 260 : 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: state.selectedImage != null
                ? _headerColor
                : _headerColor.withValues(alpha: 0.25),
            width: state.selectedImage != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: state.selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.file(
                      state.selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(detectionProvider.notifier).clearAll();
                        ref
                            .read(detectionProvider.notifier)
                            .selectCrop(widget.crop.cropKey);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF5D4037).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF5D4037).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              l.t('change'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _headerColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded,
                        size: 48, color: _headerColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.tapUpload,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.t('supports_jpeg_png'),
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: const Color(0xFF9E9E9E)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard(DetectionResult result) {
    final l = AppLocalizations.of(context);

    // Pass API texts through our formatter before localization or display
    final rawDiseaseName =
        DetectionLocalizer.localizeDiseaseName(context, result.diseaseName);
    final localizedDiseaseName = _formatApiDecimalToPercent(rawDiseaseName);

    final localizedDescription = DetectionLocalizer.localizeRecommendationText(
        context, result.description);
    final localizedFertilizers = DetectionLocalizer.localizeRecommendationList(
        context, result.fertilizers);
    final localizedPesticides = DetectionLocalizer.localizeRecommendationList(
        context, result.pesticides);
    final localizedSteps = DetectionLocalizer.localizeRecommendationList(
        context, result.actionSteps);

    final rawPredictionText = DetectionLocalizer.localizePredictionText(
        context, result.predictionText);
    final localizedPredictionText =
        _formatApiDecimalToPercent(rawPredictionText);

    final localizedSeverity = _localizedSeverity(result.severity);
    final confidence = (result.confidence * 100).clamp(0, 100).round();

    return Column(
      children: [
        // Result header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_headerColor, _headerColorEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _headerColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DetectionLocalizer.cropLabel(
                          context, widget.crop.cropKey),
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localizedDiseaseName,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (confidence > 0)
                          _pill('$confidence% ${l.confident}'),
                        if (localizedSeverity.trim().isNotEmpty)
                          _pill(localizedSeverity),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _speak(result),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.14, end: 0),

        if (result.predictedImageUrl != null ||
            result.originalImageUrl != null ||
            result.imageUrl != null) ...[
          const SizedBox(height: 12),
          _buildResultImages(result).animate().fadeIn(delay: 80.ms),
        ],
        if (localizedPredictionText.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('🔬 ${l.t('prediction_label')}', localizedPredictionText)
              .animate()
              .fadeIn(delay: 100.ms),
        ],
        if (_shouldSuggestRescan(result)) ...[
          const SizedBox(height: 12),
          _rescanGuidanceCard(result).animate().fadeIn(delay: 105.ms),
        ],
        if (localizedDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('ℹ️ ${l.t('description_label')}', localizedDescription)
              .animate()
              .fadeIn(delay: 130.ms),
        ],
        if (localizedFertilizers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _solutionSection(
            '🌿 ${l.fertilizer}',
            localizedFertilizers,
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
          ).animate().fadeIn(delay: 160.ms),
        ],
        if (localizedPesticides.isNotEmpty) ...[
          const SizedBox(height: 12),
          _solutionSection(
            '🧪 ${l.pesticide}',
            localizedPesticides,
            const Color(0xFFFFF3E0),
            const Color(0xFFF9A825),
          ).animate().fadeIn(delay: 190.ms),
        ],

        if (localizedSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _solutionSection(
            '📋 ${l.actionSteps}',
            localizedSteps,
            const Color(0xFFE1F5FE),
            const Color(0xFF0288D1),
            numbered: true,
          ).animate().fadeIn(delay: 220.ms),
        ],

        if (result.products.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildProductsList(result.products).animate().fadeIn(delay: 200.ms),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(detectionProvider.notifier).clearAll();
              ref
                  .read(detectionProvider.notifier)
                  .selectCrop(widget.crop.cropKey);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: FittedAppText(
              AppLocalizations.of(context).scanAnother,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _headerColor,
              side: BorderSide(color: _headerColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultImages(DetectionResult result) {
    final imageUrls = <Map<String, String>>[];
    if (result.predictedImageUrl != null &&
        result.predictedImageUrl!.isNotEmpty) {
      imageUrls.add({
        'label': AppLocalizations.of(context).t('predicted_image_label'),
        'url': result.predictedImageUrl!,
      });
    }

    // --- ORIGINAL IMAGE RENDER REMOVED ---
    // if (result.originalImageUrl != null &&
    //     result.originalImageUrl!.isNotEmpty) {
    //   imageUrls.add({
    //     'label': AppLocalizations.of(context).t('original_image_label'),
    //     'url': result.originalImageUrl!,
    //   });
    // }

    if (imageUrls.isEmpty &&
        result.imageUrl != null &&
        result.imageUrl!.isNotEmpty) {
      imageUrls.add({
        'label': AppLocalizations.of(context).t('result_image_label'),
        'url': result.imageUrl!,
      });
    }

    return Column(
      children: imageUrls.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label']!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenResultImage(
                      imageUrl: item['url']!,
                      title: item['label']!,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item['url']!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Ensure we show a placeholder if the URL is broken, rather than shrinking to nothing
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _infoCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _headerColor)),
          const SizedBox(height: 8),
          Text(body,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: const Color(0xFF5D4037), height: 1.5)),
        ],
      ),
    );
  }

  Widget _solutionSection(
    String title,
    List<String> items,
    Color bgColor,
    Color accentColor, {
    bool numbered = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [bgColor, bgColor.withValues(alpha: 0.5)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: accentColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        numbered ? '${entry.key + 1}' : '•',
                        style: GoogleFonts.nunito(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: const Color(0xFF5D4037),
                            height: 1.4)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<ProductRecommendation> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛒 ${AppLocalizations.of(context).t('recommended_products')}',
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w800, color: _headerColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F5),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: _headerColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            product.productImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported_rounded,
                              color: _headerColor.withValues(alpha: 0.3),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            product.productName,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (product.productUrl.isNotEmpty) {
                              final url = Uri.parse(product.productUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_cart_checkout_rounded,
                              size: 16),
                          label: FittedAppText(
                            AppLocalizations.of(context).t('buy_now'),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _localizedSeverity(String severity) {
    final l = AppLocalizations.of(context);
    switch (severity.trim().toLowerCase()) {
      case 'low':
        return l.t('severity_low');
      case 'high':
        return l.t('severity_high');
      case 'moderate':
      case 'medium':
        return l.t('severity_moderate');
      default:
        return severity;
    }
  }

  bool _shouldSuggestRescan(DetectionResult result) {
    if (result.isHealthy) return true;
    return result.confidence > 0 && result.confidence < 0.5;
  }

  Widget _rescanGuidanceCard(DetectionResult result) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF57F17), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _resultMessage(l, result),
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF5D4037),
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resultMessage(AppLocalizations l, DetectionResult result) {
    if (result.isHealthy) {
      return '${l.healthyResult} ${l.scanAnother}';
    }
    return '${l.t('low_confidence_rescan')} ${l.scanAnother}';
  }
}

// ─── Crop visual widget ───────────────────────────────────────────────────────
class _CropVisual extends StatelessWidget {
  final CropOption crop;
  final Color color;
  final String? imageUrl;

  const _CropVisual({
    required this.crop,
    required this.color,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl?.trim();
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: resolvedImageUrl != null && resolvedImageUrl.isNotEmpty
            ? ApiFitImage(
                imageUrl: resolvedImageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                fallback: Icon(Icons.image_not_supported_rounded, color: color),
              )
            : Icon(Icons.image_not_supported_rounded, color: color),
      ),
    );
  }
}

class _FullScreenResultImage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenResultImage({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Curved clipper ───────────────────────────────────────────────────────────
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 28);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
