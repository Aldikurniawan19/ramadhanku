import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Celestial & Atmospheric Time Phase
enum SkyPhase {
  deepNight, // 00:00 - 04:15 (Cosmic midnight / Starlit space - Pure clear starry sky, no clouds)
  fajrDawn, // 04:15 - 05:30 (Subuh - Pre-dawn rose/violet twilight)
  sunrise, // 05:30 - 06:45 (Syuruq / Golden dawn - Warm golden rim clouds)
  morning, // 06:45 - 11:30 (Dhuha / Fresh azure sky - Bright fluffy white clouds)
  noon, // 11:30 - 15:00 (Dzuhur / Brilliant sky - Pure white cumulus clouds)
  afternoon, // 15:00 - 17:15 (Ashar / Warm amber & honey-gold tinted clouds)
  sunset, // 17:15 - 18:30 (Maghrib / Fiery crimson, magenta & burning gold clouds)
  dusk, // 18:30 - 19:45 (Isya / Velvet dusk - Clouds dissolved into starry space)
}

/// Dynamic, Hyper-Realistic, Living Video-Quality Scenic Background
/// Features:
/// - Clean, pristine cinematic sky & sun (all flying particles, motes, and spiky wedges removed for a pure, realistic look)
/// - Ultra-smooth continuous 60/120 FPS frame rendering with zero-jerk timeline
/// - Photorealistic procedural soft-vapor cumulus clouds inspired by natural cloud photography:
///   fluffy organic cauliflower crests, soft milky-dense cores, feathery vapor wisps,
///   dynamic time-of-day lighting (Pagi, Siang, Sore, Senja) and CLEAR STARRY SKY AT NIGHT (no clouds at night)
/// - 4-layer 3D mountain ranges with natural aerial perspective, sunlit ridge crests & drifting valley mist
/// - Central vertical celestial transit (Sun/Moon) through the mountain notch
/// - Multi-tiered Gaussian solar bloom and soft atmospheric scattering
/// - Coastal Islamic architecture with slender minarets, crescent finials & glowing lantern windows
/// - Natural wind-swayed palm trees with multi-jointed trunk & frond physics
/// - Living oceanic water: flowing sinusoidal wave caustics, perspective specular reflection trail,
///   and soft twinkling water glitter sparkles with gentle harmonic breathing
class RealisticSkyBackground extends StatefulWidget {
  final String? subuhTime;
  final String? terbitTime;
  final String? dzuhurTime;
  final String? asharTime;
  final String? maghribTime;
  final String? isyaTime;
  final DateTime? customTime;
  final Widget? child;

  const RealisticSkyBackground({
    super.key,
    this.subuhTime,
    this.terbitTime,
    this.dzuhurTime,
    this.asharTime,
    this.maghribTime,
    this.isyaTime,
    this.customTime,
    this.child,
  });

  @override
  State<RealisticSkyBackground> createState() => _RealisticSkyBackgroundState();
}

class _RealisticSkyBackgroundState extends State<RealisticSkyBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedSeconds = 0.0;
  Duration _lastDuration = Duration.zero;

  // Pre-allocated deterministic particle & simulation data
  late final List<_StarData> _stars;
  late final List<_WaterWaveBand> _waveBands;
  late final List<_ValleyFogData> _valleyFogs;
  late final List<_RealCloudFormation> _cloudFormations;
  late final List<_FlyingBirdData> _birds;

  // Meteor / Shooting star state (Night only)
  double _shootingStarProgress = 1.0;
  Offset _shootingStarStart = const Offset(0.2, 0.08);
  Offset _shootingStarEnd = const Offset(0.7, 0.32);
  double _shootingStarTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _initStars();
    _initWaterSimulation();
    _initValleyFogs();
    _initPhotorealisticClouds();
    _initFlyingBirds();

    _ticker = createTicker((elapsed) {
      if (_lastDuration != Duration.zero) {
        final dt = (elapsed - _lastDuration).inMicroseconds / 1000000.0;
        _elapsedSeconds += dt;
      }
      _lastDuration = elapsed;

      // Periodic meteor update (only active during deep night)
      _shootingStarTimer += 0.016;
      if (_shootingStarTimer > 16.0) {
        final rand = math.Random();
        _shootingStarStart = Offset(
          0.10 + rand.nextDouble() * 0.35,
          0.03 + rand.nextDouble() * 0.12,
        );
        _shootingStarEnd = Offset(
          _shootingStarStart.dx + 0.25 + rand.nextDouble() * 0.20,
          _shootingStarStart.dy + 0.15 + rand.nextDouble() * 0.12,
        );
        _shootingStarProgress = 0.0;
        _shootingStarTimer = 0.0;
      }
      if (_shootingStarProgress < 1.0) {
        _shootingStarProgress += 0.032;
      }

      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initStars() {
    final rand = math.Random(2026);
    _stars = List.generate(85, (i) {
      return _StarData(
        x: rand.nextDouble(),
        y: rand.nextDouble() * 0.45,
        radius: 0.4 + rand.nextDouble() * 1.5,
        twinkleSpeed: 1.0 + rand.nextDouble() * 3.0,
        phaseOffset: rand.nextDouble() * math.pi * 2,
        isMajorStar: i % 6 == 0,
        hueShift: rand.nextDouble() * 0.4,
      );
    });
  }

  void _initWaterSimulation() {
    final rand = math.Random(999);

    _waveBands = List.generate(42, (i) {
      final yNorm = (i + 1) / 43.0;
      return _WaterWaveBand(
        yRel: yNorm,
        speed: 0.9 + (rand.nextDouble() * 1.5),
        frequency: 0.016 + (rand.nextDouble() * 0.020),
        phase: rand.nextDouble() * math.pi * 2,
        secondaryFrequency: 0.034 + (rand.nextDouble() * 0.030),
        secondaryPhase: rand.nextDouble() * math.pi * 2,
        amplitude: 0.6 + (yNorm * 2.6),
        thickness: 0.6 + (yNorm * 2.2),
      );
    });
  }

  void _initValleyFogs() {
    final rand = math.Random(777);
    _valleyFogs = List.generate(5, (i) {
      return _ValleyFogData(
        yRel: 0.58 + (i * 0.025),
        speed: 0.06 + (i * 0.025),
        height: 12.0 + (i * 5.0),
        phase: rand.nextDouble() * math.pi * 2,
        opacity: 0.16 + rand.nextDouble() * 0.12,
      );
    });
  }

  /// Builds photorealistic procedural cloud formations matching natural cloud photography
  void _initPhotorealisticClouds() {
    _RealCloudFormation buildCloud({
      required double xRel,
      required double yRel,
      required double scale,
      required double driftSpeed,
      required double cyclePeriod,
      required double phaseOffset,
      required double morphSpeed,
      required double morphPhase,
      required int seed,
      required bool isFacingLeft,
    }) {
      final rand = math.Random(seed);
      final nodes = <_CloudVaporNode>[];

      // 1. Broad Soft Stratum Foundation (Flat-bottomed atmospheric layer)
      for (int i = 0; i < 7; i++) {
        final ox = (i - 3.0) * 16.0 * scale;
        final oy = (3.0 + rand.nextDouble() * 7.0) * scale;
        nodes.add(_CloudVaporNode(
          offsetX: ox,
          offsetY: oy,
          radiusX: (36.0 + rand.nextDouble() * 18.0) * scale,
          radiusY: (14.0 + rand.nextDouble() * 8.0) * scale,
          blur: 16.0 * scale,
          opacity: 0.52 + rand.nextDouble() * 0.18,
          isSunlitCrest: false,
          isFoundation: true,
        ));
      }

      // 2. Dense Internal Milky Volume (Fluffy body mass)
      for (int i = 0; i < 15; i++) {
        final ox = (rand.nextDouble() - 0.5) * 85.0 * scale;
        final oy = (-5.0 + (rand.nextDouble() - 0.5) * 18.0) * scale;
        nodes.add(_CloudVaporNode(
          offsetX: ox,
          offsetY: oy,
          radiusX: (22.0 + rand.nextDouble() * 14.0) * scale,
          radiusY: (15.0 + rand.nextDouble() * 10.0) * scale,
          blur: 9.5 * scale,
          opacity: 0.78 + rand.nextDouble() * 0.18,
          isSunlitCrest: false,
        ));
      }

      // 3. Cauliflower Micro-Crests (Billowy bumpy tops with sunlit highlights)
      for (int i = 0; i < 18; i++) {
        final t = (i / 17.0);
        final ox = (-48.0 + t * 96.0 + (rand.nextDouble() - 0.5) * 8.0) * scale;
        final domeHeight = math.sin(t * math.pi) * 19.0;
        final oy = (-11.0 - domeHeight + (rand.nextDouble() - 0.5) * 7.0) * scale;

        nodes.add(_CloudVaporNode(
          offsetX: ox,
          offsetY: oy,
          radiusX: (13.0 + rand.nextDouble() * 10.0) * scale,
          radiusY: (11.0 + rand.nextDouble() * 8.0) * scale,
          blur: 4.8 * scale,
          opacity: 0.92 + rand.nextDouble() * 0.08,
          isSunlitCrest: true,
        ));
      }

      // 4. Feathery Vapor Tendrils / Wisps (Soft edges evaporating into sky)
      for (int i = 0; i < 8; i++) {
        final isLeftEdge = i % 2 == 0;
        final ox = (isLeftEdge ? -52.0 - rand.nextDouble() * 24.0 : 52.0 + rand.nextDouble() * 24.0) * scale;
        final oy = (-3.0 + (rand.nextDouble() - 0.5) * 14.0) * scale;
        nodes.add(_CloudVaporNode(
          offsetX: ox,
          offsetY: oy,
          radiusX: (15.0 + rand.nextDouble() * 12.0) * scale,
          radiusY: (7.0 + rand.nextDouble() * 5.0) * scale,
          blur: 8.0 * scale,
          opacity: 0.28 + rand.nextDouble() * 0.22,
          isSunlitCrest: false,
          isVaporWisp: true,
        ));
      }

      return _RealCloudFormation(
        xRel: xRel,
        yRel: yRel,
        scale: scale,
        driftSpeed: driftSpeed,
        cyclePeriod: cyclePeriod,
        phaseOffset: phaseOffset,
        morphSpeed: morphSpeed,
        morphPhase: morphPhase,
        isFacingLeft: isFacingLeft,
        nodes: nodes,
      );
    }

    _cloudFormations = [
      // 1. Upper Left Majestic Cumulus (Infrequent serene drift cycle)
      buildCloud(
        xRel: 0.16,
        yRel: 0.23,
        scale: 1.15,
        driftSpeed: 0.007,
        cyclePeriod: 68.0,
        phaseOffset: 0.0,
        morphSpeed: 0.20,
        morphPhase: 0.0,
        seed: 301,
        isFacingLeft: false,
      ),
      // 2. Mid Right Billowing Cloud Bank (Infrequent serene drift cycle)
      buildCloud(
        xRel: 0.84,
        yRel: 0.27,
        scale: 1.25,
        driftSpeed: -0.006,
        cyclePeriod: 76.0,
        phaseOffset: math.pi * 0.85,
        morphSpeed: 0.18,
        morphPhase: 1.4,
        seed: 402,
        isFacingLeft: true,
      ),
      // 3. Lower Left Stratocumulus Shelf (Infrequent serene drift cycle)
      buildCloud(
        xRel: 0.22,
        yRel: 0.43,
        scale: 0.95,
        driftSpeed: 0.008,
        cyclePeriod: 62.0,
        phaseOffset: math.pi * 1.55,
        morphSpeed: 0.22,
        morphPhase: 2.5,
        seed: 503,
        isFacingLeft: false,
      ),
      // 4. Lower Right Horizon Cloud (Infrequent serene drift cycle)
      buildCloud(
        xRel: 0.78,
        yRel: 0.45,
        scale: 1.00,
        driftSpeed: -0.007,
        cyclePeriod: 82.0,
        phaseOffset: math.pi * 0.45,
        morphSpeed: 0.19,
        morphPhase: 3.7,
        seed: 604,
        isFacingLeft: true,
      ),
      // 5. Small High Drifting Wisps in Central Sky (Infrequent serene drift cycle)
      buildCloud(
        xRel: 0.50,
        yRel: 0.15,
        scale: 0.65,
        driftSpeed: 0.005,
        cyclePeriod: 58.0,
        phaseOffset: math.pi * 1.20,
        morphSpeed: 0.15,
        morphPhase: 4.8,
        seed: 705,
        isFacingLeft: false,
      ),
    ];
  }

  void _initFlyingBirds() {
    // Graceful avian flock flying directly across the golden afternoon sun (16:00 - sunset)
    _birds = [
      // 1. Flock Leader (Cuts right across the upper half of the sun disc)
      _FlyingBirdData(
        xOffsetRel: 0.50,
        yOffsetRel: -0.15, // -7px relative to sun center
        scale: 1.10,
        speed: 0.024,
        flapSpeed: 3.2,
        flapPhase: 0.0,
        glideCyclePeriod: 5.5,
        glidePhase: 0.0,
        flightPathYAmplitude: 3.0,
      ),
      // 2. Left Flank Inner (Cuts right across the center-upper corona)
      _FlyingBirdData(
        xOffsetRel: 0.43,
        yOffsetRel: -0.35, // -17px relative to sun center
        scale: 1.00,
        speed: 0.024,
        flapSpeed: 3.4,
        flapPhase: 0.75,
        glideCyclePeriod: 5.2,
        glidePhase: 1.2,
        flightPathYAmplitude: 2.8,
      ),
      // 3. Right Flank Inner (Cuts right across the lower half of the sun disc)
      _FlyingBirdData(
        xOffsetRel: 0.57,
        yOffsetRel: 0.15, // +7px relative to sun center
        scale: 0.98,
        speed: 0.024,
        flapSpeed: 3.1,
        flapPhase: 1.4,
        glideCyclePeriod: 5.8,
        glidePhase: 2.1,
        flightPathYAmplitude: 3.0,
      ),
      // 4. Left Flank Outer (Cuts across the top sun corona)
      _FlyingBirdData(
        xOffsetRel: 0.36,
        yOffsetRel: -0.55, // -26px relative to sun center
        scale: 0.90,
        speed: 0.024,
        flapSpeed: 3.5,
        flapPhase: 2.2,
        glideCyclePeriod: 5.0,
        glidePhase: 3.0,
        flightPathYAmplitude: 2.6,
      ),
      // 5. Right Flank Outer (Cuts across the lower sun corona)
      _FlyingBirdData(
        xOffsetRel: 0.64,
        yOffsetRel: 0.40, // +19px relative to sun center
        scale: 0.88,
        speed: 0.024,
        flapSpeed: 3.3,
        flapPhase: 2.9,
        glideCyclePeriod: 5.4,
        glidePhase: 4.1,
        flightPathYAmplitude: 2.7,
      ),
      // 6. Trailing High Bird (Above sun corona)
      _FlyingBirdData(
        xOffsetRel: 0.47,
        yOffsetRel: -0.75, // -36px relative to sun center
        scale: 0.78,
        speed: 0.023,
        flapSpeed: 3.6,
        flapPhase: 4.1,
        glideCyclePeriod: 4.8,
        glidePhase: 1.8,
        flightPathYAmplitude: 2.4,
      ),
      // 7. Trailing Low Bird (Below sun disc)
      _FlyingBirdData(
        xOffsetRel: 0.30,
        yOffsetRel: 0.60, // +29px relative to sun center
        scale: 0.74,
        speed: 0.024,
        flapSpeed: 3.7,
        flapPhase: 5.2,
        glideCyclePeriod: 5.1,
        glidePhase: 2.7,
        flightPathYAmplitude: 2.2,
      ),
    ];
  }

  _SkyStateData _calculateSkyState() {
    final now = widget.customTime ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute + (now.second / 60.0);

    int parseTimeStr(String? timeStr, int defaultMinutes) {
      if (timeStr == null || !timeStr.contains(':')) return defaultMinutes;
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    final subuhM = parseTimeStr(widget.subuhTime, 4 * 60 + 38);
    final terbitM = parseTimeStr(widget.terbitTime, 5 * 60 + 50);
    final dzuhurM = parseTimeStr(widget.dzuhurTime, 11 * 60 + 58);
    final asharM = parseTimeStr(widget.asharTime, 15 * 60 + 12);
    final maghribM = parseTimeStr(widget.maghribTime, 18 * 60 + 5);
    final isyaM = parseTimeStr(widget.isyaTime, 19 * 60 + 15);

    final isDaytime = currentMinutes >= terbitM && currentMinutes <= maghribM;

    SkyPhase currentPhase;
    SkyPhase nextPhase;
    double progress = 0.0;

    final dawnStart = subuhM - 25;
    final morningStart = terbitM + 60;
    final noonStart = dzuhurM - 30;
    final sunsetStart = maghribM - 40;
    final duskStart = maghribM + 35;
    final nightStart = isyaM + 45;

    if (currentMinutes < dawnStart) {
      currentPhase = SkyPhase.deepNight;
      nextPhase = SkyPhase.fajrDawn;
      final totalNightSpan = (1440 - nightStart) + dawnStart;
      double elapsed;
      if (currentMinutes >= nightStart) {
        elapsed = currentMinutes - nightStart;
      } else {
        elapsed = (1440 - nightStart) + currentMinutes;
      }
      progress = (elapsed / totalNightSpan).clamp(0.0, 1.0);
    } else if (currentMinutes < terbitM) {
      currentPhase = SkyPhase.fajrDawn;
      nextPhase = SkyPhase.sunrise;
      progress = ((currentMinutes - dawnStart) / (terbitM - dawnStart)).clamp(0.0, 1.0);
    } else if (currentMinutes < morningStart) {
      currentPhase = SkyPhase.sunrise;
      nextPhase = SkyPhase.morning;
      progress = ((currentMinutes - terbitM) / (morningStart - terbitM)).clamp(0.0, 1.0);
    } else if (currentMinutes < noonStart) {
      currentPhase = SkyPhase.morning;
      nextPhase = SkyPhase.noon;
      progress = ((currentMinutes - morningStart) / (noonStart - morningStart)).clamp(0.0, 1.0);
    } else if (currentMinutes < asharM) {
      currentPhase = SkyPhase.noon;
      nextPhase = SkyPhase.afternoon;
      progress = ((currentMinutes - noonStart) / (asharM - noonStart)).clamp(0.0, 1.0);
    } else if (currentMinutes < sunsetStart) {
      currentPhase = SkyPhase.afternoon;
      nextPhase = SkyPhase.sunset;
      progress = ((currentMinutes - asharM) / (sunsetStart - asharM)).clamp(0.0, 1.0);
    } else if (currentMinutes < duskStart) {
      currentPhase = SkyPhase.sunset;
      nextPhase = SkyPhase.dusk;
      progress = ((currentMinutes - sunsetStart) / (duskStart - sunsetStart)).clamp(0.0, 1.0);
    } else if (currentMinutes < nightStart) {
      currentPhase = SkyPhase.dusk;
      nextPhase = SkyPhase.deepNight;
      progress = ((currentMinutes - duskStart) / (nightStart - duskStart)).clamp(0.0, 1.0);
    } else {
      currentPhase = SkyPhase.deepNight;
      nextPhase = SkyPhase.fajrDawn;
      final totalNightSpan = (1440 - nightStart) + dawnStart;
      final elapsed = currentMinutes - nightStart;
      progress = (elapsed / totalNightSpan).clamp(0.0, 1.0);
    }

    final paletteA = SkyThemePalette.getPaletteForPhase(currentPhase);
    final paletteB = SkyThemePalette.getPaletteForPhase(nextPhase);
    final palette = SkyThemePalette.lerp(paletteA, paletteB, progress);

    double sunProgress = 0.0;
    if (isDaytime) {
      final totalDayMinutes = (maghribM - terbitM).toDouble();
      sunProgress = ((currentMinutes - terbitM) / totalDayMinutes).clamp(0.0, 1.0);
    }

    double moonProgress = 0.0;
    if (!isDaytime) {
      final totalNightMinutes = (1440 - maghribM + terbitM).toDouble();
      double elapsedNight;
      if (currentMinutes >= maghribM) {
        elapsedNight = currentMinutes - maghribM;
      } else {
        elapsedNight = (1440 - maghribM) + currentMinutes;
      }
      moonProgress = (elapsedNight / totalNightMinutes).clamp(0.0, 1.0);
    }

    // Flying birds are visible strictly during late afternoon (16:00 / 4 PM) until sunset (maghrib)
    final birdStartM = 16 * 60; // 16:00 (Jam 4 sore)
    double birdVisibility = 0.0;
    if (currentMinutes >= birdStartM && currentMinutes <= maghribM) {
      final fadeIn = ((currentMinutes - birdStartM) / 2.0).clamp(0.0, 1.0);
      final fadeOut = ((maghribM - currentMinutes) / 2.0).clamp(0.0, 1.0);
      birdVisibility = math.min(fadeIn, fadeOut);
    }

    return _SkyStateData(
      phase: currentPhase,
      phaseProgress: progress,
      isDaytime: isDaytime,
      sunProgress: sunProgress,
      moonProgress: moonProgress,
      palette: palette,
      currentMinutes: currentMinutes,
      terbitTimeStr: widget.terbitTime ?? '05:58',
      maghribTimeStr: widget.maghribTime ?? '18:07',
      birdVisibility: birdVisibility,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skyState = _calculateSkyState();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CinematicScenicPainter(
          skyState: skyState,
          elapsedSeconds: _elapsedSeconds,
          stars: _stars,
          waveBands: _waveBands,
          valleyFogs: _valleyFogs,
          cloudFormations: _cloudFormations,
          birds: _birds,
          shootingStarProgress: _shootingStarProgress,
          shootingStarStart: _shootingStarStart,
          shootingStarEnd: _shootingStarEnd,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Rich atmospheric color palette for a specific time phase
class SkyThemePalette {
  final List<Color> skyGradientColors;
  final List<double> skyStops;
  final List<Color> sunDiscColors;
  final Color sunGlowOuter;
  final Color sunGlowMid;
  final Color sunGlowCore;
  final Color cloudHighlight;
  final Color cloudBody;
  final Color cloudShadow;
  final double cloudOpacity;
  final Color distantMountainColor;
  final Color midMountainColor;
  final Color mountainFacetHighlight;
  final Color foreMountainColor;
  final Color mosqueSilhouetteColor;
  final double windowGlowOpacity;
  final List<Color> waterColors;
  final Color waterMistColor;
  final Color waterReflectionGlow;
  final Color ripplePrimary;
  final Color rippleSecondary;
  final Color sparkleColor;
  final double starVisibility;
  final Color fogColor;
  final bool isMoon;

  SkyThemePalette({
    required this.skyGradientColors,
    required this.skyStops,
    required this.sunDiscColors,
    required this.sunGlowOuter,
    required this.sunGlowMid,
    required this.sunGlowCore,
    required this.cloudHighlight,
    required this.cloudBody,
    required this.cloudShadow,
    required this.cloudOpacity,
    required this.distantMountainColor,
    required this.midMountainColor,
    required this.mountainFacetHighlight,
    required this.foreMountainColor,
    required this.mosqueSilhouetteColor,
    required this.windowGlowOpacity,
    required this.waterColors,
    required this.waterMistColor,
    required this.waterReflectionGlow,
    required this.ripplePrimary,
    required this.rippleSecondary,
    required this.sparkleColor,
    required this.starVisibility,
    required this.fogColor,
    required this.isMoon,
  });

  static SkyThemePalette getPaletteForPhase(SkyPhase phase) {
    switch (phase) {
      // 1. FAJR / SUBUH (04:15 - 05:30: Pre-Dawn Rose-Violet Twilight)
      case SkyPhase.fajrDawn:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF030818), // Midnight cosmic zenith
            Color(0xFF091636), // Deep pre-dawn indigo
            Color(0xFF162354), // Twilight sapphire
            Color(0xFF322668), // Velvet royal mauve
            Color(0xFF5E3970), // Soft pre-dawn violet
            Color(0xFFA84E70), // Dawn rose-apricot
            Color(0xFFFF9478), // Warm glowing peach horizon notch
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFE0B2),
            Color(0xFFFFAB91),
            Color(0xFFFF7043),
          ],
          sunGlowOuter: const Color(0xFFFF8E78),
          sunGlowMid: const Color(0xFFFFAB91),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFD180),
          cloudBody: const Color(0xFFE8D5E5),
          cloudShadow: const Color(0xFF4A2E59),
          cloudOpacity: 0.65,
          distantMountainColor: const Color(0xFF7A4468),
          midMountainColor: const Color(0xFF261D42),
          mountainFacetHighlight: const Color(0xFF4E3768),
          foreMountainColor: const Color(0xFF130D22),
          mosqueSilhouetteColor: const Color(0xFF0B0716),
          windowGlowOpacity: 0.88,
          waterColors: const [
            Color(0xFF161938),
            Color(0xFF10132C),
            Color(0xFF0B0D20),
            Color(0xFF060712),
          ],
          waterMistColor: const Color(0xFFFF8A65),
          waterReflectionGlow: const Color(0xFFFF7043),
          ripplePrimary: const Color(0xFFFFD180),
          rippleSecondary: const Color(0xFFFF8A65),
          sparkleColor: const Color(0xFFFFE0B2),
          starVisibility: 0.15,
          fogColor: const Color(0xFFFFAB91),
          isMoon: false,
        );

      // 2. SUNRISE / SYURUQ (05:30 - 06:45: Golden Dawn & Morning Azure)
      case SkyPhase.sunrise:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF08224C), // Deep morning sapphire zenith
            Color(0xFF12437E), // Cobalt blue
            Color(0xFF226EBA), // Rich sky azure
            Color(0xFF4598D8), // Radiant cerulean
            Color(0xFF7AC5EC), // Morning mist cyan
            Color(0xFFF6B84A), // Warm golden amber horizon
            Color(0xFFFFE696), // Luminous butter-gold sun notch
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFDE7),
            Color(0xFFFFF59D),
            Color(0xFFFFD54F),
          ],
          sunGlowOuter: const Color(0xFFFFD54F),
          sunGlowMid: const Color(0xFFFFF9C4),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFF8D0),
          cloudBody: const Color(0xFFF4F9FD),
          cloudShadow: const Color(0xFF3E6686),
          cloudOpacity: 0.95,
          distantMountainColor: const Color(0xFFDE984A),
          midMountainColor: const Color(0xFF24507C),
          mountainFacetHighlight: const Color(0xFF3C72A6),
          foreMountainColor: const Color(0xFF122E4A),
          mosqueSilhouetteColor: const Color(0xFF0B2036),
          windowGlowOpacity: 0.25,
          waterColors: const [
            Color(0xFF14477A),
            Color(0xFF0F3660),
            Color(0xFF0B2444),
            Color(0xFF06152B),
          ],
          waterMistColor: const Color(0xFFFFD54F),
          waterReflectionGlow: const Color(0xFFFFB300),
          ripplePrimary: const Color(0xFFFFF9C4),
          rippleSecondary: const Color(0xFFFFCA28),
          sparkleColor: const Color(0xFFFFFFFF),
          starVisibility: 0.0,
          fogColor: const Color(0xFFFFE082),
          isMoon: false,
        );

      // 3. MORNING / DHUHA (06:45 - 11:30: Fresh Radiant Azure Sky)
      case SkyPhase.morning:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF0B3F82), // Deep azure zenith
            Color(0xFF155EAC), // Vibrant sky cobalt
            Color(0xFF257FD8), // Radiant azure
            Color(0xFF459FE8), // Brilliant tropical blue
            Color(0xFF76C4F4), // Soft sky mist
            Color(0xFFAEE2FC), // Luminous atmospheric cyan haze
            Color(0xFFFFF6D8), // Warm sunlit mountain notch
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFE0),
            Color(0xFFFFF59D),
            Color(0xFFFFEE58),
          ],
          sunGlowOuter: const Color(0xFFFFEE58),
          sunGlowMid: const Color(0xFFFFFDE7),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFFFFF),
          cloudBody: const Color(0xFFF8FBFE),
          cloudShadow: const Color(0xFF5E8EA8),
          cloudOpacity: 1.0,
          distantMountainColor: const Color(0xFF6EAFDE),
          midMountainColor: const Color(0xFF24669E),
          mountainFacetHighlight: const Color(0xFF468DC6),
          foreMountainColor: const Color(0xFF14406A),
          mosqueSilhouetteColor: const Color(0xFF0C2C4C),
          windowGlowOpacity: 0.0,
          waterColors: const [
            Color(0xFF1A609E),
            Color(0xFF124B80),
            Color(0xFF0C3660),
            Color(0xFF072342),
          ],
          waterMistColor: const Color(0xFFB3E5FC),
          waterReflectionGlow: const Color(0xFFFFE082),
          ripplePrimary: const Color(0xFFFFFFFF),
          rippleSecondary: const Color(0xFFFFF176),
          sparkleColor: const Color(0xFFFFFFFF),
          starVisibility: 0.0,
          fogColor: const Color(0xFFE1F5FE),
          isMoon: false,
        );

      // 4. NOON / DZUHUR (11:30 - 15:00: Brilliant Royal Azure & Pure White Cumulus)
      case SkyPhase.noon:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF083C7E), // Deep royal blue zenith
            Color(0xFF1058A4), // Deep sky blue
            Color(0xFF1E75CA), // Brilliant azure
            Color(0xFF3893E0), // Vibrant cyan-blue
            Color(0xFF6AB6EC), // Radiant soft cyan
            Color(0xFF9ED5F6), // Luminous horizon mist
            Color(0xFFFFFBE8), // Luminous solar horizon
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFDE7),
            Color(0xFFFFF59D),
          ],
          sunGlowOuter: const Color(0xFFFFF59D),
          sunGlowMid: const Color(0xFFFFFFFF),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFFFFF),
          cloudBody: const Color(0xFFFFFFFF),
          cloudShadow: const Color(0xFF7CAFC8),
          cloudOpacity: 1.0,
          distantMountainColor: const Color(0xFF65AFE0),
          midMountainColor: const Color(0xFF20609C),
          mountainFacetHighlight: const Color(0xFF4489C8),
          foreMountainColor: const Color(0xFF123B64),
          mosqueSilhouetteColor: const Color(0xFF0B2844),
          windowGlowOpacity: 0.0,
          waterColors: const [
            Color(0xFF145E9E),
            Color(0xFF0D487D),
            Color(0xFF08335D),
            Color(0xFF04203D),
          ],
          waterMistColor: const Color(0xFFE1F5FE),
          waterReflectionGlow: const Color(0xFFFFFFFF),
          ripplePrimary: const Color(0xFFFFFFFF),
          rippleSecondary: const Color(0xFFE0F7FA),
          sparkleColor: const Color(0xFFFFFFFF),
          starVisibility: 0.0,
          fogColor: const Color(0xFFFFFFFF),
          isMoon: false,
        );

      // 5. AFTERNOON / ASHAR (15:00 - 17:15: Warm Honey-Gold & Topaz Horizon)
      case SkyPhase.afternoon:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF0D2D58), // Deepening afternoon cobalt zenith
            Color(0xFF18457D), // Deep blue
            Color(0xFF27609E), // Warm azure
            Color(0xFF4B80B2), // Mellow sky blue
            Color(0xFF8A9580), // Warm atmospheric golden haze
            Color(0xFFDDA248), // Warm amber honey horizon
            Color(0xFFFFCE68), // Radiant golden topaz notch
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFDE7),
            Color(0xFFFFE082),
            Color(0xFFFFB74D),
          ],
          sunGlowOuter: const Color(0xFFFFB74D),
          sunGlowMid: const Color(0xFFFFE082),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFE082),
          cloudBody: const Color(0xFFF6F0EC),
          cloudShadow: const Color(0xFF4E596E),
          cloudOpacity: 0.95,
          distantMountainColor: const Color(0xFFC0823C),
          midMountainColor: const Color(0xFF2E4C74),
          mountainFacetHighlight: const Color(0xFF52749E),
          foreMountainColor: const Color(0xFF172D48),
          mosqueSilhouetteColor: const Color(0xFF0E2034),
          windowGlowOpacity: 0.15,
          waterColors: const [
            Color(0xFF163E66),
            Color(0xFF103052),
            Color(0xFF0B223D),
            Color(0xFF061529),
          ],
          waterMistColor: const Color(0xFFFFCA28),
          waterReflectionGlow: const Color(0xFFFFB300),
          ripplePrimary: const Color(0xFFFFF9C4),
          rippleSecondary: const Color(0xFFFFB74D),
          sparkleColor: const Color(0xFFFFFAEB),
          starVisibility: 0.0,
          fogColor: const Color(0xFFFFCA28),
          isMoon: false,
        );

      // 6. SUNSET / MAGHRIB (17:15 - 18:30: Fiery Crimson, Magenta & Burning Gold)
      case SkyPhase.sunset:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF080F30), // Deep cosmic indigo zenith
            Color(0xFF18184C), // Midnight violet
            Color(0xFF381C60), // Royal purple
            Color(0xFF702368), // Rich magenta-crimson
            Color(0xFFB42C54), // Burning ruby red
            Color(0xFFE44E2E), // Fiery sunset orange
            Color(0xFFFF9534), // Blazing horizon gold
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFE082),
            Color(0xFFFF7043),
            Color(0xFFD84315),
          ],
          sunGlowOuter: const Color(0xFFFF5722),
          sunGlowMid: const Color(0xFFFFAB40),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFFFAB40),
          cloudBody: const Color(0xFFE48470),
          cloudShadow: const Color(0xFF441838),
          cloudOpacity: 0.90,
          distantMountainColor: const Color(0xFFBE3C32),
          midMountainColor: const Color(0xFF321840),
          mountainFacetHighlight: const Color(0xFF5E2762),
          foreMountainColor: const Color(0xFF160B20),
          mosqueSilhouetteColor: const Color(0xFF0E0616),
          windowGlowOpacity: 0.85,
          waterColors: const [
            Color(0xFF1A1438),
            Color(0xFF130E2C),
            Color(0xFF0C0920),
            Color(0xFF070514),
          ],
          waterMistColor: const Color(0xFFFF5722),
          waterReflectionGlow: const Color(0xFFFF7043),
          ripplePrimary: const Color(0xFFFFD180),
          rippleSecondary: const Color(0xFFFF6E40),
          sparkleColor: const Color(0xFFFFE0B2),
          starVisibility: 0.0,
          fogColor: const Color(0xFFFF7043),
          isMoon: false,
        );

      // 7. DUSK / ISYA (18:30 - 19:45: Nautical Dusk & Velvet Nightfall)
      case SkyPhase.dusk:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF020614), // Deep midnight navy black
            Color(0xFF06122E), // Deep night blue
            Color(0xFF0E204C), // Dark indigo
            Color(0xFF1A336E), // Royal night sapphire
            Color(0xFF26478A), // Deep twilight blue
            Color(0xFF3C60A0), // Soft horizon blue glow
            Color(0xFF66A0D4), // Lingering twilight horizon
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFE1F5FE),
            Color(0xFFB3E5FC),
            Color(0xFF81D4FA),
          ],
          sunGlowOuter: const Color(0xFF81D4FA),
          sunGlowMid: const Color(0xFFB3E5FC),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: const Color(0xFFB0BEC5),
          cloudBody: const Color(0xFF1E3252),
          cloudShadow: const Color(0xFF0E1A2C),
          cloudOpacity: 0.0,
          distantMountainColor: const Color(0xFF2E4D7A),
          midMountainColor: const Color(0xFF182A47),
          mountainFacetHighlight: const Color(0xFF2D4B75),
          foreMountainColor: const Color(0xFF0B1424),
          mosqueSilhouetteColor: const Color(0xFF070D1A),
          windowGlowOpacity: 1.0,
          waterColors: const [
            Color(0xFF0E203D),
            Color(0xFF09172E),
            Color(0xFF051020),
            Color(0xFF020914),
          ],
          waterMistColor: const Color(0xFF81D4FA),
          waterReflectionGlow: const Color(0xFF4FC3F7),
          ripplePrimary: const Color(0xFFE1F5FE),
          rippleSecondary: const Color(0xFF81D4FA),
          sparkleColor: const Color(0xFFE1F5FE),
          starVisibility: 0.80,
          fogColor: const Color(0xFF81D4FA),
          isMoon: true,
        );

      // 8. DEEP NIGHT / MALAM (19:45 - 04:15: Starlit Space & Lunar Glow)
      case SkyPhase.deepNight:
        return SkyThemePalette(
          skyGradientColors: const [
            Color(0xFF01040D), // Interstellar cosmic black
            Color(0xFF030C1E), // Deep cosmic navy
            Color(0xFF071734), // Interstellar midnight
            Color(0xFF0C234A), // Deep space indigo
            Color(0xFF123160), // Deep navy blue
            Color(0xFF1B447A), // Mountain haze blue
            Color(0xFF3E75A8), // Soft horizon starlight glow
          ],
          skyStops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.90, 1.0],
          sunDiscColors: const [
            Color(0xFFFFFFFF),
            Color(0xFFE1F5FE),
            Color(0xFFB3E5FC),
            Color(0xFF81D4FA),
          ],
          sunGlowOuter: const Color(0xFF81D4FA),
          sunGlowMid: const Color(0xFF4FC3F7),
          sunGlowCore: const Color(0xFFFFFFFF),
          cloudHighlight: Colors.transparent,
          cloudBody: Colors.transparent,
          cloudShadow: Colors.transparent,
          cloudOpacity: 0.0,
          distantMountainColor: const Color(0xFF1E3A5F),
          midMountainColor: const Color(0xFF13273F),
          mountainFacetHighlight: const Color(0xFF224263),
          foreMountainColor: const Color(0xFF091422),
          mosqueSilhouetteColor: const Color(0xFF050B14),
          windowGlowOpacity: 1.0,
          waterColors: const [
            Color(0xFF0A1E38),
            Color(0xFF07162B),
            Color(0xFF040E1C),
            Color(0xFF02070E),
          ],
          waterMistColor: const Color(0xFF81D4FA),
          waterReflectionGlow: const Color(0xFF4FC3F7),
          ripplePrimary: const Color(0xFFE1F5FE),
          rippleSecondary: const Color(0xFF81D4FA),
          sparkleColor: const Color(0xFFE1F5FE),
          starVisibility: 1.0,
          fogColor: const Color(0xFF81D4FA),
          isMoon: true,
        );
    }
  }

  static SkyThemePalette lerp(SkyThemePalette a, SkyThemePalette b, double t) {
    final clampedT = t.clamp(0.0, 1.0);

    List<Color> lerpColorList(List<Color> listA, List<Color> listB) {
      final count = math.min(listA.length, listB.length);
      return List.generate(
        count,
        (i) => Color.lerp(listA[i], listB[i], clampedT) ?? listA[i],
      );
    }

    return SkyThemePalette(
      skyGradientColors: lerpColorList(a.skyGradientColors, b.skyGradientColors),
      skyStops: a.skyStops,
      sunDiscColors: lerpColorList(a.sunDiscColors, b.sunDiscColors),
      sunGlowOuter: Color.lerp(a.sunGlowOuter, b.sunGlowOuter, clampedT) ?? a.sunGlowOuter,
      sunGlowMid: Color.lerp(a.sunGlowMid, b.sunGlowMid, clampedT) ?? a.sunGlowMid,
      sunGlowCore: Color.lerp(a.sunGlowCore, b.sunGlowCore, clampedT) ?? a.sunGlowCore,
      cloudHighlight: Color.lerp(a.cloudHighlight, b.cloudHighlight, clampedT) ?? a.cloudHighlight,
      cloudBody: Color.lerp(a.cloudBody, b.cloudBody, clampedT) ?? a.cloudBody,
      cloudShadow: Color.lerp(a.cloudShadow, b.cloudShadow, clampedT) ?? a.cloudShadow,
      cloudOpacity: a.cloudOpacity + (b.cloudOpacity - a.cloudOpacity) * clampedT,
      distantMountainColor: Color.lerp(a.distantMountainColor, b.distantMountainColor, clampedT) ?? a.distantMountainColor,
      midMountainColor: Color.lerp(a.midMountainColor, b.midMountainColor, clampedT) ?? a.midMountainColor,
      mountainFacetHighlight: Color.lerp(a.mountainFacetHighlight, b.mountainFacetHighlight, clampedT) ?? a.mountainFacetHighlight,
      foreMountainColor: Color.lerp(a.foreMountainColor, b.foreMountainColor, clampedT) ?? a.foreMountainColor,
      mosqueSilhouetteColor: Color.lerp(a.mosqueSilhouetteColor, b.mosqueSilhouetteColor, clampedT) ?? a.mosqueSilhouetteColor,
      windowGlowOpacity: a.windowGlowOpacity + (b.windowGlowOpacity - a.windowGlowOpacity) * clampedT,
      waterColors: lerpColorList(a.waterColors, b.waterColors),
      waterMistColor: Color.lerp(a.waterMistColor, b.waterMistColor, clampedT) ?? a.waterMistColor,
      waterReflectionGlow: Color.lerp(a.waterReflectionGlow, b.waterReflectionGlow, clampedT) ?? a.waterReflectionGlow,
      ripplePrimary: Color.lerp(a.ripplePrimary, b.ripplePrimary, clampedT) ?? a.ripplePrimary,
      rippleSecondary: Color.lerp(a.rippleSecondary, b.rippleSecondary, clampedT) ?? a.rippleSecondary,
      sparkleColor: Color.lerp(a.sparkleColor, b.sparkleColor, clampedT) ?? a.sparkleColor,
      starVisibility: a.starVisibility + (b.starVisibility - a.starVisibility) * clampedT,
      fogColor: Color.lerp(a.fogColor, b.fogColor, clampedT) ?? a.fogColor,
      isMoon: clampedT < 0.5 ? a.isMoon : b.isMoon,
    );
  }
}

class _SkyStateData {
  final SkyPhase phase;
  final double phaseProgress;
  final bool isDaytime;
  final double sunProgress;
  final double moonProgress;
  final SkyThemePalette palette;
  final double currentMinutes;
  final String terbitTimeStr;
  final String maghribTimeStr;
  final double birdVisibility;

  _SkyStateData({
    required this.phase,
    required this.phaseProgress,
    required this.isDaytime,
    required this.sunProgress,
    required this.moonProgress,
    required this.palette,
    required this.currentMinutes,
    required this.terbitTimeStr,
    required this.maghribTimeStr,
    required this.birdVisibility,
  });
}

class _StarData {
  final double x;
  final double y;
  final double radius;
  final double twinkleSpeed;
  final double phaseOffset;
  final bool isMajorStar;
  final double hueShift;

  _StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinkleSpeed,
    required this.phaseOffset,
    required this.isMajorStar,
    required this.hueShift,
  });
}

class _WaterWaveBand {
  final double yRel;
  final double speed;
  final double frequency;
  final double phase;
  final double secondaryFrequency;
  final double secondaryPhase;
  final double amplitude;
  final double thickness;

  _WaterWaveBand({
    required this.yRel,
    required this.speed,
    required this.frequency,
    required this.phase,
    required this.secondaryFrequency,
    required this.secondaryPhase,
    required this.amplitude,
    required this.thickness,
  });
}

class _ValleyFogData {
  final double yRel;
  final double speed;
  final double height;
  final double phase;
  final double opacity;

  _ValleyFogData({
    required this.yRel,
    required this.speed,
    required this.height,
    required this.phase,
    required this.opacity,
  });
}

class _RealCloudFormation {
  final double xRel;
  final double yRel;
  final double scale;
  final double driftSpeed;
  final double cyclePeriod;
  final double phaseOffset;
  final double morphSpeed;
  final double morphPhase;
  final bool isFacingLeft;
  final List<_CloudVaporNode> nodes;

  _RealCloudFormation({
    required this.xRel,
    required this.yRel,
    required this.scale,
    required this.driftSpeed,
    required this.cyclePeriod,
    required this.phaseOffset,
    required this.morphSpeed,
    required this.morphPhase,
    required this.isFacingLeft,
    required this.nodes,
  });

  double get driftStep => driftSpeed * cyclePeriod * 0.5;
}

class _CloudVaporNode {
  final double offsetX;
  final double offsetY;
  final double radiusX;
  final double radiusY;
  final double blur;
  final double opacity;
  final bool isSunlitCrest;
  final bool isFoundation;
  final bool isVaporWisp;

  _CloudVaporNode({
    required this.offsetX,
    required this.offsetY,
    required this.radiusX,
    required this.radiusY,
    required this.blur,
    required this.opacity,
    required this.isSunlitCrest,
    this.isFoundation = false,
    this.isVaporWisp = false,
  });
}

class _FlyingBirdData {
  final double xOffsetRel;
  final double yOffsetRel;
  final double scale;
  final double speed;
  final double flapSpeed;
  final double flapPhase;
  final double glideCyclePeriod;
  final double glidePhase;
  final double flightPathYAmplitude;

  _FlyingBirdData({
    required this.xOffsetRel,
    required this.yOffsetRel,
    required this.scale,
    required this.speed,
    required this.flapSpeed,
    required this.flapPhase,
    required this.glideCyclePeriod,
    required this.glidePhase,
    required this.flightPathYAmplitude,
  });
}

/// Cinematic Master Painter for Living Scenic Landscape
class _CinematicScenicPainter extends CustomPainter {
  final _SkyStateData skyState;
  final double elapsedSeconds;
  final List<_StarData> stars;
  final List<_WaterWaveBand> waveBands;
  final List<_ValleyFogData> valleyFogs;
  final List<_RealCloudFormation> cloudFormations;
  final List<_FlyingBirdData> birds;
  final double shootingStarProgress;
  final Offset shootingStarStart;
  final Offset shootingStarEnd;

  _CinematicScenicPainter({
    required this.skyState,
    required this.elapsedSeconds,
    required this.stars,
    required this.waveBands,
    required this.valleyFogs,
    required this.cloudFormations,
    required this.birds,
    required this.shootingStarProgress,
    required this.shootingStarStart,
    required this.shootingStarEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final horizonY = height * 0.67;

    // 1. Draw Atmospheric Sky Dome Gradient
    _drawSkyDomeGradient(canvas, size, horizonY);

    // 2. Draw Twinkling Stardust Field & Dynamic Shooting Star (Night only)
    if (skyState.palette.starVisibility > 0.05) {
      _drawStarField(canvas, size, skyState.palette.starVisibility);
      if (skyState.palette.starVisibility > 0.70) {
        _drawShootingStar(canvas, size, skyState.palette.starVisibility);
      }
    }

    // 3. Compute Celestial Orb (Sun or Moon) Center Position
    final orbPos = _calculateCelestialPosition(size, horizonY);

    // 4. Draw Multi-Tiered Gaussian Solar Atmospheric Bloom & Corona (Zero spiky rays / zero motes)
    _drawCelestialDiscAndBloom(canvas, size, orbPos, horizonY);

    // 5. Draw Photorealistic Soft-Vapor Cumulus Clouds (Day/Pagi/Siang/Senja ONLY - No clouds at night)
    if (skyState.palette.cloudOpacity > 0.01) {
      _drawPhotorealisticClouds(canvas, size, horizonY, orbPos);
    }

    // 6. Draw 4-Layered 3D Mountains with Sunlight Facets & Drifting Valley Mist
    _drawLayeredMountainsAndFog(canvas, size, horizonY);

    // 7. Draw Flying Birds Flock (Late Afternoon 16:00 until Sunset ONLY - directly in front of the sun)
    if (skyState.birdVisibility > 0.01) {
      _drawFlyingBirds(canvas, size, horizonY, orbPos);
    }

    // 8. Draw Coastal Islamic Mosques, Minarets & Swaying Palm Trees
    _drawCoastalMosquesAndPalms(canvas, size, horizonY);

    // 9. Draw Hyper-Realistic Living Water: Sinusoidal Caustic Waves & Sun Glitter Sparkles
    _drawLivingWaterAndReflection(canvas, size, horizonY, orbPos);
  }

  Offset _calculateCelestialPosition(Size size, double horizonY) {
    final centerX = size.width * 0.50;
    final radius = skyState.palette.isMoon ? 20.0 : 25.5;
    // Sinking level: celestial body center sinks completely below the mountain notch
    final sinkY = horizonY + radius + 10.0;

    if (!skyState.palette.isMoon) {
      final p = skyState.sunProgress.clamp(0.0, 1.0);
      final elevation = math.sin(p * math.pi);
      // High noon (Dzuhur) reaches zenith: ~22% of screen height
      final topY = size.height * 0.22;
      final currentY = sinkY - (elevation * (sinkY - topY));
      return Offset(centerX, currentY);
    } else {
      final p = skyState.moonProgress.clamp(0.0, 1.0);
      final elevation = math.sin(p * math.pi);
      // Midnight reaches zenith: ~22% of screen height
      final topY = size.height * 0.22;
      final currentY = sinkY - (elevation * (sinkY - topY));
      return Offset(centerX, currentY);
    }
  }

  /// 1. Deep Atmospheric Sky Dome Gradient
  void _drawSkyDomeGradient(Canvas canvas, Size size, double horizonY) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 20);
    final palette = skyState.palette;

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: palette.skyGradientColors,
        stops: palette.skyStops,
      ).createShader(skyRect);

    canvas.drawRect(skyRect, skyPaint);

    final ambientGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.0, (horizonY / size.height) * 2 - 1),
        radius: 0.85,
        colors: [
          palette.sunGlowOuter.withOpacity(0.24),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, ambientGlowPaint);
  }

  /// 2. Twinkling Stardust Field & Dynamic Shooting Stars (Night Only)
  void _drawStarField(Canvas canvas, Size size, double globalVisibility) {
    for (final star in stars) {
      final twinkle = math.sin(elapsedSeconds * star.twinkleSpeed + star.phaseOffset);
      final alpha = ((0.35 + 0.65 * ((twinkle + 1.0) / 2.0)) * globalVisibility)
          .clamp(0.0, 1.0);

      if (alpha <= 0.02) continue;

      final starCenter = Offset(star.x * size.width, star.y * size.height);
      final baseColor = star.hueShift > 0.2
          ? const Color(0xFFFFF9C4)
          : const Color(0xFFE1F5FE);

      if (star.isMajorStar) {
        final glowPaint = Paint()
          ..color = baseColor.withOpacity(alpha * 0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(starCenter, star.radius * 2.2, glowPaint);
        canvas.drawCircle(
          starCenter,
          star.radius,
          Paint()..color = Colors.white.withOpacity(alpha),
        );
      } else {
        canvas.drawCircle(
          starCenter,
          star.radius,
          Paint()..color = baseColor.withOpacity(alpha),
        );
      }
    }
  }

  void _drawShootingStar(Canvas canvas, Size size, double globalVisibility) {
    if (shootingStarProgress >= 1.0 || globalVisibility < 0.60) return;

    final start = Offset(
      shootingStarStart.dx * size.width,
      shootingStarStart.dy * size.height,
    );
    final end = Offset(
      shootingStarEnd.dx * size.width,
      shootingStarEnd.dy * size.height,
    );

    final currentPos = Offset.lerp(start, end, shootingStarProgress)!;
    final tailLength = (end - start).distance * 0.30;
    final direction = (end - start) / (end - start).distance;
    final tailPos = currentPos -
        direction *
            (tailLength * (1.0 - (shootingStarProgress - 0.5).abs() * 0.5));

    final alpha = (math.sin(shootingStarProgress * math.pi) * globalVisibility)
        .clamp(0.0, 1.0);

    final meteorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFF81D4FA).withOpacity(alpha * 0.65),
          Colors.white.withOpacity(alpha),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(tailPos, currentPos))
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(tailPos, currentPos, meteorPaint);
    canvas.drawCircle(
      currentPos,
      1.6,
      Paint()..color = Colors.white.withOpacity(alpha),
    );
  }

  /// 3. Photorealistic Radiant Sun & Ethereal Lunar Body with Gaussian Atmospheric Bloom
  void _drawCelestialDiscAndBloom(Canvas canvas, Size size, Offset orbPos, double horizonY) {
    final palette = skyState.palette;

    if (!palette.isMoon) {
      _drawPhotorealisticSun(canvas, size, orbPos, horizonY);
    } else {
      _drawPhotorealisticMoon(canvas, size, orbPos, horizonY);
    }
  }

  /// Photorealistic Sun: Incandescent blinding white core, silky continuous Gaussian corona bloom,
  /// soft atmospheric Rayleigh/Mie scattering, and cinematic optical glare
  void _drawPhotorealisticSun(Canvas canvas, Size size, Offset orbPos, double horizonY) {
    final palette = skyState.palette;
    const double radius = 25.5;

    // 1. Broad Outer Atmospheric Scattering Wash (Ambient solar lighting of the sky dome)
    const double outerHazeRadius = 220.0;
    final outerHazeRect = Rect.fromCircle(center: orbPos, radius: outerHazeRadius);
    final outerHazePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.sunGlowOuter.withOpacity(0.38),
          palette.sunGlowOuter.withOpacity(0.18),
          palette.sunGlowOuter.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.68, 1.0],
      ).createShader(outerHazeRect);
    canvas.drawCircle(orbPos, outerHazeRadius, outerHazePaint);

    // 2. Mid Corona Bloom (Velvety Gaussian halo connecting the disc with the atmosphere)
    const double midBloomRadius = 95.0;
    final midBloomRect = Rect.fromCircle(center: orbPos, radius: midBloomRadius);
    final midBloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.sunGlowMid.withOpacity(0.88),
          palette.sunGlowOuter.withOpacity(0.42),
          palette.sunGlowOuter.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
      ).createShader(midBloomRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
    canvas.drawCircle(orbPos, midBloomRadius, midBloomPaint);

    // 3. Inner Chromosphere Radiance (Intense, brilliant halo directly around the solar disc)
    const double innerCoronaRadius = 48.0;
    final innerCoronaRect = Rect.fromCircle(center: orbPos, radius: innerCoronaRadius);
    final innerCoronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.96),
          palette.sunGlowMid.withOpacity(0.72),
          palette.sunGlowOuter.withOpacity(0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(innerCoronaRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(orbPos, innerCoronaRadius, innerCoronaPaint);

    // 4. Subtle Anamorphic Optical Atmospheric Gleam (Delicate horizontal light flare)
    const double gleamWidth = 140.0;
    const double gleamHeight = 5.0;
    final gleamRect = Rect.fromCenter(
      center: orbPos,
      width: gleamWidth * 2,
      height: gleamHeight * 2,
    );
    final gleamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.32),
          palette.sunGlowMid.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(gleamRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawOval(gleamRect, gleamPaint);

    // 5. Incandescent Solar Photosphere Disc (Round, seamless, luminous warm rim)
    final discRect = Rect.fromCircle(center: orbPos, radius: radius);
    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.98),
          palette.sunDiscColors[1].withOpacity(0.95),
          palette.sunDiscColors[2].withOpacity(0.80),
        ],
        stops: const [0.0, 0.50, 0.82, 1.0],
      ).createShader(discRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(orbPos, radius, discPaint);

    // 6. Blinding Pure White Solar Core
    const double coreRadius = radius * 0.58;
    final coreRect = Rect.fromCircle(center: orbPos, radius: coreRadius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.96),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(coreRect);
    canvas.drawCircle(orbPos, coreRadius, corePaint);
  }

  /// Photorealistic Moon: Soft silver-pearl lunar disc with crater mare topography and ethereal lunar halo
  void _drawPhotorealisticMoon(Canvas canvas, Size size, Offset orbPos, double horizonY) {
    final palette = skyState.palette;
    const double radius = 21.0;

    // 1. Broad Lunar Atmospheric Haze (Silvery blue celestial glow)
    const double outerHazeRadius = 140.0;
    final outerHazeRect = Rect.fromCircle(center: orbPos, radius: outerHazeRadius);
    final outerHazePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.sunGlowOuter.withOpacity(0.30),
          palette.sunGlowOuter.withOpacity(0.12),
          palette.sunGlowOuter.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(outerHazeRect);
    canvas.drawCircle(orbPos, outerHazeRadius, outerHazePaint);

    // 2. Soft Lunar Corona
    const double coronaRadius = 55.0;
    final coronaRect = Rect.fromCircle(center: orbPos, radius: coronaRadius);
    final coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.sunGlowMid.withOpacity(0.70),
          palette.sunGlowOuter.withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(coronaRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(orbPos, coronaRadius, coronaPaint);

    // 3. Moon Disc Body (Silver-white pearl lunar sphere)
    final moonRect = Rect.fromCircle(center: orbPos, radius: radius);
    final moonPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.95,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF2F6FA),
          Color(0xFFDBE4ED),
          Color(0xFFBCCCDC),
        ],
        stops: [0.0, 0.40, 0.80, 1.0],
      ).createShader(moonRect);
    canvas.drawCircle(orbPos, radius, moonPaint);

    // 4. Subtle Lunar Mare / Crater Features (Realistic subtle surface details)
    final craterPaint = Paint()
      ..color = const Color(0xFF9FB3C8).withOpacity(0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    // Mare Serenitatis / Tranquillitatis
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(orbPos.dx + radius * 0.20, orbPos.dy - radius * 0.15),
        width: radius * 0.65,
        height: radius * 0.45,
      ),
      craterPaint,
    );
    // Oceanus Procellarum
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(orbPos.dx - radius * 0.22, orbPos.dy + radius * 0.10),
        width: radius * 0.55,
        height: radius * 0.50,
      ),
      craterPaint,
    );
    // Mare Imbrium
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(orbPos.dx - radius * 0.10, orbPos.dy - radius * 0.28),
        width: radius * 0.40,
        height: radius * 0.35,
      ),
      craterPaint,
    );

    // 5. Delicate Luminous Lunar Limb Rim (Silver bright edge)
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.70),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.75, 1.0],
      ).createShader(moonRect);
    canvas.drawCircle(orbPos, radius, rimPaint);
  }

  /// 4. Photorealistic Soft-Vapor Cumulus Clouds (Day/Dawn/Sunset ONLY - Absent at night)
  void _drawPhotorealisticClouds(Canvas canvas, Size size, double horizonY, Offset orbPos) {
    final width = size.width;
    final height = size.height;
    final palette = skyState.palette;
    final globalCloudOpacity = palette.cloudOpacity;

    if (globalCloudOpacity <= 0.01) return;

    for (final cloud in cloudFormations) {
      // Infrequent ("agak jarang") alternating drift motion:
      // Clouds mostly rest peacefully in the sky (78% of the time) and only occasionally drift gently (22% of the time)
      final totalPhase = (elapsedSeconds / cloud.cyclePeriod) * 2 * math.pi + cloud.phaseOffset;
      final nCycles = (totalPhase / (2 * math.pi)).floor();
      final alpha = totalPhase - (nCycles * 2 * math.pi); // [0, 2*pi)

      const moveFraction = 0.22;
      final cycleNorm = (alpha / (2 * math.pi)).clamp(0.0, 1.0);

      double cycleProgress;
      bool isMoving;
      if (cycleNorm < moveFraction) {
        // Continuous smooth-step motion during the short active drift window
        final tNorm = cycleNorm / moveFraction; // [0, 1]
        final smoothT = (tNorm * math.pi - 0.5 * math.sin(2 * tNorm * math.pi)) / math.pi;
        cycleProgress = smoothT;
        isMoving = true;
      } else {
        // Long stationary resting state (diam)
        cycleProgress = 1.0;
        isMoving = false;
      }

      final totalMotion = nCycles + cycleProgress;
      final integratedDrift = totalMotion * cloud.driftStep;

      final rawX = (cloud.xRel + integratedDrift) % 1.30;
      final cx = (rawX - 0.15) * width;
      final cy = cloud.yRel * height;

      // Organic subtle breathing (gentler when resting, lively when moving)
      final morphFactor = isMoving ? 0.035 : 0.018;
      final morph = math.sin(elapsedSeconds * cloud.morphSpeed + cloud.morphPhase) * morphFactor;

      // Pass 1: Foundation Stratum (Soft atmospheric base shadow)
      for (final node in cloud.nodes.where((n) => n.isFoundation)) {
        final rx = node.radiusX * (1.0 + morph);
        final ry = node.radiusY * (1.0 - morph * 0.5);
        final rect = Rect.fromCenter(
          center: Offset(cx + node.offsetX, cy + node.offsetY),
          width: rx * 2,
          height: ry * 2,
        );

        final shadowPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.0, 0.40),
            radius: 0.95,
            colors: [
              palette.cloudShadow.withOpacity(node.opacity * 0.85 * globalCloudOpacity),
              palette.cloudShadow.withOpacity(node.opacity * 0.38 * globalCloudOpacity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(rect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.blur);

        canvas.drawOval(rect, shadowPaint);
      }

      // Pass 2: Internal Dense Milky Body (Fluffy voluminous mass)
      for (final node in cloud.nodes.where((n) => !n.isFoundation && !n.isSunlitCrest && !n.isVaporWisp)) {
        final rx = node.radiusX * (1.0 + morph);
        final ry = node.radiusY * (1.0 - morph * 0.5);
        final rect = Rect.fromCenter(
          center: Offset(cx + node.offsetX, cy + node.offsetY),
          width: rx * 2,
          height: ry * 2,
        );

        final lightDir = Alignment(cloud.isFacingLeft ? -0.40 : 0.40, -0.30);

        final bodyPaint = Paint()
          ..shader = RadialGradient(
            center: lightDir,
            radius: 0.88,
            colors: [
              palette.cloudHighlight.withOpacity(node.opacity * 0.85 * globalCloudOpacity),
              palette.cloudBody.withOpacity(node.opacity * 0.90 * globalCloudOpacity),
              palette.cloudShadow.withOpacity(node.opacity * 0.35 * globalCloudOpacity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 0.80, 1.0],
          ).createShader(rect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.blur);

        canvas.drawOval(rect, bodyPaint);
      }

      // Pass 3: Sunlit Cauliflower Micro-Crests (Bright billowy tops with soft sunlight radiance)
      for (final node in cloud.nodes.where((n) => n.isSunlitCrest)) {
        final rx = node.radiusX * (1.0 + morph);
        final ry = node.radiusY * (1.0 - morph * 0.5);
        final rect = Rect.fromCenter(
          center: Offset(cx + node.offsetX, cy + node.offsetY),
          width: rx * 2,
          height: ry * 2,
        );

        final crestPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(cloud.isFacingLeft ? -0.45 : 0.45, -0.42),
            radius: 0.82,
            colors: [
              Colors.white.withOpacity(node.opacity * 0.98 * globalCloudOpacity),
              palette.cloudHighlight.withOpacity(node.opacity * 0.90 * globalCloudOpacity),
              palette.cloudBody.withOpacity(node.opacity * 0.28 * globalCloudOpacity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ).createShader(rect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.blur);

        canvas.drawOval(rect, crestPaint);
      }

      // Pass 4: Delicate Feathery Vapor Wisps (Dissolving natural edges)
      for (final node in cloud.nodes.where((n) => n.isVaporWisp)) {
        final rx = node.radiusX * (1.0 + morph);
        final ry = node.radiusY * (1.0 - morph * 0.5);
        final rect = Rect.fromCenter(
          center: Offset(cx + node.offsetX, cy + node.offsetY),
          width: rx * 2,
          height: ry * 2,
        );

        final wispPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              palette.cloudHighlight.withOpacity(node.opacity * 0.80 * globalCloudOpacity),
              palette.cloudBody.withOpacity(node.opacity * 0.38 * globalCloudOpacity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(rect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.blur);

        canvas.drawOval(rect, wispPaint);
      }
    }
  }

  /// 5. 4-Layered 3D Mountains & Drifting Valley Mist
  void _drawLayeredMountainsAndFog(Canvas canvas, Size size, double horizonY) {
    final width = size.width;
    final palette = skyState.palette;

    // --- Layer 1: Distant Misty Valley Pass Notch ---
    final distantPath = Path();
    distantPath.moveTo(0, horizonY);
    distantPath.lineTo(0, horizonY - 24);
    distantPath.lineTo(width * 0.28, horizonY - 16);
    distantPath.lineTo(width * 0.42, horizonY - 4);
    distantPath.lineTo(width * 0.50, horizonY);
    distantPath.lineTo(width * 0.58, horizonY - 4);
    distantPath.lineTo(width * 0.72, horizonY - 16);
    distantPath.lineTo(width, horizonY - 24);
    distantPath.lineTo(width, horizonY);
    distantPath.close();

    canvas.drawPath(
      distantPath,
      Paint()..color = palette.distantMountainColor.withOpacity(0.74),
    );

    // --- Layer 2: Mid-Range Mountain Peaks (Left & Right Flanks) ---
    final midLeftPath = Path();
    midLeftPath.moveTo(0, horizonY);
    midLeftPath.lineTo(0, horizonY - 60);
    midLeftPath.lineTo(width * 0.14, horizonY - 50);
    midLeftPath.lineTo(width * 0.24, horizonY - 72);
    midLeftPath.lineTo(width * 0.36, horizonY - 34);
    midLeftPath.lineTo(width * 0.46, horizonY - 6);
    midLeftPath.lineTo(width * 0.50, horizonY);
    midLeftPath.close();

    canvas.drawPath(midLeftPath, Paint()..color = palette.midMountainColor);

    final midRightPath = Path();
    midRightPath.moveTo(width, horizonY);
    midRightPath.lineTo(width, horizonY - 60);
    midRightPath.lineTo(width * 0.86, horizonY - 50);
    midRightPath.lineTo(width * 0.76, horizonY - 72);
    midRightPath.lineTo(width * 0.64, horizonY - 34);
    midRightPath.lineTo(width * 0.54, horizonY - 6);
    midRightPath.lineTo(width * 0.50, horizonY);
    midRightPath.close();

    canvas.drawPath(midRightPath, Paint()..color = palette.midMountainColor);

    // --- Layer 3: Mountain Ridge Facet Highlights (Lit by central sun rays) ---
    final litFacetPaint = Paint()
      ..color = palette.mountainFacetHighlight.withOpacity(0.62);

    final litFacetLeft = Path();
    litFacetLeft.moveTo(width * 0.24, horizonY - 72);
    litFacetLeft.lineTo(width * 0.36, horizonY - 34);
    litFacetLeft.lineTo(width * 0.30, horizonY - 26);
    litFacetLeft.close();
    canvas.drawPath(litFacetLeft, litFacetPaint);

    final litFacetRight = Path();
    litFacetRight.moveTo(width * 0.76, horizonY - 72);
    litFacetRight.lineTo(width * 0.64, horizonY - 34);
    litFacetRight.lineTo(width * 0.70, horizonY - 26);
    litFacetRight.close();
    canvas.drawPath(litFacetRight, litFacetPaint);

    // --- Living Valley Mist / Mountain Fog Planes (Drifting horizontally) ---
    for (final fog in valleyFogs) {
      final yFog = size.height * fog.yRel;
      final fogOffset = (math.sin(elapsedSeconds * fog.speed + fog.phase) * width * 0.12);
      final fogRect = Rect.fromCenter(
        center: Offset(width * 0.50 + fogOffset, yFog),
        width: width * 0.68,
        height: fog.height,
      );
      final fogPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            palette.fogColor.withOpacity(fog.opacity * (palette.isMoon ? 0.25 : 0.40)),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(fogRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawOval(fogRect, fogPaint);
    }

    // --- Layer 4: Foreground Shoreline Slopes ---
    final foreLeftPath = Path();
    foreLeftPath.moveTo(0, horizonY + 8);
    foreLeftPath.lineTo(0, horizonY - 30);
    foreLeftPath.lineTo(width * 0.18, horizonY - 20);
    foreLeftPath.lineTo(width * 0.35, horizonY - 6);
    foreLeftPath.lineTo(width * 0.44, horizonY + 3);
    foreLeftPath.lineTo(0, horizonY + 8);
    foreLeftPath.close();

    canvas.drawPath(foreLeftPath, Paint()..color = palette.foreMountainColor);

    final foreRightPath = Path();
    foreRightPath.moveTo(width, horizonY + 8);
    foreRightPath.lineTo(width, horizonY - 30);
    foreRightPath.lineTo(width * 0.82, horizonY - 20);
    foreRightPath.lineTo(width * 0.65, horizonY - 6);
    foreRightPath.lineTo(width * 0.56, horizonY + 3);
    foreRightPath.lineTo(width, horizonY + 8);
    foreRightPath.close();

    canvas.drawPath(foreRightPath, Paint()..color = palette.foreMountainColor);
  }

  /// 7. Graceful Avian Flock in Sunset Transit (Active strictly 16:00 to Sunset, flies directly in front of the sun)
  void _drawFlyingBirds(Canvas canvas, Size size, double horizonY, Offset orbPos) {
    final width = size.width;
    final visibility = skyState.birdVisibility;
    if (visibility <= 0.01) return;

    final silhouetteColor = skyState.palette.mosqueSilhouetteColor.withOpacity(0.92 * visibility);

    for (final bird in birds) {
      // Smooth continuous looping flight transit across the sky width
      final progress = ((elapsedSeconds * bird.speed + bird.xOffsetRel) % 1.40) - 0.20;
      final birdX = progress * width;

      // Base altitude locked to afternoon sun elevation so flock flies directly in front of the sun
      final birdBaseY = orbPos.dy + (bird.yOffsetRel * 48.0);
      final birdY = birdBaseY +
          math.sin(elapsedSeconds * 0.9 + bird.flapPhase) * bird.flightPathYAmplitude;

      // Culling outside viewable screen bounds
      if (birdX < -50 || birdX > width + 50) continue;

      // Alternating wing flap vs glide dynamics
      final glideTime = (elapsedSeconds + bird.glidePhase) % bird.glideCyclePeriod;
      final isGliding = glideTime > (bird.glideCyclePeriod * 0.62);

      double flapAngle;
      if (isGliding) {
        // Wings held in slight aerodynamic glide V
        flapAngle = 0.20 + 0.06 * math.sin(elapsedSeconds * 1.6);
      } else {
        // Harmonic wing flap cycle
        flapAngle = math.sin(elapsedSeconds * bird.flapSpeed + bird.flapPhase);
      }

      _drawSingleBird(
        canvas,
        Offset(birdX, birdY),
        bird.scale,
        flapAngle,
        silhouetteColor,
      );
    }
  }

  void _drawSingleBird(
    Canvas canvas,
    Offset pos,
    double scale,
    double flapAngle,
    Color color,
  ) {
    final wingSpan = 11.0 * scale;
    final flapDy = flapAngle * (6.5 * scale);

    final birdPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final birdPath = Path();

    // 1. Torso & Head
    final bodyRect = Rect.fromCenter(
      center: pos,
      width: 7.0 * scale,
      height: 2.2 * scale,
    );
    birdPath.addOval(bodyRect);

    // 2. Left Wing (Aerofoil curvature)
    birdPath.moveTo(pos.dx - 0.5 * scale, pos.dy);
    birdPath.quadraticBezierTo(
      pos.dx - wingSpan * 0.45,
      pos.dy - flapDy * 0.85 - 1.5 * scale,
      pos.dx - wingSpan,
      pos.dy - flapDy,
    );
    birdPath.quadraticBezierTo(
      pos.dx - wingSpan * 0.55,
      pos.dy - flapDy * 0.40 + 1.2 * scale,
      pos.dx - 1.5 * scale,
      pos.dy + 0.8 * scale,
    );
    birdPath.close();

    // 3. Right Wing (Opposite aerofoil)
    birdPath.moveTo(pos.dx + 0.5 * scale, pos.dy);
    birdPath.quadraticBezierTo(
      pos.dx + wingSpan * 0.45,
      pos.dy - flapDy * 0.85 - 1.5 * scale,
      pos.dx + wingSpan,
      pos.dy - flapDy,
    );
    birdPath.quadraticBezierTo(
      pos.dx + wingSpan * 0.55,
      pos.dy - flapDy * 0.40 + 1.2 * scale,
      pos.dx + 1.5 * scale,
      pos.dy + 0.8 * scale,
    );
    birdPath.close();

    canvas.drawPath(birdPath, birdPaint);
  }

  /// 8. Coastal Islamic Mosques, Minarets & Swaying Palm Trees
  void _drawCoastalMosquesAndPalms(Canvas canvas, Size size, double horizonY) {
    final width = size.width;
    final palette = skyState.palette;
    final silPaint = Paint()..color = palette.mosqueSilhouetteColor;

    // --- LEFT COAST MOSQUE & PALMS ---
    final leftMosquePath = Path();
    leftMosquePath.moveTo(0, horizonY + 6);

    _drawScenicMinaret(leftMosquePath, width * 0.08, horizonY - 10, height: 72, width: 9.5);
    _drawScenicDome(leftMosquePath, width * 0.14, horizonY - 8, radius: 15, height: 18);
    _drawScenicDome(leftMosquePath, width * 0.20, horizonY - 4, radius: 10, height: 12);

    leftMosquePath.lineTo(width * 0.32, horizonY + 4);
    leftMosquePath.lineTo(0, horizonY + 6);
    leftMosquePath.close();
    canvas.drawPath(leftMosquePath, silPaint);

    final palmSway = math.sin(elapsedSeconds * 1.8) * 0.045;
    _drawSwayingPalmTree(
      canvas,
      Offset(width * 0.20, horizonY - 6),
      height: 33,
      swayFactor: palmSway,
      color: palette.mosqueSilhouetteColor,
    );
    _drawSwayingPalmTree(
      canvas,
      Offset(width * 0.25, horizonY - 3),
      height: 27,
      swayFactor: palmSway * 1.25,
      color: palette.mosqueSilhouetteColor,
    );

    // --- RIGHT COAST MOSQUE & PALMS ---
    final rightMosquePath = Path();
    rightMosquePath.moveTo(width, horizonY + 6);

    _drawScenicMinaret(rightMosquePath, width * 0.92, horizonY - 10, height: 75, width: 10);
    _drawScenicDome(rightMosquePath, width * 0.85, horizonY - 8, radius: 16, height: 19);
    _drawScenicDome(rightMosquePath, width * 0.78, horizonY - 4, radius: 10, height: 12);

    rightMosquePath.lineTo(width * 0.68, horizonY + 4);
    rightMosquePath.lineTo(width, horizonY + 6);
    rightMosquePath.close();
    canvas.drawPath(rightMosquePath, silPaint);

    _drawSwayingPalmTree(
      canvas,
      Offset(width * 0.79, horizonY - 6),
      height: 33,
      swayFactor: -palmSway,
      color: palette.mosqueSilhouetteColor,
    );
    _drawSwayingPalmTree(
      canvas,
      Offset(width * 0.74, horizonY - 3),
      height: 27,
      swayFactor: -palmSway * 1.25,
      color: palette.mosqueSilhouetteColor,
    );

    // Warm Glowing Lantern Windows
    if (palette.windowGlowOpacity > 0.05) {
      _drawScenicGlowingWindows(canvas, width, horizonY, palette.windowGlowOpacity);
    }
  }

  void _drawScenicDome(Path path, double cx, double baseY, {required double radius, required double height}) {
    final topY = baseY - height;
    path.lineTo(cx - radius, baseY);
    path.cubicTo(
      cx - radius * 1.05, baseY - height * 0.55,
      cx - radius * 0.35, topY + height * 0.15,
      cx, topY,
    );
    path.cubicTo(
      cx + radius * 0.35, topY + height * 0.15,
      cx + radius * 1.05, baseY - height * 0.55,
      cx + radius, baseY,
    );
  }

  void _drawScenicMinaret(Path path, double cx, double baseY, {required double height, required double width}) {
    final topY = baseY - height;
    final hw = width / 2;
    path.lineTo(cx - hw, baseY);
    final bY = baseY - height * 0.65;
    path.lineTo(cx - hw, bY);
    path.lineTo(cx - hw - 2.5, bY);
    path.lineTo(cx - hw - 2.5, bY - 3);
    path.lineTo(cx - hw, bY - 3);
    path.lineTo(cx - hw * 0.6, topY + 7);
    path.lineTo(cx, topY);
    path.lineTo(cx + hw * 0.6, topY + 7);
    path.lineTo(cx + hw, bY - 3);
    path.lineTo(cx + hw + 2.5, bY - 3);
    path.lineTo(cx + hw + 2.5, bY);
    path.lineTo(cx + hw, bY);
    path.lineTo(cx + hw, baseY);
  }

  void _drawSwayingPalmTree(Canvas canvas, Offset base, {required double height, required double swayFactor, required Color color}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + (height * (0.18 + swayFactor)), base.dy - height);
    final control = Offset(base.dx + (height * (0.10 + swayFactor * 0.5)), base.dy - height * 0.5);
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(control.dx, control.dy, top.dx, top.dy);
    canvas.drawPath(trunk, paint);

    final frondPaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final angle = (i * (math.pi / 3)) - 0.4 + (swayFactor * 0.85);
      final frondEnd = Offset(
        top.dx + (height * 0.46) * math.cos(angle),
        top.dy + (height * 0.36) * math.sin(angle) + 4.0,
      );
      final frondPath = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + (height * 0.26) * math.cos(angle),
          top.dy + (height * 0.16) * math.sin(angle) - 3.0,
          frondEnd.dx,
          frondEnd.dy,
        );
      canvas.drawPath(frondPath, frondPaint);
    }
  }

  void _drawScenicGlowingWindows(Canvas canvas, double width, double horizonY, double maxGlowOpacity) {
    final glowPulse = 0.75 + 0.25 * math.sin(elapsedSeconds * 2.2);
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity((0.88 * glowPulse * maxGlowOpacity).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(width * 0.14, horizonY - 14), width: 3.5, height: 6.5),
        const Radius.circular(1.8),
      ),
      glowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(width * 0.85, horizonY - 14), width: 3.5, height: 6.5),
        const Radius.circular(1.8),
      ),
      glowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(width * 0.92, horizonY - 45), width: 2.8, height: 5.5),
        const Radius.circular(1.4),
      ),
      glowPaint,
    );
  }

  /// 7. Living Water Body & Animated Specular Reflection with Sun Glitter Sparkles
  void _drawLivingWaterAndReflection(Canvas canvas, Size size, double horizonY, Offset orbPos) {
    final width = size.width;
    final height = size.height;
    final waterHeight = height - horizonY;
    final palette = skyState.palette;

    final waterRect = Rect.fromLTWH(0, horizonY, width, waterHeight);

    // 1. Deep Atmospheric Water Base Gradient (Fresnel perspective: horizon matches sky haze, foreground is deep ocean)
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: palette.waterColors,
        stops: const [0.0, 0.28, 0.65, 1.0],
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    // 2. Horizon Water Mist & Atmospheric Haze Blend
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.waterMistColor.withOpacity(palette.isMoon ? 0.25 : 0.45),
          palette.waterMistColor.withOpacity(palette.isMoon ? 0.08 : 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, horizonY, width, 18));
    canvas.drawRect(Rect.fromLTWH(0, horizonY, width, 18), mistPaint);

    // 3. Diffuse Specular Sunlight Column (Atmospheric Reflection Wash)
    final sunX = orbPos.dx;
    final reflectionTopW = width * (palette.isMoon ? 0.14 : 0.18);
    final reflectionBottomW = width * (palette.isMoon ? 0.55 : 0.70);

    final reflectionGlowPath = Path();
    reflectionGlowPath.moveTo(sunX - reflectionTopW / 2, horizonY);
    reflectionGlowPath.lineTo(sunX + reflectionTopW / 2, horizonY);
    reflectionGlowPath.lineTo(sunX + reflectionBottomW / 2, height);
    reflectionGlowPath.lineTo(sunX - reflectionBottomW / 2, height);
    reflectionGlowPath.close();

    final specularGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.waterReflectionGlow.withOpacity(palette.isMoon ? 0.50 : 0.72),
          palette.waterReflectionGlow.withOpacity(palette.isMoon ? 0.28 : 0.42),
          palette.waterReflectionGlow.withOpacity(palette.isMoon ? 0.10 : 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.65, 1.0],
      ).createShader(waterRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
    canvas.drawPath(reflectionGlowPath, specularGlowPaint);

    // Core intense narrow vertical beam along sun axis
    final coreBeamPath = Path();
    coreBeamPath.moveTo(sunX - width * 0.04, horizonY);
    coreBeamPath.lineTo(sunX + width * 0.04, horizonY);
    coreBeamPath.lineTo(sunX + width * 0.15, height);
    coreBeamPath.lineTo(sunX - width * 0.15, height);
    coreBeamPath.close();

    final coreBeamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(palette.isMoon ? 0.40 : 0.60),
          palette.waterReflectionGlow.withOpacity(palette.isMoon ? 0.20 : 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(waterRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawPath(coreBeamPath, coreBeamPaint);

    // 4. Realistic 3D Harmonic Wave Ribbons with Organic Curves & Specular Highlights
    for (final band in waveBands) {
      final yBase = horizonY + (band.yRel * waterHeight);
      final perspectiveScale = 0.2 + (band.yRel * 0.8);

      // Multi-frequency sinusoidal wave path across the screen width
      final wavePath = Path();
      const numSegments = 24;
      final dx = width / numSegments;

      for (int s = 0; s <= numSegments; s++) {
        final x = s * dx;
        final k1 = band.frequency;
        final k2 = band.secondaryFrequency;
        final t = elapsedSeconds * band.speed;

        final waveElevation = math.sin(k1 * x + t + band.phase) * band.amplitude +
            math.sin(k2 * x - t * 0.7 + band.secondaryPhase) * (band.amplitude * 0.35);

        final y = yBase + waveElevation;

        if (s == 0) {
          wavePath.moveTo(x, y);
        } else {
          final prevX = (s - 1) * dx;
          final prevWaveElevation = math.sin(k1 * prevX + t + band.phase) * band.amplitude +
              math.sin(k2 * prevX - t * 0.7 + band.secondaryPhase) * (band.amplitude * 0.35);
          final prevY = yBase + prevWaveElevation;

          final cx = (prevX + x) / 2;
          final cy = (prevY + y) / 2;
          wavePath.quadraticBezierTo(prevX, prevY, cx, cy);
        }
      }

      // Shimmer intensity varies dynamically
      final shimmer = (0.50 + 0.50 * math.sin(elapsedSeconds * (band.speed * 1.2) + band.phase)).clamp(0.0, 1.0);

      // Column width at this wave's height
      final colHalfWidth = (reflectionTopW + (reflectionBottomW - reflectionTopW) * band.yRel) * 0.55;
      final colLeft = (sunX - colHalfWidth).clamp(0.0, width);
      final colRight = (sunX + colHalfWidth).clamp(0.0, width);

      // Wave shader with ambient water color outside & brilliant sun reflection inside the column
      final waveShader = LinearGradient(
        colors: [
          palette.rippleSecondary.withOpacity(0.0),
          palette.rippleSecondary.withOpacity(0.18 * shimmer * perspectiveScale),
          palette.rippleSecondary.withOpacity(0.40 * shimmer * perspectiveScale),
          palette.ripplePrimary.withOpacity(0.95 * shimmer * (0.4 + 0.6 * perspectiveScale)),
          Colors.white.withOpacity(0.85 * shimmer * (0.3 + 0.7 * perspectiveScale)),
          palette.ripplePrimary.withOpacity(0.95 * shimmer * (0.4 + 0.6 * perspectiveScale)),
          palette.rippleSecondary.withOpacity(0.40 * shimmer * perspectiveScale),
          palette.rippleSecondary.withOpacity(0.18 * shimmer * perspectiveScale),
          palette.rippleSecondary.withOpacity(0.0),
        ],
        stops: [
          0.0,
          (colLeft / width * 0.7).clamp(0.0, 0.3),
          (colLeft / width).clamp(0.0, 0.45),
          ((sunX - colHalfWidth * 0.35) / width).clamp(0.1, 0.49),
          (sunX / width).clamp(0.2, 0.8),
          ((sunX + colHalfWidth * 0.35) / width).clamp(0.51, 0.9),
          (colRight / width).clamp(0.55, 1.0),
          (1.0 - (1.0 - colRight / width) * 0.7).clamp(0.7, 1.0),
          1.0,
        ],
      ).createShader(Rect.fromLTWH(0, yBase - 4, width, 8));

      final wavePaint = Paint()
        ..shader = waveShader
        ..strokeWidth = band.thickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(wavePath, wavePaint);

      // Subtle shadow under the wave crest for 3D depth
      if (band.yRel > 0.15) {
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.12 * band.yRel)
          ..strokeWidth = band.thickness * 0.7
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final shadowPath = wavePath.shift(const Offset(0, 1.2));
        canvas.drawPath(shadowPath, shadowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicScenicPainter oldDelegate) {
    return true;
  }
}
