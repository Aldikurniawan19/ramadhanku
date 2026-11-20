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
  late double _liveClockBaseSeconds;
  late int _cloudDaySeed;

  // Pre-allocated deterministic particle & simulation data
  late final List<_StarData> _stars;
  late final List<_WaterWaveBand> _waveBands;
  late final List<_ValleyFogData> _valleyFogs;
  late List<_VolumetricCloudFormation> _cloudFormations;
  late List<_CirrusStreak> _cirrusStreaks;
  late List<_HorizonCloudBank> _horizonCloudBanks;
  late final List<_FlyingBirdData> _birds;

  // Meteor / Shooting star state (Night only)
  double _shootingStarProgress = 1.0;
  Offset _shootingStarStart = const Offset(0.2, 0.08);
  Offset _shootingStarEnd = const Offset(0.7, 0.32);
  double _shootingStarTimer = 0.0;

  int _computeDaySeed(DateTime dt) {
    final raw = dt.year * 10000 + dt.month * 100 + dt.day;
    return ((raw * 2654435761) & 0x7fffffff);
  }

  @override
  void initState() {
    super.initState();
    final initialTime = widget.customTime ?? DateTime.now();
    _liveClockBaseSeconds = initialTime.hour * 3600.0 +
        initialTime.minute * 60.0 +
        initialTime.second +
        (initialTime.millisecond / 1000.0);
    _cloudDaySeed = _computeDaySeed(initialTime);

    _initStars();
    _initWaterSimulation();
    _initValleyFogs();
    _initPhotorealisticClouds(_cloudDaySeed);
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
  void didUpdateWidget(covariant RealisticSkyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.customTime ?? DateTime.now();
    final nextSeed = _computeDaySeed(now);
    if (nextSeed != _cloudDaySeed) {
      _cloudDaySeed = nextSeed;
      _initPhotorealisticClouds(_cloudDaySeed);
    }
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

    // 62 quadratically foreshortened perspective wave rows (dense & fine near horizon, wider in foreground)
    const rowCount = 62;
    _waveBands = List.generate(rowCount, (i) {
      final t = (i + 0.5) / rowCount;
      final yNorm = math.pow(t, 1.76).toDouble();
      return _WaterWaveBand(
        yRel: yNorm,
        speed: 1.05 + (rand.nextDouble() * 1.45),
        frequency: 0.25 + (rand.nextDouble() * 0.75), // deterministic glint variation seed
        phase: rand.nextDouble() * math.pi * 2,
        secondaryFrequency: rand.nextDouble(), // ambient swell horizontal anchor
        secondaryPhase: rand.nextDouble() * math.pi * 2,
        amplitude: 0.45 + (rand.nextDouble() * 0.55), // brightness/length weight
        thickness: 0.85 + (yNorm * 2.85),
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

  /// Procedurally generates an organic, non-template multi-layer cloudscape across an extended sky belt:
  /// - Seeded per calendar day so each day has unique natural weather formations
  /// - 4 distinct meteorological archetypes (asymmetric billowing cumulus, sleek windswept stratocumulus,
  ///   broken fair-weather fractus clusters with detached wisps, and airy high altocumulus)
  /// - Distributed over a 2.9x-wide scrolling sky belt with altitude-varied wind shear so positions,
  ///   groupings, and silhouettes evolve naturally throughout the day instead of staying fixed
  void _initPhotorealisticClouds(int daySeed) {
    final rand = math.Random(daySeed);
    double range(double min, double max) => min + rand.nextDouble() * (max - min);

    Path buildOrganicCumulusPath(List<_CumulusPuff> baseEllipses, List<_CumulusPuff> silhouettePuffs) {
      Path? combined;
      void unionOval(_CumulusPuff p) {
        final oval = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(p.dx, p.dy),
              width: p.rx * 2,
              height: p.ry * 2,
            ),
          );
        combined = combined == null
            ? oval
            : Path.combine(PathOperation.union, combined!, oval);
      }

      for (final b in baseEllipses) {
        unionOval(b);
      }
      for (final p in silhouettePuffs) {
        unionOval(p);
      }
      return combined ?? Path();
    }

    /// Generates a single sculpted, non-repeating cloud matching one of 5 natural meteorological archetypes:
    /// 0 = Asymmetric Billowing Cumulus, 1 = Elongated Windswept Stratocumulus,
    /// 2 = Broken Fair-Weather Fractus, 3 = Airy High Altocumulus Veil, 4 = Soft Companion Wisp
    _VolumetricCloudFormation buildProceduralCloud({
      required int archetype,
      required double xRel,
      required double yRel,
      required double scale,
      required double driftSpeed,
      required double layerDepth,
      required double opacityScale,
    }) {
      final baseEllipses = <_CumulusPuff>[];
      final silhouettePuffs = <_CumulusPuff>[];
      final volumePuffs = <_CumulusPuff>[];
      final shadowPockets = <_CumulusPuff>[];

      // Random horizontal lean direction & base undulation phase so no two clouds look alike
      final flip = rand.nextBool() ? 1.0 : -1.0;
      final baseWavePhase = range(0.0, math.pi * 2);

      if (archetype == 0) {
        // --- Archetype 0: Asymmetric Billowing Cumulus (off-center convective tower + shoulder + wind tail) ---
        final halfW = range(78.0, 108.0);
        final peakH = range(34.0, 48.0);
        final peakU = flip * range(0.14, 0.36);
        final shoulderU = -flip * range(0.18, 0.42);
        final shoulderH = peakH * range(0.52, 0.76);
        final tertiaryU = flip * range(0.46, 0.64);
        final tertiaryH = peakH * range(0.32, 0.50);

        // Gently undulating solid condensation base (zero pinholes, zero ruler-flat bottom)
        final tailSign = -flip;
        for (int k = 0; k < 6; k++) {
          final u = -0.94 + (k / 5.0) * 1.88;
          final edgeFactor = (1.0 - u * u).clamp(0.08, 1.0);
          final bx = u * halfW + (u * tailSign > 0.5 ? tailSign * 10.0 : 0.0);
          final brx = halfW * (0.22 + 0.16 * edgeFactor);
          final bry = 3.2 + 7.8 * math.sqrt(edgeFactor);
          final undulateY = math.sin(u * 2.5 + baseWavePhase) * 2.0 * edgeFactor;
          baseEllipses.add(_CumulusPuff(bx, -bry * 0.72 + undulateY, brx, bry));
        }

        // Smooth multi-peak convective envelope sampled with closely overlapping organic domes
        const steps = 11;
        for (int s = 0; s < steps; s++) {
          final u = -0.86 + (s / (steps - 1)) * 1.72;
          final dPeak = (u - peakU) / 0.34;
          final dShoulder = (u - shoulderU) / 0.36;
          final dTert = (u - tertiaryU) / 0.28;
          final edgeTapering = math.pow((1.0 - (u * 0.96) * (u * 0.96)).clamp(0.0, 1.0), 0.52).toDouble();

          final rawH = math.max(
            peakH * math.exp(-dPeak * dPeak),
            math.max(
              shoulderH * math.exp(-dShoulder * dShoulder),
              tertiaryH * math.exp(-dTert * dTert),
            ),
          );
          final h = (5.0 + rawH * (0.72 + 0.28 * edgeTapering)) * range(0.92, 1.08);
          final cx = u * halfW + range(-2.5, 2.5);
          final rx = (halfW / steps) * range(1.55, 2.10) * (0.75 + 0.32 * edgeTapering);
          final ry = math.max(4.5, h * 0.56);
          silhouettePuffs.add(_CumulusPuff(cx, -ry * 1.05, rx, ry));
        }

        // Intricate cauliflower micro-ridges perched near the primary & shoulder crests
        final ridgeAnchors = [
          (peakU - 0.10 * flip, peakH * 0.92),
          (peakU + 0.06 * flip, peakH * 0.98),
          (peakU + 0.18 * flip, peakH * 0.74),
          (shoulderU - 0.06 * flip, shoulderH * 0.94),
          (shoulderU + 0.10 * flip, shoulderH * 0.86),
        ];
        for (final anchor in ridgeAnchors) {
          final rX = anchor.$1 * halfW + range(-4.0, 4.0);
          final rY = -anchor.$2 * range(0.84, 0.96);
          silhouettePuffs.add(_CumulusPuff(rX, rY, range(9.5, 14.0), range(7.5, 11.5)));
        }

        volumePuffs.addAll([
          _CumulusPuff(peakU * halfW, -peakH * 0.62, halfW * 0.38, peakH * 0.56),
          _CumulusPuff(shoulderU * halfW, -shoulderH * 0.58, halfW * 0.34, shoulderH * 0.52),
          _CumulusPuff(tertiaryU * halfW, -tertiaryH * 0.54, halfW * 0.28, tertiaryH * 0.48),
        ]);
        shadowPockets.addAll([
          _CumulusPuff(peakU * halfW * 0.72, -peakH * 0.22, halfW * 0.38, peakH * 0.24),
          _CumulusPuff(shoulderU * halfW * 0.82, -shoulderH * 0.22, halfW * 0.34, shoulderH * 0.24),
        ]);
      } else if (archetype == 1) {
        // --- Archetype 1: Elongated Windswept Stratocumulus Deck (sleek undulating ribbon with soft swells) ---
        final halfW = range(92.0, 122.0);
        final maxH = range(21.0, 32.0);
        final swell1U = flip * range(0.16, 0.42);
        final swell2U = -flip * range(0.22, 0.50);
        final swell3U = flip * range(-0.10, 0.14);

        for (int k = 0; k < 7; k++) {
          final u = -0.96 + (k / 6.0) * 1.92;
          final edge = (1.0 - u * u).clamp(0.06, 1.0);
          final brx = halfW * (0.18 + 0.15 * edge);
          final bry = 2.6 + 5.2 * math.sqrt(edge);
          final undulateY = math.sin(u * 2.8 + baseWavePhase) * 2.8 * edge;
          baseEllipses.add(_CumulusPuff(u * halfW, -bry * 0.72 + undulateY, brx, bry));
        }

        const steps = 11;
        for (int s = 0; s < steps; s++) {
          final u = -0.88 + (s / (steps - 1)) * 1.76;
          final edge = math.pow((1.0 - (u * 0.95) * (u * 0.95)).clamp(0.0, 1.0), 0.55).toDouble();
          final h1 = maxH * math.exp(-math.pow((u - swell1U) / 0.32, 2));
          final h2 = maxH * range(0.65, 0.86) * math.exp(-math.pow((u - swell2U) / 0.36, 2));
          final h3 = maxH * range(0.45, 0.70) * math.exp(-math.pow((u - swell3U) / 0.28, 2));
          final h = (4.2 + math.max(h1, math.max(h2, h3)) * (0.65 + 0.35 * edge));
          final rx = (halfW / steps) * range(1.65, 2.25);
          final ry = math.max(3.8, h * 0.54);
          final undulateY = math.sin(u * 2.8 + baseWavePhase) * 2.2 * edge;
          silhouettePuffs.add(_CumulusPuff(u * halfW + range(-3.0, 3.0), -ry * 1.02 + undulateY, rx, ry));
        }

        silhouettePuffs.add(_CumulusPuff(swell1U * halfW, -maxH * 0.84, range(10.0, 14.0), range(6.5, 9.0)));
        silhouettePuffs.add(_CumulusPuff(swell2U * halfW, -maxH * 0.70, range(9.5, 13.5), range(6.0, 8.5)));

        volumePuffs.addAll([
          _CumulusPuff(swell1U * halfW, -maxH * 0.54, halfW * 0.36, maxH * 0.50),
          _CumulusPuff(swell2U * halfW, -maxH * 0.46, halfW * 0.34, maxH * 0.46),
        ]);
        shadowPockets.addAll([
          _CumulusPuff(-halfW * 0.32, -maxH * 0.20, halfW * 0.34, maxH * 0.24),
          _CumulusPuff(halfW * 0.28, -maxH * 0.20, halfW * 0.34, maxH * 0.24),
        ]);
      } else if (archetype == 2) {
        // --- Archetype 2: Broken Fair-Weather Cumulus Humilis (irregular asymmetric mid-small puff) ---
        final halfW = range(48.0, 68.0);
        final peakH = range(21.0, 34.0);
        final peakU = flip * range(0.12, 0.36);

        for (int k = 0; k < 5; k++) {
          final u = -0.90 + (k / 4.0) * 1.80;
          final edge = (1.0 - u * u).clamp(0.08, 1.0);
          final undulateY = math.sin(u * 2.6 + baseWavePhase) * 2.0 * edge;
          baseEllipses.add(_CumulusPuff(u * halfW, -4.4 + undulateY, halfW * 0.30, 2.6 + 4.4 * edge));
        }

        const steps = 8;
        for (int s = 0; s < steps; s++) {
          final u = -0.84 + (s / (steps - 1)) * 1.68;
          final edge = math.pow((1.0 - (u * 0.94) * (u * 0.94)).clamp(0.0, 1.0), 0.5).toDouble();
          final h = (4.5 + peakH * math.exp(-math.pow((u - peakU) / 0.42, 2)) * (0.65 + 0.35 * edge)) *
              range(0.88, 1.12);
          final rx = (halfW / steps) * range(1.65, 2.20);
          final ry = math.max(4.0, h * 0.56);
          silhouettePuffs.add(_CumulusPuff(u * halfW, -ry * 1.04, rx, ry));
        }
        silhouettePuffs.add(_CumulusPuff(peakU * halfW + range(-5, 5), -peakH * 0.88, range(8.5, 11.5), range(6.5, 9.0)));

        volumePuffs.addAll([
          _CumulusPuff(peakU * halfW, -peakH * 0.58, halfW * 0.48, peakH * 0.54),
          _CumulusPuff(-peakU * halfW * 0.6, -peakH * 0.42, halfW * 0.40, peakH * 0.42),
        ]);
        shadowPockets.add(_CumulusPuff(0, -peakH * 0.22, halfW * 0.56, peakH * 0.25));
      } else if (archetype == 3) {
        // --- Archetype 3: Airy High-Altitude Altocumulus Veil (soft undulating stretched cloudlet) ---
        final halfW = range(62.0, 88.0);
        final maxH = range(14.0, 21.0);
        final peakU = flip * range(0.10, 0.35);

        for (int k = 0; k < 5; k++) {
          final u = -0.92 + (k / 4.0) * 1.84;
          final edge = (1.0 - u * u).clamp(0.08, 1.0);
          final undulateY = math.sin(u * 3.0 + baseWavePhase) * 2.2 * edge;
          baseEllipses.add(_CumulusPuff(u * halfW, -3.2 + undulateY, halfW * 0.28, 2.2 + 3.0 * edge));
        }
        const steps = 7;
        for (int s = 0; s < steps; s++) {
          final u = -0.84 + (s / (steps - 1)) * 1.68;
          final edge = (1.0 - (u * 0.94) * (u * 0.94)).clamp(0.08, 1.0);
          final h = 3.5 + maxH * math.exp(-math.pow((u - peakU) / 0.52, 2)) * (0.55 + 0.45 * edge);
          silhouettePuffs.add(_CumulusPuff(u * halfW, -h * 0.54, (halfW / steps) * 1.95, h * 0.52));
        }

        volumePuffs.add(_CumulusPuff(peakU * halfW * 0.6, -maxH * 0.52, halfW * 0.50, maxH * 0.52));
        shadowPockets.add(_CumulusPuff(0, -maxH * 0.22, halfW * 0.52, maxH * 0.25));
      } else {
        // --- Archetype 4: Soft Companion Wisp (independent small cloudlet with its own natural shading gradient) ---
        final halfW = range(26.0, 42.0);
        final peakH = range(10.0, 17.0);
        final peakU = flip * range(0.10, 0.32);

        for (int k = 0; k < 4; k++) {
          final u = -0.88 + (k / 3.0) * 1.76;
          final edge = (1.0 - u * u).clamp(0.10, 1.0);
          baseEllipses.add(_CumulusPuff(u * halfW, -2.6, halfW * 0.34, 1.8 + 2.8 * edge));
        }
        const steps = 5;
        for (int s = 0; s < steps; s++) {
          final u = -0.78 + (s / (steps - 1)) * 1.56;
          final edge = (1.0 - u * u).clamp(0.12, 1.0);
          final h = 3.0 + peakH * math.exp(-math.pow((u - peakU) / 0.50, 2)) * (0.60 + 0.40 * edge);
          silhouettePuffs.add(_CumulusPuff(u * halfW, -h * 0.52, (halfW / steps) * 2.1, h * 0.52));
        }

        volumePuffs.add(_CumulusPuff(peakU * halfW * 0.5, -peakH * 0.50, halfW * 0.52, peakH * 0.52));
        shadowPockets.add(_CumulusPuff(0, -peakH * 0.22, halfW * 0.55, peakH * 0.24));
      }

      final outerPath = buildOrganicCumulusPath(baseEllipses, silhouettePuffs);
      return _VolumetricCloudFormation(
        xRel: xRel,
        yRel: yRel,
        scale: scale,
        driftSpeed: driftSpeed,
        layerDepth: layerDepth,
        opacityScale: opacityScale,
        bobSpeed: range(0.15, 0.27),
        bobPhase: range(0.0, math.pi * 2),
        outerPath: outerPath,
        outerBounds: outerPath.getBounds(),
        volumePuffs: volumePuffs,
        shadowPockets: shadowPockets,
      );
    }

    // 1. High-altitude sweeping gossamer cirrus veils across an extended 2.8x belt
    const cirrusBeltSpan = 2.80;
    const cirrusCount = 6;
    _cirrusStreaks = List.generate(cirrusCount, (i) {
      final slotX = ((i + 0.5) / cirrusCount) * cirrusBeltSpan + range(-0.18, 0.18);
      return _CirrusStreak(
        xRel: slotX % cirrusBeltSpan,
        yRel: range(0.05, 0.21),
        width: range(155.0, 265.0),
        thickness: range(4.5, 7.6),
        tiltRadians: range(-0.095, 0.085),
        curveLift: range(9.0, 21.0),
        driftSpeed: range(0.0010, 0.0020),
        opacity: range(0.18, 0.34),
        phase: range(0.0, math.pi * 2),
      );
    });

    // 2. Diverse non-template procedural clouds spread organically across a 2.9x scrolling sky belt
    // At any moment ~4-6 clouds + occasional soft companion wisps are visible with varied silhouettes & depths
    const cloudBeltSpan = 2.90;
    final archetypes = <int>[0, 2, 1, 3, 0, 2, 1, 0, 3, 2, 1, 2];
    // Shuffle archetype order deterministically per day so patterns never repeat
    for (int i = archetypes.length - 1; i > 0; i--) {
      final j = rand.nextInt(i + 1);
      final tmp = archetypes[i];
      archetypes[i] = archetypes[j];
      archetypes[j] = tmp;
    }

    final generatedClouds = <_VolumetricCloudFormation>[];
    double prevY = 0.25;
    for (int i = 0; i < archetypes.length; i++) {
      final archetype = archetypes[i];
      // Stratified organic spacing with deliberate pairing & open-sky gaps (never uniform grid!)
      final baseSlot = ((i + 0.5) / archetypes.length) * cloudBeltSpan;
      final jitterX = range(-0.14, 0.14);
      final xRel = (baseSlot + jitterX + cloudBeltSpan) % cloudBeltSpan;

      // Altitude band tailored to cloud meteorology while avoiding consecutive same-row lining up
      double minY, maxY, minScale, maxScale, minDepth, maxDepth, minSpeed, maxSpeed, minOp, maxOp;
      switch (archetype) {
        case 0: // Billowing cumulus (mid-sky heroes)
          minY = 0.17; maxY = 0.38;
          minScale = 0.72; maxScale = 1.04;
          minDepth = 0.84; maxDepth = 1.00;
          minSpeed = 0.0024; maxSpeed = 0.0036;
          minOp = 0.92; maxOp = 1.00;
          break;
        case 1: // Windswept stratocumulus ribbons (lower-mid atmospheric sweep)
          minY = 0.26; maxY = 0.49;
          minScale = 0.68; maxScale = 0.94;
          minDepth = 0.62; maxDepth = 0.84;
          minSpeed = 0.0030; maxSpeed = 0.0044;
          minOp = 0.80; maxOp = 0.94;
          break;
        case 2: // Broken fair-weather fractus (scattered mid/upper accents)
          minY = 0.12; maxY = 0.46;
          minScale = 0.54; maxScale = 0.82;
          minDepth = 0.58; maxDepth = 0.88;
          minSpeed = 0.0026; maxSpeed = 0.0042;
          minOp = 0.78; maxOp = 0.94;
          break;
        default: // Airy high altocumulus veils (upper depth)
          minY = 0.08; maxY = 0.24;
          minScale = 0.56; maxScale = 0.80;
          minDepth = 0.42; maxDepth = 0.58;
          minSpeed = 0.0017; maxSpeed = 0.0026;
          minOp = 0.66; maxOp = 0.82;
      }

      double yRel = range(minY, maxY);
      if ((yRel - prevY).abs() < 0.075) {
        yRel = yRel + (yRel > (minY + maxY) * 0.5 ? -0.09 : 0.09);
        yRel = yRel.clamp(minY, maxY);
      }
      prevY = yRel;

      final chosenSpeed = range(minSpeed, maxSpeed);
      final chosenDepth = range(minDepth, maxDepth);
      final chosenScale = range(minScale, maxScale);

      generatedClouds.add(
        buildProceduralCloud(
          archetype: archetype,
          xRel: xRel,
          yRel: yRel,
          scale: chosenScale,
          driftSpeed: chosenSpeed,
          layerDepth: chosenDepth,
          opacityScale: range(minOp, maxOp),
        ),
      );

      // Spawn a separate softly-shaded companion cloudlet near ~45% of cumulus & fractus clouds
      // (drifts together as a natural broken cluster while keeping proper top-to-bottom 3D lighting)
      if ((archetype == 0 || archetype == 2) && rand.nextDouble() < 0.48) {
        final side = rand.nextBool() ? 1.0 : -1.0;
        final wispX = (xRel + side * range(0.14, 0.24) + cloudBeltSpan) % cloudBeltSpan;
        final wispY = (yRel + range(-0.045, 0.025)).clamp(0.08, 0.50);
        generatedClouds.add(
          buildProceduralCloud(
            archetype: 4,
            xRel: wispX,
            yRel: wispY,
            scale: chosenScale * range(0.72, 1.05),
            driftSpeed: chosenSpeed * range(0.96, 1.05),
            layerDepth: (chosenDepth - 0.14).clamp(0.38, 0.86),
            opacityScale: range(0.62, 0.78),
          ),
        );
      }
    }

    // Pre-sort back-to-front by layerDepth once (avoids per-frame allocation & sorting)
    generatedClouds.sort((a, b) => a.layerDepth.compareTo(b.layerDepth));
    _cloudFormations = generatedClouds;

    // 3. Distant horizon stratocumulus banks scattered across a 2.7x belt (tuck naturally behind mountains)
    const bankBeltSpan = 2.70;
    const bankCount = 5;
    _horizonCloudBanks = List.generate(bankCount, (i) {
      final slotX = ((i + 0.5) / bankCount) * bankBeltSpan + range(-0.20, 0.20);
      final bHalfW = range(66.0, 92.0);
      final bPeakH = range(12.0, 19.0);
      final bFlip = rand.nextBool() ? 1.0 : -1.0;
      return _HorizonCloudBank(
        xRel: (slotX + bankBeltSpan) % bankBeltSpan,
        yRel: range(0.50, 0.57),
        scale: range(0.80, 1.06),
        driftSpeed: range(0.0011, 0.0019),
        opacity: range(0.38, 0.54),
        path: buildOrganicCumulusPath(
          [
            _CumulusPuff(-bHalfW, -3, 28, 4.2),
            _CumulusPuff(0, -4.5, bHalfW * 0.88, 6.2),
            _CumulusPuff(bHalfW, -3, 28, 4.2),
          ],
          [
            _CumulusPuff(-bHalfW * 0.65, -7.5, 25, bPeakH * 0.60),
            _CumulusPuff(-bHalfW * 0.20 * bFlip, -bPeakH * 0.78, 30, bPeakH * 0.92),
            _CumulusPuff(bHalfW * 0.28 * bFlip, -bPeakH * 0.92, 32, bPeakH),
            _CumulusPuff(bHalfW * 0.68, -8.0, 24, bPeakH * 0.58),
          ],
        ),
      );
    });
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
    final preDawnTransitionStart = dawnStart - 35; // Keep deepNight pure until 35 min before Fajr dawn
    final morningStart = terbitM + 60;
    final noonStart = dzuhurM - 30;
    final sunsetStart = maghribM - 40;
    final duskStart = maghribM + 35;
    final nightStart = isyaM + 45;

    if (currentMinutes < preDawnTransitionStart) {
      // Pure cosmic deepNight all through midnight & late night (00:00 - ~03:38)
      currentPhase = SkyPhase.deepNight;
      nextPhase = SkyPhase.deepNight;
      progress = 0.0;
    } else if (currentMinutes < dawnStart) {
      // Smooth 35-minute pre-dawn transition into Fajr twilight (~03:38 - 04:13)
      currentPhase = SkyPhase.deepNight;
      nextPhase = SkyPhase.fajrDawn;
      progress = ((currentMinutes - preDawnTransitionStart) / (dawnStart - preDawnTransitionStart))
          .clamp(0.0, 1.0);
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
      // Pure deepNight after Isya settles (~20:00 - 23:59)
      currentPhase = SkyPhase.deepNight;
      nextPhase = SkyPhase.deepNight;
      progress = 0.0;
    }

    final paletteA = SkyThemePalette.getPaletteForPhase(currentPhase);
    final paletteB = SkyThemePalette.getPaletteForPhase(nextPhase);
    // Drive isMoon strictly from real daytime/nighttime (!isDaytime) instead of palette lerp midpoint
    final palette = SkyThemePalette.lerp(
      paletteA,
      paletteB,
      progress,
      isMoonOverride: !isDaytime,
    );

    // Piecewise sunProgress anchored so:
    //   terbitM  -> 0.0 (rising East)
    //   dzuhurM  -> 0.5 (exact Zenith at Dzuhur!)
    //   maghribM -> 1.0 (setting West)
    double sunProgress = 0.0;
    if (isDaytime) {
      if (currentMinutes <= dzuhurM) {
        final morningSpan = math.max(1.0, (dzuhurM - terbitM).toDouble());
        sunProgress = (((currentMinutes - terbitM) / morningSpan) * 0.5).clamp(0.0, 0.5);
      } else {
        final afternoonSpan = math.max(1.0, (maghribM - dzuhurM).toDouble());
        sunProgress = (0.5 + ((currentMinutes - dzuhurM) / afternoonSpan) * 0.5).clamp(0.5, 1.0);
      }
    }

    // Moon arc from Maghrib (0.0, rising East) -> Midnight (0.5, Zenith) -> Terbit (1.0, setting West)
    double moonProgress = 0.0;
    if (!isDaytime) {
      final totalNightMinutes = math.max(1.0, (1440 - maghribM + terbitM).toDouble());
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
      terbitTimeStr: widget.terbitTime ?? '05:50',
      maghribTimeStr: widget.maghribTime ?? '18:05',
      birdVisibility: birdVisibility,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.customTime ?? DateTime.now();
    final daySeed = _computeDaySeed(now);
    if (daySeed != _cloudDaySeed) {
      _cloudDaySeed = daySeed;
      _initPhotorealisticClouds(_cloudDaySeed);
    }

    final skyState = _calculateSkyState();
    // Continuous real-time wind clock: runs butter-smooth at 60/120 FPS AND carries real-clock progression across hours
    final cloudTimeSeconds = widget.customTime != null
        ? (widget.customTime!.hour * 3600.0 +
              widget.customTime!.minute * 60.0 +
              widget.customTime!.second +
              _elapsedSeconds)
        : (_liveClockBaseSeconds + _elapsedSeconds);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CinematicScenicPainter(
          skyState: skyState,
          elapsedSeconds: _elapsedSeconds,
          cloudTimeSeconds: cloudTimeSeconds,
          stars: _stars,
          waveBands: _waveBands,
          valleyFogs: _valleyFogs,
          cloudFormations: _cloudFormations,
          cirrusStreaks: _cirrusStreaks,
          horizonCloudBanks: _horizonCloudBanks,
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
          cloudHighlight: const Color(0xFFFFB599),
          cloudBody: const Color(0xFF6B4F7E),
          cloudShadow: const Color(0xFF211E44),
          cloudOpacity: 0.48,
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
          cloudHighlight: const Color(0xFFFFEAB0),
          cloudBody: const Color(0xFFFDF3EA),
          cloudShadow: const Color(0xFF6684A8),
          cloudOpacity: 0.90,
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
          cloudBody: const Color(0xFFF3F9FF),
          cloudShadow: const Color(0xFF8AB7D8),
          cloudOpacity: 0.96,
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
          cloudBody: const Color(0xFFF5FAFF),
          cloudShadow: const Color(0xFF90BFDD),
          cloudOpacity: 0.96,
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
          cloudHighlight: const Color(0xFFFFEEC0),
          cloudBody: const Color(0xFFF8ECE0),
          cloudShadow: const Color(0xFF747D99),
          cloudOpacity: 0.94,
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
          cloudHighlight: const Color(0xFFFFBD59),
          cloudBody: const Color(0xFFE07A6E),
          cloudShadow: const Color(0xFF48234D),
          cloudOpacity: 0.88,
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
          cloudHighlight: const Color(0xFF9F7A99),
          cloudBody: const Color(0xFF3E2F5C),
          cloudShadow: const Color(0xFF1A1E3D),
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
          cloudHighlight: const Color(0xFF4B4F78),
          cloudBody: const Color(0xFF1F2747),
          cloudShadow: const Color(0xFF0D152B),
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

  static SkyThemePalette lerp(
    SkyThemePalette a,
    SkyThemePalette b,
    double t, {
    bool? isMoonOverride,
  }) {
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
      isMoon: isMoonOverride ?? (clampedT < 0.5 ? a.isMoon : b.isMoon),
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

class _CumulusPuff {
  final double dx;
  final double dy;
  final double rx;
  final double ry;

  const _CumulusPuff(this.dx, this.dy, this.rx, this.ry);
}

class _VolumetricCloudFormation {
  final double xRel;
  final double yRel;
  final double scale;
  final double driftSpeed;
  final double layerDepth;
  final double opacityScale;
  final double bobSpeed;
  final double bobPhase;
  final Path outerPath;
  final Rect outerBounds;
  final List<_CumulusPuff> volumePuffs;
  final List<_CumulusPuff> shadowPockets;

  _VolumetricCloudFormation({
    required this.xRel,
    required this.yRel,
    required this.scale,
    required this.driftSpeed,
    required this.layerDepth,
    this.opacityScale = 1.0,
    required this.bobSpeed,
    required this.bobPhase,
    required this.outerPath,
    required this.outerBounds,
    required this.volumePuffs,
    required this.shadowPockets,
  });
}

class _CirrusStreak {
  final double xRel;
  final double yRel;
  final double width;
  final double thickness;
  final double tiltRadians;
  final double curveLift;
  final double driftSpeed;
  final double opacity;
  final double phase;

  const _CirrusStreak({
    required this.xRel,
    required this.yRel,
    required this.width,
    required this.thickness,
    required this.tiltRadians,
    required this.curveLift,
    required this.driftSpeed,
    required this.opacity,
    required this.phase,
  });
}

class _HorizonCloudBank {
  final double xRel;
  final double yRel;
  final double scale;
  final double driftSpeed;
  final double opacity;
  final Path path;

  _HorizonCloudBank({
    required this.xRel,
    required this.yRel,
    required this.scale,
    required this.driftSpeed,
    required this.opacity,
    required this.path,
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

class _BuildingWindowLight {
  final Offset pos;
  final double width;
  final double height;
  final bool isMidground;
  final bool castsWaterReflection;
  final double twinklePhase;
  final double intensity;

  const _BuildingWindowLight({
    required this.pos,
    required this.width,
    required this.height,
    this.isMidground = false,
    this.castsWaterReflection = false,
    this.twinklePhase = 0.0,
    this.intensity = 1.0,
  });
}

class _PalmTreeSpec {
  final Offset base;
  final double height;
  final double swaySign;
  final double swayMult;
  final double leanDir;

  const _PalmTreeSpec({
    required this.base,
    required this.height,
    required this.swaySign,
    required this.swayMult,
    required this.leanDir,
  });
}

class _CoastalCityGeometry {
  final Path midSkylinePath;
  final Path foreSkylinePath;
  final List<Offset> crescentTips;
  final List<_PalmTreeSpec> palms;
  final List<_BuildingWindowLight> windows;

  const _CoastalCityGeometry({
    required this.midSkylinePath,
    required this.foreSkylinePath,
    required this.crescentTips,
    required this.palms,
    required this.windows,
  });
}

/// Cinematic Master Painter for Living Scenic Landscape
class _CinematicScenicPainter extends CustomPainter {
  final _SkyStateData skyState;
  final double elapsedSeconds;
  final double cloudTimeSeconds;
  final List<_StarData> stars;
  final List<_WaterWaveBand> waveBands;
  final List<_ValleyFogData> valleyFogs;
  final List<_VolumetricCloudFormation> cloudFormations;
  final List<_CirrusStreak> cirrusStreaks;
  final List<_HorizonCloudBank> horizonCloudBanks;
  final List<_FlyingBirdData> birds;
  final double shootingStarProgress;
  final Offset shootingStarStart;
  final Offset shootingStarEnd;

  _CinematicScenicPainter({
    required this.skyState,
    required this.elapsedSeconds,
    required this.cloudTimeSeconds,
    required this.stars,
    required this.waveBands,
    required this.valleyFogs,
    required this.cloudFormations,
    required this.cirrusStreaks,
    required this.horizonCloudBanks,
    required this.birds,
    required this.shootingStarProgress,
    required this.shootingStarStart,
    required this.shootingStarEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final horizonY = height * 0.67;

    // 1. Compute Celestial Orb (Sun or Moon) Center Position along East -> Zenith -> West Arc
    final orbPos = _calculateCelestialPosition(size, horizonY);

    // 2. Draw Atmospheric Sky Dome Gradient (horizon glow tracks actual celestial azimuth)
    _drawSkyDomeGradient(canvas, size, horizonY, orbPos);

    // 3. Draw Twinkling Stardust Field & Dynamic Shooting Star (Night & twilight)
    if (skyState.palette.starVisibility > 0.05) {
      _drawStarField(canvas, size, skyState.palette.starVisibility);
      if (skyState.palette.starVisibility > 0.70) {
        _drawShootingStar(canvas, size, skyState.palette.starVisibility);
      }
    }

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

    // 8. Build shared coastal Islamic skyline geometry once (reused for exact water reflections)
    final coastalCity = _buildCoastalCityGeometry(size.width, horizonY);
    _drawCoastalMosquesAndPalms(canvas, size, horizonY, coastalCity);

    // 9. Draw Hyper-Realistic Living Water: Fresnel Sky Mirror, Wave-Rippled City Reflections & Sun/Moon Glitter Path
    _drawLivingWaterAndReflection(canvas, size, horizonY, orbPos, coastalCity);
  }

  /// Computes realistic curved East (left) -> Zenith (center) -> West (right) sky arc:
  /// - Sun: rises East at Terbit (0.0), reaches exact Zenith at Dzuhur (0.5), sets West at Maghrib (1.0)
  /// - Moon: rises East after Maghrib (0.0), reaches Zenith at midnight (0.5), sets West by Terbit (1.0)
  Offset _calculateCelestialPosition(Size size, double horizonY) {
    final isMoon = !skyState.isDaytime;
    final p = (isMoon ? skyState.moonProgress : skyState.sunProgress).clamp(0.0, 1.0);
    final radius = isMoon ? 21.0 : 25.5;

    // Curved East-to-West horizontal sweep (16% -> 50% -> 84% of viewport width)
    final currentX = size.width * (0.16 + p * 0.68);

    // Smooth atmospheric arc elevation: rises cleanly over eastern ridge, peaks at zenith (~21% from top), sets west
    final sinArc = math.sin(p * math.pi).clamp(0.0, 1.0);
    final elevation = math.pow(sinArc, 0.52).toDouble();
    final sinkY = horizonY + radius * 0.35;
    final topY = size.height * 0.21;
    final currentY = sinkY - (elevation * (sinkY - topY));

    return Offset(currentX, currentY);
  }

  /// 1. Deep Atmospheric Sky Dome Gradient (horizon glow tracks actual East/West solar azimuth)
  void _drawSkyDomeGradient(Canvas canvas, Size size, double horizonY, Offset orbPos) {
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

    // During Fajr pre-dawn, glow warms the eastern (left) horizon ahead of sunrise;
    // otherwise glow follows the live celestial orb azimuth smoothly.
    final glowAlignX = skyState.phase == SkyPhase.fajrDawn
        ? -0.62
        : ((orbPos.dx / size.width) * 2.0 - 1.0).clamp(-0.85, 0.85);
    final ambientGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(glowAlignX, (horizonY / size.height) * 2 - 1),
        radius: 0.92,
        colors: [
          palette.sunGlowOuter.withOpacity(0.26),
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
    if (skyState.isDaytime) {
      _drawPhotorealisticSun(canvas, size, orbPos, horizonY);
    } else {
      // Smooth lunar fade-in right after Maghrib and gentle fade-out as Fajr dawn brightens
      double moonOpacity = 1.0;
      if (skyState.moonProgress < 0.04) {
        moonOpacity = (skyState.moonProgress / 0.04).clamp(0.0, 1.0);
      } else if (skyState.phase == SkyPhase.fajrDawn) {
        moonOpacity = (1.0 - skyState.phaseProgress * 0.72).clamp(0.18, 1.0);
      }
      if (moonOpacity > 0.02) {
        if (moonOpacity < 0.99) {
          canvas.saveLayer(
            Rect.fromCircle(center: orbPos, radius: 160),
            Paint()..color = Colors.white.withOpacity(moonOpacity),
          );
          _drawPhotorealisticMoon(canvas, size, orbPos, horizonY);
          canvas.restore();
        } else {
          _drawPhotorealisticMoon(canvas, size, orbPos, horizonY);
        }
      }
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

  /// 4. Multi-Layer Volumetric Clouds: High Cirrus, Distant Horizon Banks & Sculpted Sun-Lit Cumulus
  void _drawPhotorealisticClouds(Canvas canvas, Size size, double horizonY, Offset orbPos) {
    // Pure clear starlit sky at night & dusk (keep Fajr dawn & daytime/sunset clouds visible)
    if (skyState.phase == SkyPhase.deepNight || skyState.phase == SkyPhase.dusk) return;

    final globalCloudOpacity = skyState.palette.cloudOpacity;
    if (globalCloudOpacity <= 0.01) return;

    // During Fajr pre-dawn, clouds are lit warmly from the rising eastern horizon glow
    final effectiveLightPos = skyState.phase == SkyPhase.fajrDawn
        ? Offset(size.width * 0.16, horizonY + 14.0)
        : orbPos;

    // 0.0 when sun is high (morning/noon), 1.0 when sun is near or below horizon (fajr/sunrise/sunset)
    final sunElevNorm = ((horizonY - effectiveLightPos.dy) / (horizonY * 0.72)).clamp(0.0, 1.0);
    final lowSunFactor = (1.0 - sunElevNorm).clamp(0.0, 1.0);

    // Layer A: High-Altitude Gossamer Cirrus Veils (upper sky depth)
    _drawCirrusStreaks(canvas, size, effectiveLightPos, globalCloudOpacity, lowSunFactor);

    // Layer B: Distant Horizon Stratocumulus Banks (tuck naturally behind mountains)
    _drawHorizonCloudBanks(canvas, size, horizonY, effectiveLightPos, globalCloudOpacity, lowSunFactor);

    // Layer C: Sculpted Volumetric Clouds (already pre-sorted back-to-front by layerDepth)
    for (final cloud in cloudFormations) {
      _drawSingleVolumetricCloud(
        canvas,
        size,
        cloud,
        effectiveLightPos,
        globalCloudOpacity,
        lowSunFactor,
      );
    }
  }

  /// Smooth off-screen horizontal wrap over an extended scrolling sky belt driven by real clock time
  /// (so organic cloud compositions evolve naturally across hours & days without repeating fixed stamps)
  double _wrapCloudX(
    double initialXRel,
    double driftSpeed,
    double width,
    double marginRel, {
    double beltSpan = 2.90,
  }) {
    final shifted = (initialXRel + marginRel + cloudTimeSeconds * driftSpeed) % beltSpan;
    final positive = shifted < 0 ? shifted + beltSpan : shifted;
    return (positive - marginRel) * width;
  }

  /// Layer A: Delicate sweeping high-altitude gossamer cirrus veils
  void _drawCirrusStreaks(
    Canvas canvas,
    Size size,
    Offset orbPos,
    double globalCloudOpacity,
    double lowSunFactor,
  ) {
    final palette = skyState.palette;
    final width = size.width;
    final height = size.height;

    for (final streak in cirrusStreaks) {
      final cx = _wrapCloudX(streak.xRel, streak.driftSpeed, width, 0.40, beltSpan: 2.80);
      final halfSpan = streak.width * 0.56 + 12.0;
      if (cx + halfSpan < 0 || cx - halfSpan > width) continue;
      final cy = streak.yRel * height + math.sin(cloudTimeSeconds * 0.0005 + elapsedSeconds * 0.14 + streak.phase) * 3.0;
      final alpha = (streak.opacity * globalCloudOpacity).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final hw = streak.width * 0.5;
      final ht = streak.thickness * 0.5;
      final lift = streak.curveLift;

      // Sweeping silky main cirrus plume
      final mainRibbon = Path()
        ..moveTo(-hw, lift * 0.30)
        ..cubicTo(
          -hw * 0.45, -ht * 0.9 - lift * 0.50,
          hw * 0.20, -ht * 1.25 - lift * 0.20,
          hw, -lift * 0.32,
        )
        ..cubicTo(
          hw * 0.28, ht * 0.65 - lift * 0.05,
          -hw * 0.38, ht * 0.80 - lift * 0.25,
          -hw, lift * 0.30,
        )
        ..close();

      // Secondary gossamer wisp branching gently below
      final subRibbon = Path()
        ..moveTo(-hw * 0.78, ht * 1.4 + lift * 0.25)
        ..cubicTo(
          -hw * 0.22, ht * 0.55 - lift * 0.18,
          hw * 0.35, ht * 0.30 - lift * 0.14,
          hw * 0.86, ht * 0.90 - lift * 0.24,
        )
        ..cubicTo(
          hw * 0.32, ht * 1.15 - lift * 0.04,
          -hw * 0.26, ht * 1.45 - lift * 0.06,
          -hw * 0.78, ht * 1.4 + lift * 0.25,
        )
        ..close();

      // Fine upper feathery accent filament
      final fineHair = Path()
        ..moveTo(-hw * 0.55, -ht * 1.1 + lift * 0.05)
        ..quadraticBezierTo(0, -ht * 2.1 - lift * 0.35, hw * 0.62, -ht * 0.7 - lift * 0.25)
        ..quadraticBezierTo(0, -ht * 1.3 - lift * 0.22, -hw * 0.55, -ht * 1.1 + lift * 0.05)
        ..close();

      final cirrusTint = Color.lerp(
        palette.cloudHighlight,
        palette.sunGlowMid,
        0.20 + lowSunFactor * 0.42,
      )!;
      final cirrusTail = Color.lerp(palette.cloudBody, palette.cloudHighlight, 0.55)!;

      final rect = Rect.fromCenter(center: Offset.zero, width: streak.width, height: streak.thickness * 6.0);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            cirrusTail.withOpacity(0.0),
            cirrusTint.withOpacity(alpha * 0.55),
            cirrusTint.withOpacity(alpha * 0.92),
            cirrusTail.withOpacity(alpha * 0.48),
            cirrusTail.withOpacity(0.0),
          ],
          stops: const [0.0, 0.20, 0.50, 0.82, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

      final subPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            cirrusTail.withOpacity(0.0),
            cirrusTail.withOpacity(alpha * 0.46),
            cirrusTail.withOpacity(0.0),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(streak.tiltRadians);
      canvas.drawPath(mainRibbon, paint);
      canvas.drawPath(subRibbon, subPaint);
      canvas.drawPath(fineHair, subPaint);
      canvas.restore();
    }
  }

  /// Layer B: Distant perspective-flattened horizon cloud banks blended into atmospheric haze
  void _drawHorizonCloudBanks(
    Canvas canvas,
    Size size,
    double horizonY,
    Offset orbPos,
    double globalCloudOpacity,
    double lowSunFactor,
  ) {
    final palette = skyState.palette;
    final width = size.width;
    final height = size.height;

    final horizonMistTint = Color.lerp(
      palette.skyGradientColors[palette.skyGradientColors.length - 2],
      palette.sunGlowOuter,
      0.34 * lowSunFactor,
    )!;

    for (final bank in horizonCloudBanks) {
      final cx = _wrapCloudX(bank.xRel, bank.driftSpeed, width, 0.38, beltSpan: 2.70);
      if (cx + 150.0 * bank.scale < 0 || cx - 150.0 * bank.scale > width) continue;
      final cy = bank.yRel * height;
      final alpha = (bank.opacity * globalCloudOpacity).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final bounds = bank.path.getBounds();
      final litColor = Color.lerp(palette.cloudHighlight, horizonMistTint, 0.38)!;
      final shadedColor = Color.lerp(palette.cloudShadow, horizonMistTint, 0.58)!;

      final bankPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (lowSunFactor > 0.5 ? shadedColor : litColor).withOpacity(alpha * 0.82),
            Color.lerp(palette.cloudBody, horizonMistTint, 0.42)!.withOpacity(alpha * 0.68),
            (lowSunFactor > 0.5 ? litColor : shadedColor).withOpacity(alpha * 0.36),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(bank.scale, bank.scale * 0.88);
      canvas.drawPath(bank.path, bankPaint);
      canvas.restore();
    }
  }

  /// Layer C: Sculpted Volumetric Cumulus Cloud with Smooth Multi-Puff 3D Relief & Sun-Reactive Lighting
  void _drawSingleVolumetricCloud(
    Canvas canvas,
    Size size,
    _VolumetricCloudFormation cloud,
    Offset orbPos,
    double globalCloudOpacity,
    double lowSunFactor,
  ) {
    final width = size.width;
    final height = size.height;
    final palette = skyState.palette;

    // Smooth real-time horizontal drift over extended belt with off-screen viewport culling
    final cx = _wrapCloudX(cloud.xRel, cloud.driftSpeed, width, 0.42, beltSpan: 2.90);
    final maxReachLeft = -cloud.outerBounds.left * cloud.scale + 24.0;
    final maxReachRight = cloud.outerBounds.right * cloud.scale + 24.0;
    if (cx + maxReachRight < 0 || cx - maxReachLeft > width) return;

    // Gentle real-time altitude swell + subtle live vertical breathing so clouds never sit on fixed rails
    final slowAltShift = math.sin(cloudTimeSeconds * 0.00035 + cloud.bobPhase) * height * 0.024;
    final bobY = math.sin(elapsedSeconds * cloud.bobSpeed + cloud.bobPhase) * 1.5 * cloud.layerDepth;
    final cy = (cloud.yRel * height + slowAltShift + bobY).clamp(height * 0.06, height * 0.54);

    // Subtle organic breathing deformation
    final breath = math.sin(elapsedSeconds * cloud.bobSpeed * 0.8 + cloud.bobPhase) * 0.014;
    final sx = cloud.scale * (1.0 + breath);
    final sy = cloud.scale * (1.0 - breath * 0.4);

    // Direction vector from cloud visual center toward the actual sun (orbPos)
    final cloudVisualCenter = Offset(cx, cy - 16.0 * sy);
    final toSun = orbPos - cloudVisualCenter;
    final distToSun = toSun.distance.clamp(1.0, 2000.0);
    final dirX = toSun.dx / distToSun;
    final dirY = toSun.dy / distToSun;

    // Mie forward-scattering proximity boost when cloud approaches or flanks the sun
    final sunProximity = math.exp(-distToSun / (width * 0.44)).clamp(0.0, 1.0);

    // Elevation-aware lighting axis:
    // - High sun (morning/noon): bright top-lit domes, clean sky-blue shaded underside
    // - Low sun (fajr/sunrise/sunset): glowing warm undersides & sun-facing flanks, velvety twilight upper domes
    final lightAlignX = (dirX * 0.82).clamp(-0.92, 0.92);
    final highSunLightY = (dirY * 0.30 - 0.86).clamp(-1.0, -0.35);
    final lowSunLightY = (dirY * 0.78 + 0.36).clamp(-0.15, 0.92);
    final lightAlignY = highSunLightY + (lowSunLightY - highSunLightY) * lowSunFactor;

    final litAlignment = Alignment(lightAlignX, lightAlignY);
    final shadowAlignment = Alignment(-lightAlignX * 0.70, -lightAlignY * 0.90);

    // Atmospheric aerial perspective blending (distant clouds soften slightly toward sky tone)
    final skyMidColor = palette.skyGradientColors[3];
    final depthFade = (1.0 - cloud.layerDepth) * 0.28;
    final effectiveOpacity =
        (globalCloudOpacity * cloud.opacityScale * (0.72 + 0.28 * cloud.layerDepth)).clamp(0.0, 1.0);

    final highlightCol = Color.lerp(palette.cloudHighlight, skyMidColor, depthFade * 0.50)!;
    final bodyCol = Color.lerp(palette.cloudBody, skyMidColor, depthFade * 0.72)!;
    final shadowCol = Color.lerp(palette.cloudShadow, skyMidColor, depthFade * 0.62)!;
    final rimCol = Color.lerp(
      palette.cloudHighlight,
      palette.sunGlowMid,
      0.32 + lowSunFactor * 0.48 + sunProximity * 0.20,
    )!;

    // Edge softness scales with aerial depth (crisp-soft tops, softer distant clouds)
    final edgeBlur = 1.15 + (1.0 - cloud.layerDepth) * 2.1;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sx, sy);

    final bounds = cloud.outerBounds;
    final layerBounds = bounds.inflate(18.0);

    // Render into a tight per-cloud offscreen layer so base feathering dissolves smoothly into the sky
    canvas.saveLayer(layerBounds, Paint());

    // --- PASS 1: Subtle Sun-Facing Atmospheric Silver/Golden Lining Halo ---
    final rimHaloAlpha = ((0.16 + 0.32 * sunProximity + 0.16 * lowSunFactor) * effectiveOpacity)
        .clamp(0.0, 0.66);
    if (rimHaloAlpha > 0.02) {
      canvas.save();
      canvas.translate(dirX * 2.0, dirY * 1.6);
      final haloPaint = Paint()
        ..shader = LinearGradient(
          begin: litAlignment,
          end: shadowAlignment,
          colors: [
            rimCol.withOpacity(rimHaloAlpha),
            rimCol.withOpacity(rimHaloAlpha * 0.26),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 0.82],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.8);
      canvas.drawPath(cloud.outerPath, haloPaint);
      canvas.restore();
    }

    // --- PASS 2: Unified Cohesive Cloud Silhouette (Zero overlapping seams, zero muddy halo) ---
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: litAlignment,
        end: shadowAlignment,
        colors: [
          highlightCol.withOpacity(effectiveOpacity * 0.98),
          bodyCol.withOpacity(effectiveOpacity * 0.95),
          Color.lerp(bodyCol, shadowCol, 0.56)!.withOpacity(effectiveOpacity * 0.93),
          shadowCol.withOpacity(effectiveOpacity * 0.90),
        ],
        stops: const [0.0, 0.36, 0.72, 1.0],
      ).createShader(bounds)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, edgeBlur);
    canvas.drawPath(cloud.outerPath, basePaint);

    // --- PASS 3..6: Clipped Internal 3D Volumetric Sculpting ---
    canvas.save();
    canvas.clipPath(cloud.outerPath);

    // Pass 3: Soft Flat-Base Condensation Shadow & Low-Sun Warm Horizon Bounce
    final baseShadowTop = bounds.bottom - bounds.height * 0.44;
    final baseShadowRect = Rect.fromLTRB(bounds.left, baseShadowTop, bounds.right, bounds.bottom + 4);
    final baseShadowStrength = (0.54 - lowSunFactor * 0.34).clamp(0.14, 0.56);
    final undersidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          shadowCol.withOpacity(effectiveOpacity * baseShadowStrength * 0.62),
          shadowCol.withOpacity(effectiveOpacity * baseShadowStrength),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(baseShadowRect);
    canvas.drawRect(baseShadowRect, undersidePaint);

    if (lowSunFactor > 0.16) {
      final bounceRect = Rect.fromLTRB(
        bounds.left,
        bounds.bottom - bounds.height * 0.30,
        bounds.right,
        bounds.bottom + 2,
      );
      final bouncePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            rimCol.withOpacity(effectiveOpacity * lowSunFactor * (0.44 + 0.24 * sunProximity)),
            palette.sunGlowOuter.withOpacity(effectiveOpacity * lowSunFactor * 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(bounceRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
      canvas.drawRect(bounceRect, bouncePaint);
    }

    // Pass 4: Smooth Organic Internal Self-Shadow Pockets (Gaussian-blurred elliptical 3D depth)
    final shadowShiftX = -lightAlignX * 3.0;
    final shadowShiftY = lowSunFactor > 0.55 ? -2.0 : 3.2;
    final pocketPaint = Paint()
      ..color = shadowCol.withOpacity(effectiveOpacity * (0.20 + 0.08 * cloud.layerDepth))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    for (final pocket in cloud.shadowPockets) {
      final rect = Rect.fromCenter(
        center: Offset(pocket.dx + shadowShiftX, pocket.dy + shadowShiftY),
        width: pocket.rx * 1.65,
        height: pocket.ry * 1.45,
      );
      canvas.drawOval(rect, pocketPaint);
    }

    // Pass 5: Creamy Volumetric Sunlit Puff Domes (Pure Gaussian-blurred elliptical billows, zero circular rings)
    final puffShiftX = lightAlignX * 2.8;
    final puffShiftY = lightAlignY * 2.4;
    final puffStrength = (effectiveOpacity * (0.36 - lowSunFactor * 0.12 + sunProximity * 0.10))
        .clamp(0.10, 0.48);
    final puffPaint = Paint()
      ..color = highlightCol.withOpacity(puffStrength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
    for (final puff in cloud.volumePuffs) {
      final rect = Rect.fromCenter(
        center: Offset(puff.dx + puffShiftX, puff.dy + puffShiftY),
        width: puff.rx * 1.55,
        height: puff.ry * 1.45,
      );
      canvas.drawOval(rect, puffPaint);
    }

    // Pass 6: Clipped Sun-Facing Inner Silver-Lining / Subsurface Scattering Rim
    final innerRimAlpha = ((0.38 + 0.34 * sunProximity + 0.20 * lowSunFactor) * effectiveOpacity)
        .clamp(0.0, 0.92);
    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8 + sunProximity * 2.2
      ..shader = LinearGradient(
        begin: litAlignment,
        end: shadowAlignment,
        colors: [
          rimCol.withOpacity(innerRimAlpha),
          highlightCol.withOpacity(innerRimAlpha * 0.38),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.70],
      ).createShader(bounds)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    canvas.drawPath(cloud.outerPath, innerRimPaint);

    canvas.restore(); // End silhouette clip

    // --- PASS 7: Gentle Bottom Condensation Feather (Softens flat base & wing tips into atmosphere) ---
    final featherPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xE8FFFFFF),
          Color(0x98FFFFFF),
        ],
        stops: const [0.0, 0.72, 0.90, 1.0],
      ).createShader(Rect.fromLTRB(bounds.left - 12, bounds.top - 12, bounds.right + 12, bounds.bottom + 4));
    canvas.drawRect(layerBounds, featherPaint);

    canvas.restore(); // End cloud saveLayer
    canvas.restore(); // End cloud transform
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

  /// 8. Rich Layered Islamic Waterfront Architecture: Grand Mosques, Twin Ornate Minarets,
  ///    Cascading Half-Domes, Crescent Finials, Arched Colonnades, Terraced Madrasahs & Swaying Palms
  _CoastalCityGeometry _buildCoastalCityGeometry(double width, double horizonY) {
    final midPath = Path();
    final forePath = Path();
    final crescentTips = <Offset>[];
    final windows = <_BuildingWindowLight>[];

    // Helper: solid stepped building block extending cleanly below horizonY (avoids shoreline gaps)
    void addBlock(Path target, double left, double right, double topY, {bool crenellated = false}) {
      target.addRect(Rect.fromLTRB(left, topY, right, horizonY + 4));
      if (crenellated) {
        const merlonW = 3.2;
        const gapW = 2.6;
        double x = left + 1.5;
        while (x + merlonW <= right - 1.5) {
          target.addRect(Rect.fromLTWH(x, topY - 2.2, merlonW, 2.5));
          x += merlonW + gapW;
        }
      }
    }

    // Helper: graceful Ottoman/Islamic ogee dome with optional drum (tambour), finial spire & crescent tip
    void addDome(
      Path target,
      double cx,
      double baseY, {
      required double radius,
      required double height,
      double drumHeight = 0.0,
      bool addSpire = true,
      bool addCrescent = false,
    }) {
      if (drumHeight > 0) {
        target.addRect(
          Rect.fromLTRB(cx - radius * 0.96, baseY - drumHeight, cx + radius * 0.96, horizonY + 4),
        );
      }
      final springY = baseY - drumHeight;
      final topY = springY - height;
      final dome = Path()
        ..moveTo(cx - radius, springY + 1.0)
        ..lineTo(cx - radius, springY)
        ..cubicTo(
          cx - radius * 1.08, springY - height * 0.56,
          cx - radius * 0.42, topY + height * 0.22,
          cx, topY,
        )
        ..cubicTo(
          cx + radius * 0.42, topY + height * 0.22,
          cx + radius * 1.08, springY - height * 0.56,
          cx + radius, springY,
        )
        ..lineTo(cx + radius, springY + 1.0)
        ..close();
      target.addPath(dome, Offset.zero);

      if (addSpire) {
        final spireH = (height * 0.26).clamp(3.0, 6.8);
        final spire = Path()
          ..moveTo(cx - 1.1, topY + 0.8)
          ..lineTo(cx, topY - spireH)
          ..lineTo(cx + 1.1, topY + 0.8)
          ..close();
        target.addPath(spire, Offset.zero);
        if (addCrescent) {
          crescentTips.add(Offset(cx, topY - spireH - 1.8));
        }
      }
    }

    // Helper: slender multi-tiered Ottoman minaret with 1 or 2 carved balconies (sherefe) & conical spire
    void addMinaret(
      Path target,
      double cx,
      double baseY, {
      required double height,
      required double shaftWidth,
      int balconies = 2,
      bool addCrescent = false,
    }) {
      final topY = baseY - height;
      final hw = shaftWidth * 0.5;
      final coneBaseY = topY + height * 0.24;

      // Grounded square pedestal + slender tapered shaft
      final shaft = Path()
        ..moveTo(cx - hw * 1.25, horizonY + 4)
        ..lineTo(cx - hw * 1.25, baseY - height * 0.14)
        ..lineTo(cx - hw, baseY - height * 0.18)
        ..lineTo(cx - hw * 0.78, coneBaseY)
        ..lineTo(cx, topY)
        ..lineTo(cx + hw * 0.78, coneBaseY)
        ..lineTo(cx + hw, baseY - height * 0.18)
        ..lineTo(cx + hw * 1.25, baseY - height * 0.14)
        ..lineTo(cx + hw * 1.25, horizonY + 4)
        ..close();
      target.addPath(shaft, Offset.zero);

      // Ornate projecting balconies (sherefe) with corbel taper
      final balconyFracs = balconies >= 2 ? const [0.46, 0.72] : const [0.68];
      for (final frac in balconyFracs) {
        final by = baseY - height * frac;
        final bHalf = hw + 2.5;
        final balcony = Path()
          ..moveTo(cx - hw * 0.85, by + 2.6)
          ..lineTo(cx - bHalf, by)
          ..lineTo(cx - bHalf, by - 2.6)
          ..lineTo(cx + bHalf, by - 2.6)
          ..lineTo(cx + bHalf, by)
          ..lineTo(cx + hw * 0.85, by + 2.6)
          ..close();
        target.addPath(balcony, Offset.zero);
      }

      // Finial needle & optional crescent
      final finialH = (height * 0.08).clamp(3.2, 6.0);
      final finial = Path()
        ..moveTo(cx - 0.8, topY + 1.0)
        ..lineTo(cx, topY - finialH)
        ..lineTo(cx + 0.8, topY + 1.0)
        ..close();
      target.addPath(finial, Offset.zero);
      if (addCrescent) {
        crescentTips.add(Offset(cx, topY - finialH - 1.6));
      }
    }

    // Helper: square Andalusian / Maghrebi tower minaret with crowned lantern pavilion
    void addSquareTower(Path target, double cx, double baseY, {required double height, required double w}) {
      final hw = w * 0.5;
      final topY = baseY - height;
      addBlock(target, cx - hw, cx + hw, topY, crenellated: true);
      // Small lantern turret & cupola atop square tower
      addBlock(target, cx - hw * 0.58, cx + hw * 0.58, topY - 5.5);
      addDome(target, cx, topY - 5.5, radius: hw * 0.62, height: 5.5, addSpire: true);
    }

    // =========================================================================
    // LAYER 1: MID-GROUND ATMOSPHERIC CITYSCAPE (Behind main waterfront mosques)
    // =========================================================================

    // --- Left Mid-Ground Hillside Quarter ---
    addBlock(midPath, -20, width * 0.16, horizonY - 22, crenellated: true);
    addBlock(midPath, width * 0.14, width * 0.26, horizonY - 15);
    addBlock(midPath, width * 0.24, width * 0.34, horizonY - 9, crenellated: true);
    addMinaret(midPath, width * 0.022, horizonY - 18, height: 58, shaftWidth: 6.4, balconies: 1);
    addDome(midPath, width * 0.095, horizonY - 22, radius: 13.5, height: 17.0, drumHeight: 4.0);
    addDome(midPath, width * 0.225, horizonY - 15, radius: 10.5, height: 12.5, drumHeight: 3.0);
    addSquareTower(midPath, width * 0.286, horizonY - 9, height: 28, w: 9.0);
    addDome(midPath, width * 0.326, horizonY - 9, radius: 7.5, height: 9.0);

    // --- Right Mid-Ground Hillside Quarter ---
    addBlock(midPath, width * 0.84, width + 20, horizonY - 23, crenellated: true);
    addBlock(midPath, width * 0.73, width * 0.86, horizonY - 16);
    addBlock(midPath, width * 0.65, width * 0.75, horizonY - 10, crenellated: true);
    addMinaret(midPath, width * 0.976, horizonY - 19, height: 60, shaftWidth: 6.6, balconies: 1);
    addDome(midPath, width * 0.902, horizonY - 23, radius: 13.5, height: 17.5, drumHeight: 4.5);
    addDome(midPath, width * 0.818, horizonY - 16, radius: 11.0, height: 14.0, drumHeight: 3.5);
    addMinaret(midPath, width * 0.752, horizonY - 13, height: 48, shaftWidth: 5.8, balconies: 1);
    addDome(midPath, width * 0.692, horizonY - 10, radius: 8.5, height: 10.5, drumHeight: 2.5);

    // Warm hillside mid-ground townhouse windows
    for (final pt in [
      (0.042, 16.0, 0.4),
      (0.105, 19.0, 1.3),
      (0.242, 11.0, 2.2),
      (0.286, 26.0, 3.1),
      (0.708, 12.0, 1.7),
      (0.772, 13.0, 2.8),
      (0.902, 20.0, 0.9),
      (0.955, 17.0, 3.6),
    ]) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * pt.$1, horizonY - pt.$2),
        width: 2.0,
        height: 3.4,
        isMidground: true,
        twinklePhase: pt.$3,
        intensity: 0.72,
      ));
    }

    // =========================================================================
    // LAYER 2: FOREGROUND GRAND WATERFRONT MOSQUES, PAVILIONS & COLONNADES
    // =========================================================================

    // --- LEFT WATERFRONT: Grand Masjid, Twin Minarets, Arched Madrasah & Lakeside Pavilion ---
    // Waterfront seawall & stepped mosque prayer hall base
    addBlock(forePath, -20, width * 0.195, horizonY - 15, crenellated: true);
    addBlock(forePath, width * 0.190, width * 0.305, horizonY - 10, crenellated: true);
    addBlock(forePath, width * 0.300, width * 0.358, horizonY - 6);
    // Low stone harbor jetty tapering gently into the bay
    forePath
      ..moveTo(width * 0.352, horizonY + 4)
      ..lineTo(width * 0.352, horizonY - 4.5)
      ..lineTo(width * 0.382, horizonY - 1.0)
      ..lineTo(width * 0.392, horizonY + 4)
      ..close();

    // Tall Twin Minarets framing Left Grand Masjid
    addMinaret(forePath, width * 0.058, horizonY - 12, height: 82, shaftWidth: 8.8, balconies: 2, addCrescent: true);
    addMinaret(forePath, width * 0.196, horizonY - 10, height: 61, shaftWidth: 7.0, balconies: 2);

    // Grand Main Dome with elevated drum + cascading flanking half-domes
    addDome(forePath, width * 0.094, horizonY - 15, radius: 11.5, height: 13.5, drumHeight: 3.0);
    addDome(forePath, width * 0.162, horizonY - 15, radius: 11.5, height: 13.5, drumHeight: 3.0);
    addDome(forePath, width * 0.128, horizonY - 16, radius: 18.5, height: 24.0, drumHeight: 5.5, addCrescent: true);

    // Rhythmic Waterfront Colonnade Cupolas & Lakeside Kiosk Pavilion
    addDome(forePath, width * 0.228, horizonY - 10, radius: 6.8, height: 8.8);
    addDome(forePath, width * 0.256, horizonY - 10, radius: 6.8, height: 8.8);
    addDome(forePath, width * 0.284, horizonY - 10, radius: 6.8, height: 8.8);
    addDome(forePath, width * 0.324, horizonY - 6, radius: 10.5, height: 13.0, drumHeight: 2.5);
    // Slender waterfront lantern turret cleanly perched on left harbor jetty point
    addMinaret(forePath, width * 0.368, horizonY - 2.5, height: 21, shaftWidth: 4.2, balconies: 1);
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.368, horizonY - 16.5),
      width: 1.9,
      height: 2.8,
      castsWaterReflection: true,
      twinklePhase: 3.4,
      intensity: 0.90,
    ));

    // Left Masjid Glowing Arched Windows, Tambour Archlets & Minaret Lantern Galleries
    // Tambour drum archlet row under main dome
    for (int k = 0; k < 4; k++) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * (0.111 + k * 0.0115), horizonY - 19.0),
        width: 1.9,
        height: 3.2,
        twinklePhase: k * 0.7,
        intensity: 0.90,
      ));
    }
    // Lower grand prayer hall arched windows (cast warm golden reflections on water!)
    for (int k = 0; k < 3; k++) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * (0.104 + k * 0.024), horizonY - 7.5),
        width: 3.2,
        height: 6.2,
        castsWaterReflection: k == 1 || k == 0,
        twinklePhase: 0.5 + k * 0.9,
      ));
    }
    // Left waterfront colonnade arcade arches
    for (int k = 0; k < 3; k++) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * (0.228 + k * 0.028), horizonY - 5.2),
        width: 2.8,
        height: 4.8,
        castsWaterReflection: k == 1,
        twinklePhase: 1.6 + k * 0.8,
        intensity: 0.86,
      ));
    }
    // Left lakeside pavilion arch & harbor lantern
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.324, horizonY - 3.8),
      width: 3.2,
      height: 5.0,
      castsWaterReflection: true,
      twinklePhase: 2.3,
    ));
    // Left minaret balcony lantern galleries
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.058, horizonY - 51.0),
      width: 3.2,
      height: 4.2,
      castsWaterReflection: true,
      twinklePhase: 0.8,
      intensity: 0.95,
    ));
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.058, horizonY - 72.0),
      width: 2.6,
      height: 3.6,
      twinklePhase: 1.9,
      intensity: 0.90,
    ));
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.196, horizonY - 54.0),
      width: 2.4,
      height: 3.5,
      twinklePhase: 2.7,
      intensity: 0.88,
    ));

    // --- RIGHT WATERFRONT: Imperial Coastal Mosque, Cascading Domes & Multi-Dome Madrasah ---
    addBlock(forePath, width * 0.802, width + 20, horizonY - 16, crenellated: true);
    addBlock(forePath, width * 0.695, width * 0.808, horizonY - 11, crenellated: true);
    addBlock(forePath, width * 0.642, width * 0.700, horizonY - 6);
    // Low stone harbor jetty tapering cleanly into the bay
    forePath
      ..moveTo(width * 0.648, horizonY + 4)
      ..lineTo(width * 0.648, horizonY - 4.5)
      ..lineTo(width * 0.618, horizonY - 1.0)
      ..lineTo(width * 0.608, horizonY + 4)
      ..close();

    // Tall Imperial Minaret & Slender Companion Minaret
    addMinaret(forePath, width * 0.938, horizonY - 12, height: 86, shaftWidth: 9.2, balconies: 2, addCrescent: true);
    addMinaret(forePath, width * 0.802, horizonY - 11, height: 66, shaftWidth: 7.4, balconies: 2, addCrescent: true);

    // Grand Imperial Dome + elevated tambour + flanking half-domes
    addDome(forePath, width * 0.903, horizonY - 16, radius: 12.0, height: 14.0, drumHeight: 3.0);
    addDome(forePath, width * 0.835, horizonY - 16, radius: 12.0, height: 14.0, drumHeight: 3.0);
    addDome(forePath, width * 0.869, horizonY - 17, radius: 19.5, height: 25.5, drumHeight: 6.0, addCrescent: true);

    // Multi-Dome Lakeside Madrasah & Waterfront Portico
    addDome(forePath, width * 0.758, horizonY - 11, radius: 12.0, height: 15.0, drumHeight: 2.5);
    addDome(forePath, width * 0.718, horizonY - 11, radius: 9.5, height: 11.8, drumHeight: 2.0);
    addDome(forePath, width * 0.684, horizonY - 6, radius: 6.5, height: 8.5);
    addDome(forePath, width * 0.662, horizonY - 6, radius: 5.5, height: 7.2);
    // Waterfront harbor lighthouse minaret cleanly perched on right jetty point
    addMinaret(forePath, width * 0.632, horizonY - 2.5, height: 22, shaftWidth: 4.4, balconies: 1);
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.632, horizonY - 17.5),
      width: 2.0,
      height: 2.8,
      castsWaterReflection: true,
      twinklePhase: 2.9,
      intensity: 0.90,
    ));

    // Right Masjid Glowing Arched Windows, Tambour Archlets & Minaret Lantern Galleries
    for (int k = 0; k < 4; k++) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * (0.851 + k * 0.012), horizonY - 20.0),
        width: 2.0,
        height: 3.3,
        twinklePhase: 0.4 + k * 0.8,
        intensity: 0.92,
      ));
    }
    for (int k = 0; k < 3; k++) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * (0.844 + k * 0.025), horizonY - 8.0),
        width: 3.4,
        height: 6.4,
        castsWaterReflection: k == 1 || k == 2,
        twinklePhase: 1.1 + k * 0.9,
      ));
    }
    // Right lakeside madrasah arched windows
    for (final xFrac in const [0.758, 0.718, 0.674]) {
      windows.add(_BuildingWindowLight(
        pos: Offset(width * xFrac, horizonY - 5.2),
        width: 3.0,
        height: 5.2,
        castsWaterReflection: xFrac != 0.718,
        twinklePhase: xFrac * 7.0,
        intensity: 0.88,
      ));
    }
    // Right minaret balcony lantern galleries
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.938, horizonY - 52.0),
      width: 3.3,
      height: 4.4,
      castsWaterReflection: true,
      twinklePhase: 1.4,
      intensity: 0.96,
    ));
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.938, horizonY - 75.0),
      width: 2.8,
      height: 3.8,
      twinklePhase: 2.5,
      intensity: 0.92,
    ));
    windows.add(_BuildingWindowLight(
      pos: Offset(width * 0.802, horizonY - 59.0),
      width: 2.5,
      height: 3.6,
      castsWaterReflection: true,
      twinklePhase: 0.6,
      intensity: 0.90,
    ));

    // =========================================================================
    // LAYER 3: LUSH SWAYING COASTAL PALM TREES (Tucked naturally among pavilions)
    // =========================================================================
    final palms = [
      _PalmTreeSpec(base: Offset(width * 0.214, horizonY - 7), height: 32, swaySign: 1.0, swayMult: 1.0, leanDir: 1.0),
      _PalmTreeSpec(base: Offset(width * 0.270, horizonY - 5), height: 25, swaySign: 1.0, swayMult: 1.25, leanDir: 0.7),
      _PalmTreeSpec(base: Offset(width * 0.342, horizonY - 4), height: 19, swaySign: 1.0, swayMult: 1.35, leanDir: 0.85),
      _PalmTreeSpec(base: Offset(width * 0.784, horizonY - 7), height: 33, swaySign: -1.0, swayMult: 1.0, leanDir: -1.0),
      _PalmTreeSpec(base: Offset(width * 0.732, horizonY - 5), height: 25, swaySign: -1.0, swayMult: 1.25, leanDir: -0.75),
      _PalmTreeSpec(base: Offset(width * 0.656, horizonY - 4), height: 19, swaySign: -1.0, swayMult: 1.35, leanDir: -0.85),
    ];

    return _CoastalCityGeometry(
      midSkylinePath: midPath,
      foreSkylinePath: forePath,
      crescentTips: crescentTips,
      palms: palms,
      windows: windows,
    );
  }

  void _drawCoastalMosquesAndPalms(
    Canvas canvas,
    Size size,
    double horizonY,
    _CoastalCityGeometry city,
  ) {
    final palette = skyState.palette;

    // 1. Mid-ground atmospheric skyline layer (softer/lighter tone for realistic architectural depth)
    final midBuildingColor = Color.lerp(
      palette.foreMountainColor,
      palette.mosqueSilhouetteColor,
      0.38,
    )!;
    canvas.drawPath(city.midSkylinePath, Paint()..color = midBuildingColor);

    // 2. Foreground waterfront grand mosques, twin minarets, domes & colonnades
    final forePaint = Paint()..color = palette.mosqueSilhouetteColor;
    canvas.drawPath(city.foreSkylinePath, forePaint);

    // 3. Delicate Islamic crescent finials (hilal) atop grand domes & primary minarets
    final hilalColor = Color.lerp(
      palette.mosqueSilhouetteColor,
      palette.sunGlowMid,
      palette.isMoon ? 0.28 : 0.22,
    )!;
    for (final tip in city.crescentTips) {
      _drawCrescentFinial(canvas, tip, 2.3, hilalColor);
    }

    // 4. Lush Swaying Coastal Palm Trees
    final palmSway = math.sin(elapsedSeconds * 1.8) * 0.045;
    for (final palm in city.palms) {
      _drawSwayingPalmTree(
        canvas,
        palm.base,
        height: palm.height,
        swayFactor: palmSway * palm.swaySign * palm.swayMult,
        leanDir: palm.leanDir,
        color: palette.mosqueSilhouetteColor,
      );
    }

    // 5. Warm Glowing Arched Mosque Windows, Tambour Archlets & Minaret Lantern Galleries
    if (palette.windowGlowOpacity > 0.05) {
      _drawScenicGlowingWindows(canvas, city.windows, palette.windowGlowOpacity);
    }
  }

  /// Draws a crisp filled miniature Islamic crescent finial (hilal) opening gracefully upward
  void _drawCrescentFinial(Canvas canvas, Offset center, double radius, Color color) {
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final inner = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx + radius * 0.22, center.dy - radius * 0.42),
          radius: radius * 0.84,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      crescent,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  void _drawSwayingPalmTree(
    Canvas canvas,
    Offset base, {
    required double height,
    required double swayFactor,
    double leanDir = 1.0,
    required Color color,
  }) {
    final top = Offset(base.dx + (height * (0.16 * leanDir + swayFactor)), base.dy - height);
    final control = Offset(base.dx + (height * (0.09 * leanDir + swayFactor * 0.5)), base.dy - height * 0.5);

    // Tapered organic palm trunk (slightly thicker at coastal base)
    final trunk = Path()
      ..moveTo(base.dx - 1.35, base.dy)
      ..quadraticBezierTo(control.dx - 0.8, control.dy, top.dx - 0.45, top.dy)
      ..lineTo(top.dx + 0.45, top.dy)
      ..quadraticBezierTo(control.dx + 0.8, control.dy, base.dx + 1.35, base.dy)
      ..close();
    canvas.drawPath(trunk, Paint()..color = color);

    final frondPaint = Paint()
      ..color = color
      ..strokeWidth = (1.35 + (height / 36.0) * 0.45)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 7 gracefully arching drooping palm fronds
    const frondCount = 7;
    for (int i = 0; i < frondCount; i++) {
      final angle = (i * (math.pi * 2 / frondCount)) - 0.55 + (swayFactor * 0.9);
      final frondLen = height * (0.42 + (i % 2 == 0 ? 0.08 : 0.0));
      final frondEnd = Offset(
        top.dx + frondLen * math.cos(angle),
        top.dy + (frondLen * 0.72) * math.sin(angle) + 4.5,
      );
      final frondPath = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + (frondLen * 0.56) * math.cos(angle),
          top.dy + (frondLen * 0.34) * math.sin(angle) - 3.6,
          frondEnd.dx,
          frondEnd.dy,
        );
      canvas.drawPath(frondPath, frondPaint);
    }
  }

  /// Draws warm glowing pointed-arch mosque windows, tambour archlets & minaret lantern galleries
  void _drawScenicGlowingWindows(
    Canvas canvas,
    List<_BuildingWindowLight> windows,
    double maxGlowOpacity,
  ) {
    for (final win in windows) {
      final pulse = 0.80 + 0.20 * math.sin(elapsedSeconds * 2.1 + win.twinklePhase);
      final alpha = (0.92 * pulse * maxGlowOpacity * win.intensity).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;

      final cx = win.pos.dx;
      final cy = win.pos.dy;
      final hw = win.width * 0.5;
      final hh = win.height * 0.5;

      // Soft warm amber halo around each lit window
      canvas.drawOval(
        Rect.fromCenter(center: win.pos, width: win.width * 2.5, height: win.height * 1.9),
        Paint()
          ..color = const Color(0xFFFFB74D).withOpacity(alpha * (win.isMidground ? 0.28 : 0.42))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
      );

      // Crisp pointed Islamic arch window core
      final arch = Path()
        ..moveTo(cx - hw, cy + hh)
        ..lineTo(cx - hw, cy - hh * 0.15)
        ..quadraticBezierTo(cx - hw * 0.85, cy - hh * 0.85, cx, cy - hh)
        ..quadraticBezierTo(cx + hw * 0.85, cy - hh * 0.85, cx + hw, cy - hh * 0.15)
        ..lineTo(cx + hw, cy + hh)
        ..close();

      final coreColor = win.isMidground ? const Color(0xFFFFCA66) : const Color(0xFFFFE082);
      canvas.drawPath(arch, Paint()..color = coreColor.withOpacity(alpha));
    }
  }

  /// 9. Photorealistic Reflecting Water: Fresnel Sky Mirror, Wave-Rippled Coastal Silhouettes & Physical Sun/Moon Glitter Path
  void _drawLivingWaterAndReflection(
    Canvas canvas,
    Size size,
    double horizonY,
    Offset orbPos,
    _CoastalCityGeometry coastalCity,
  ) {
    final width = size.width;
    final height = size.height;
    final waterHeight = (height - horizonY).clamp(1.0, height);
    final palette = skyState.palette;
    final waterRect = Rect.fromLTWH(0, horizonY, width, waterHeight);

    canvas.save();
    canvas.clipRect(waterRect);

    // 1. Physical Fresnel Sky-Mirror Water Base
    // Grazing angles near the horizon reflect the bright horizon sky strongly;
    // steeper foreground angles reveal deeper ocean color tinted by upper sky.
    final skyHorizon = palette.skyGradientColors.last;
    final skyLower = palette.skyGradientColors[palette.skyGradientColors.length - 2];
    final skyMid = palette.skyGradientColors[2];

    final mirrorHorizon = Color.lerp(palette.waterColors[0], skyHorizon, palette.isMoon ? 0.34 : 0.56)!;
    final mirrorUpper = Color.lerp(palette.waterColors[0], skyLower, palette.isMoon ? 0.26 : 0.42)!;
    final mirrorMid = Color.lerp(palette.waterColors[1], skyMid, 0.22)!;

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mirrorHorizon,
          mirrorUpper,
          mirrorMid,
          palette.waterColors[2],
          palette.waterColors[3],
        ],
        stops: const [0.0, 0.14, 0.40, 0.74, 1.0],
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    // Reflected broad sky-dome solar/lunar glow wash across the bay
    // During Fajr pre-dawn, the warm sky glow reflects from the eastern (left) horizon while the pale Moon sets west
    final sunX = orbPos.dx;
    final horizonGlowX = skyState.phase == SkyPhase.fajrDawn ? width * 0.18 : sunX;
    final skyMirrorGlowRect = Rect.fromCenter(
      center: Offset(horizonGlowX, horizonY + waterHeight * 0.06),
      width: width * 0.95,
      height: waterHeight * 1.15,
    );
    final skyMirrorGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.78),
        radius: 0.88,
        colors: [
          Color.lerp(skyHorizon, palette.waterReflectionGlow, 0.45)!
              .withOpacity(palette.isMoon ? 0.32 : 0.52),
          palette.waterReflectionGlow.withOpacity(palette.isMoon ? 0.14 : 0.24),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(skyMirrorGlowRect);
    canvas.drawRect(waterRect, skyMirrorGlowPaint);

    // 2. Real Wave-Rippled Inverted Reflections of Mountains, Mosques, Minarets, Palms & Lantern Windows
    _drawCoastalWaterReflections(canvas, size, horizonY, waterHeight, coastalCity);

    // 3. Subtle Perspective Water Swells & Dark Wave Troughs across the full surface
    _drawAmbientWaterSwells(canvas, size, horizonY, waterHeight, horizonGlowX);

    // 4. Physical Sun / Moon Mirror Silhouette & Cox-Munk Liquid Glitter Path ("Jalan Cahaya")
    _drawSunMoonWaterReflection(canvas, size, horizonY, waterHeight, orbPos);

    // 5. Smooth Feathered Shoreline Contact Shadow (zero abrupt notch edges) + Atmospheric Valley Pass Mist
    final leftShoreRect = Rect.fromLTWH(0, horizonY, width * 0.49, 7.0);
    canvas.drawRect(
      leftShoreRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.mosqueSilhouetteColor.withOpacity(0.42),
            Colors.transparent,
          ],
        ).createShader(leftShoreRect),
    );
    final rightShoreRect = Rect.fromLTWH(width * 0.51, horizonY, width * 0.49, 7.0);
    canvas.drawRect(
      rightShoreRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.mosqueSilhouetteColor.withOpacity(0.42),
            Colors.transparent,
          ],
        ).createShader(rightShoreRect),
    );

    // Smooth atmospheric horizon mist bridging open water & glowing valley pass seamlessly
    final passMistRect = Rect.fromCenter(
      center: Offset(horizonGlowX, horizonY + 1.5),
      width: width * 0.44,
      height: 15.0,
    );
    canvas.drawOval(
      passMistRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(palette.waterMistColor, Colors.white, 0.28)!
                .withOpacity(palette.isMoon ? 0.24 : 0.48),
            palette.waterMistColor.withOpacity(palette.isMoon ? 0.08 : 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(passMistRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    canvas.restore();
  }

  /// Renders inverted, perspective-rippled reflections of mountains, ridge facets,
  /// layered Islamic waterfront mosques, twin minarets, domes, swaying palms & glowing lantern windows.
  void _drawCoastalWaterReflections(
    Canvas canvas,
    Size size,
    double horizonY,
    double waterHeight,
    _CoastalCityGeometry coastalCity,
  ) {
    final width = size.width;
    final palette = skyState.palette;
    final maxReflectionDepth = math.min(waterHeight * 0.82, 94.0);
    if (maxReflectionDepth <= 4.0) return;

    // Extend outer coastal edges by ±20px beyond viewport so horizontal wave ripple shifts never expose screen-edge gaps
    final midMountains = Path()
      ..moveTo(-20, horizonY)
      ..lineTo(-20, horizonY - 60)
      ..lineTo(0, horizonY - 60)
      ..lineTo(width * 0.14, horizonY - 50)
      ..lineTo(width * 0.24, horizonY - 72)
      ..lineTo(width * 0.36, horizonY - 34)
      ..lineTo(width * 0.46, horizonY - 6)
      ..lineTo(width * 0.50, horizonY)
      ..close()
      ..moveTo(width + 20, horizonY)
      ..lineTo(width + 20, horizonY - 60)
      ..lineTo(width, horizonY - 60)
      ..lineTo(width * 0.86, horizonY - 50)
      ..lineTo(width * 0.76, horizonY - 72)
      ..lineTo(width * 0.64, horizonY - 34)
      ..lineTo(width * 0.54, horizonY - 6)
      ..lineTo(width * 0.50, horizonY)
      ..close();

    final litFacets = Path()
      ..moveTo(width * 0.24, horizonY - 72)
      ..lineTo(width * 0.36, horizonY - 34)
      ..lineTo(width * 0.30, horizonY - 26)
      ..close()
      ..moveTo(width * 0.76, horizonY - 72)
      ..lineTo(width * 0.64, horizonY - 34)
      ..lineTo(width * 0.70, horizonY - 26)
      ..close();

    final foreSlopes = Path()
      ..moveTo(-20, horizonY + 2)
      ..lineTo(-20, horizonY - 30)
      ..lineTo(0, horizonY - 30)
      ..lineTo(width * 0.18, horizonY - 20)
      ..lineTo(width * 0.35, horizonY - 6)
      ..lineTo(width * 0.44, horizonY + 2)
      ..close()
      ..moveTo(width + 20, horizonY + 2)
      ..lineTo(width + 20, horizonY - 30)
      ..lineTo(width, horizonY - 30)
      ..lineTo(width * 0.82, horizonY - 20)
      ..lineTo(width * 0.65, horizonY - 6)
      ..lineTo(width * 0.56, horizonY + 2)
      ..close();

    // Water absorbs ~25-35% of reflected light, deepening & tinting reflected silhouettes toward water tone
    final waterDeep = palette.waterColors[2];
    final reflMidCol = Color.lerp(palette.midMountainColor, waterDeep, 0.36)!;
    final reflFacetCol = Color.lerp(palette.mountainFacetHighlight, waterDeep, 0.42)!;
    final reflForeCol = Color.lerp(palette.foreMountainColor, waterDeep, 0.26)!;
    final reflMidCityCol = Color.lerp(
      Color.lerp(palette.foreMountainColor, palette.mosqueSilhouetteColor, 0.38)!,
      waterDeep,
      0.24,
    )!;
    final reflMosqueCol = Color.lerp(palette.mosqueSilhouetteColor, waterDeep, 0.20)!;
    final palmSway = math.sin(elapsedSeconds * 1.8) * 0.045;

    // 34 fine perspective wave-sliced strips for silky-liquid ripple distortion
    const stripCount = 34;
    for (int s = 0; s < stripCount; s++) {
      final t0 = s / stripCount;
      final t1 = (s + 1) / stripCount;
      final y0 = horizonY + math.pow(t0, 1.32).toDouble() * maxReflectionDepth;
      final y1 = horizonY + math.pow(t1, 1.32).toDouble() * maxReflectionDepth;
      final yMidNorm = ((t0 + t1) * 0.5).clamp(0.0, 1.0);

      final waveDispX =
          math.sin(yMidNorm * 22.0 - elapsedSeconds * 1.85) * (0.45 + yMidNorm * 3.8) +
          math.sin(yMidNorm * 46.0 + elapsedSeconds * 2.65) * (0.20 + yMidNorm * 1.6);

      final rippleMod = 0.86 + 0.14 * math.cos(yMidNorm * 32.0 - elapsedSeconds * 2.2);
      final fade = (math.pow(1.0 - yMidNorm, 1.28).toDouble() * 0.64 * rippleMod).clamp(0.0, 1.0);
      if (fade <= 0.02) continue;

      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, y0, width, y1 + 0.45));
      canvas.translate(waveDispX, horizonY);
      canvas.scale(1.0, -0.84);
      canvas.translate(0, -horizonY);

      canvas.drawPath(midMountains, Paint()..color = reflMidCol.withOpacity(fade * 0.88));
      canvas.drawPath(litFacets, Paint()..color = reflFacetCol.withOpacity(fade * 0.52));
      canvas.drawPath(foreSlopes, Paint()..color = reflForeCol.withOpacity(fade * 0.94));
      canvas.drawPath(coastalCity.midSkylinePath, Paint()..color = reflMidCityCol.withOpacity(fade * 0.90));
      canvas.drawPath(coastalCity.foreSkylinePath, Paint()..color = reflMosqueCol.withOpacity(fade));

      final palmReflCol = reflMosqueCol.withOpacity(fade * 0.92);
      for (final palm in coastalCity.palms) {
        _drawSwayingPalmTree(
          canvas,
          palm.base,
          height: palm.height,
          swayFactor: palmSway * palm.swaySign * palm.swayMult,
          leanDir: palm.leanDir,
          color: palmReflCol,
        );
      }

      canvas.restore();
    }

    // Shimmering vertical water reflections of glowing waterfront mosque windows & minaret lanterns
    if (palette.windowGlowOpacity > 0.06) {
      int wIdx = 0;
      for (final win in coastalCity.windows) {
        if (!win.castsWaterReflection) continue;
        wIdx++;
        final pulse = 0.80 + 0.20 * math.sin(elapsedSeconds * 2.1 + win.twinklePhase);
        final baseWinAlpha = (palette.windowGlowOpacity * pulse * win.intensity * 0.78).clamp(0.0, 0.90);

        final wx = win.pos.dx;
        final elevAboveShore = (horizonY - win.pos.dy).clamp(2.0, 80.0);
        final wyStart = horizonY + elevAboveShore * 0.42;

        for (int g = 0; g < 8; g++) {
          final gt = g / 7.0;
          final gy = wyStart + gt * (18.0 + elevAboveShore * 0.22);
          if (gy > horizonY + waterHeight) break;
          final sway = math.sin(elapsedSeconds * 2.4 + g * 1.25 + wIdx * 1.7) * (0.9 + gt * 2.5);
          final shimmer = 0.52 + 0.48 * math.sin(elapsedSeconds * 3.2 + g * 1.9 + win.twinklePhase);
          final gw = (win.width * 1.1 + gt * 4.4) * (0.72 + 0.28 * shimmer);
          final gh = 1.1 + gt * 0.95;
          final gAlpha = (baseWinAlpha * (1.0 - gt * 0.78) * shimmer).clamp(0.0, 1.0);

          final rect = Rect.fromCenter(center: Offset(wx + sway, gy), width: gw, height: gh);
          canvas.drawOval(
            rect,
            Paint()
              ..color = const Color(0xFFFFD54F).withOpacity(gAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3),
          );
        }
      }
    }
  }

  /// Helper: builds an organic, gently undulating tapered liquid wave-facet lens path
  /// (pointed feathery ends & subtle wave curvature — never stiff rectangular bricks)
  Path _buildLiquidFacetPath(double cx, double cy, double width, double thickness, double curveDy) {
    final hw = width * 0.5;
    final ht = thickness * 0.5;
    return Path()
      ..moveTo(cx - hw, cy + curveDy * 0.35)
      ..quadraticBezierTo(cx, cy - ht - curveDy, cx + hw, cy - curveDy * 0.35)
      ..quadraticBezierTo(cx, cy + ht - curveDy * 0.25, cx - hw, cy + curveDy * 0.35)
      ..close();
  }

  /// Subtle broken perspective liquid swells & troughs across the whole water body
  void _drawAmbientWaterSwells(
    Canvas canvas,
    Size size,
    double horizonY,
    double waterHeight,
    double sunX,
  ) {
    final width = size.width;
    final palette = skyState.palette;
    final skyHighlight = Color.lerp(palette.skyGradientColors[4], palette.rippleSecondary, 0.30)!;
    final troughColor = Color.lerp(palette.waterColors[3], Colors.black, 0.44)!;

    for (int i = 0; i < waveBands.length; i++) {
      final band = waveBands[i];
      final yNorm = band.yRel;
      final y = horizonY + yNorm * waterHeight;
      final persp = 0.20 + yNorm * 0.80;

      for (int p = 0; p < 3; p++) {
        final anchor = (band.secondaryFrequency + p * 0.337 + math.sin(band.phase + p) * 0.08) % 1.0;
        final drift = math.sin(elapsedSeconds * (0.45 + band.speed * 0.28) + band.secondaryPhase + p * 2.1) *
            (4.0 + yNorm * 12.0);
        final cx = anchor * width + drift;

        final segWidth = (22.0 + band.amplitude * 46.0) * (0.35 + yNorm * 1.35);
        final segHeight = (0.8 + yNorm * 2.2) * (0.85 + 0.3 * band.frequency);

        // Soft dark liquid trough underneath
        final troughAlpha = ((0.14 + yNorm * 0.22) * (0.7 + 0.3 * band.amplitude)).clamp(0.0, 0.36);
        final troughRect = Rect.fromCenter(
          center: Offset(cx, y + segHeight * 0.65),
          width: segWidth * 1.15,
          height: segHeight * 1.1,
        );
        canvas.drawOval(
          troughRect,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                troughColor.withOpacity(troughAlpha),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(troughRect),
        );

        // Subtle grazing-skylight catch on top of wave slope
        final distFromSunNorm = ((cx - sunX).abs() / (width * 0.55)).clamp(0.0, 1.0);
        final sheenAlpha = ((0.05 + 0.13 * (1.0 - distFromSunNorm)) * persp *
                (0.6 + 0.4 * math.sin(elapsedSeconds * band.speed + band.phase + p)))
            .clamp(0.0, 0.20);
        if (sheenAlpha > 0.015) {
          final sheenRect = Rect.fromCenter(
            center: Offset(cx, y),
            width: segWidth * 0.90,
            height: segHeight * 0.72,
          );
          canvas.drawOval(
            sheenRect,
            Paint()
              ..shader = LinearGradient(
                colors: [
                  Colors.transparent,
                  skyHighlight.withOpacity(sheenAlpha),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(sheenRect),
          );
        }
      }
    }
  }

  /// Exact piecewise height of the mid-range mountain silhouette above horizonY at normalized xFrac (0..1)
  double _mountainRidgeHeightAt(double xFrac) {
    final d = (xFrac - 0.50).abs().clamp(0.0, 0.50);
    if (d <= 0.04) return (d / 0.04) * 6.0;
    if (d <= 0.14) return 6.0 + ((d - 0.04) / 0.10) * 28.0;
    if (d <= 0.26) return 34.0 + ((d - 0.14) / 0.12) * 38.0;
    if (d <= 0.36) return 72.0 - ((d - 0.26) / 0.10) * 22.0;
    return 50.0 + ((d - 0.36) / 0.14) * 10.0;
  }

  /// Real physical reflection of the Sun / Moon:
  /// - Rippled mirror silhouette of the celestial disc itself (attenuated naturally behind mountain ridges)
  /// - Organic sinuous Cox-Munk liquid-light wave facets tapering & shimmering in perspective
  /// - Delicate pinpoint specular light glints on peak wave crests
  void _drawSunMoonWaterReflection(
    Canvas canvas,
    Size size,
    double horizonY,
    double waterHeight,
    Offset orbPos,
  ) {
    final width = size.width;
    final palette = skyState.palette;
    final sunX = orbPos.dx;
    final isMoon = !skyState.isDaytime;
    final isFajrMoon = isMoon && skyState.phase == SkyPhase.fajrDawn;

    // Match celestial body opacity (smooth lunar fade-in after Maghrib & gentle fade-out during Fajr dawn)
    double celestialAlpha = 1.0;
    if (isMoon) {
      if (skyState.moonProgress < 0.04) {
        celestialAlpha = (skyState.moonProgress / 0.04).clamp(0.0, 1.0);
      } else if (isFajrMoon) {
        celestialAlpha = (1.0 - skyState.phaseProgress * 0.72).clamp(0.18, 1.0);
      }
    }
    if (celestialAlpha <= 0.02) return;

    // Optical elevation state of sun/moon relative to horizon & coastal mountain ridge
    final orbRadius = isMoon ? 19.0 : 25.0;
    final orbAboveHorizon = horizonY - orbPos.dy;
    final ridgeHeight = _mountainRidgeHeightAt(sunX / width);
    final orbAboveRidge = orbAboveHorizon - ridgeHeight;
    final orbVisibility = ((orbAboveHorizon + 22.0) / 36.0).clamp(0.0, 1.0);
    // Direct mirror disc dims smoothly as the orb dips behind the mountain ridge
    final discVisibility =
        (((orbAboveRidge + orbRadius * 0.72) / (orbRadius * 1.48)).clamp(0.0, 1.0) * orbVisibility * celestialAlpha)
            .clamp(0.0, 1.0);
    final lowOrbFactor = (1.0 - (orbAboveHorizon / (horizonY * 0.72)).clamp(0.0, 1.0)).clamp(0.0, 1.0);

    // During Fajr dawn the pale fading Moon casts quiet pearl-silver light rather than warm eastern dawn orange
    final discCoreColor = isFajrMoon ? const Color(0xFFF0F6FF) : const Color(0xFFFFFFFF);
    final discMidColor = isFajrMoon
        ? const Color(0xFFC4D7F0)
        : Color.lerp(palette.sunDiscColors[1], palette.ripplePrimary, 0.48)!;
    final discWarmColor = isFajrMoon
        ? const Color(0xFF9BB8DE)
        : Color.lerp(palette.sunDiscColors[2], palette.waterReflectionGlow, 0.42)!;
    final discOuterColor = isFajrMoon
        ? const Color(0xFF6B8BB8)
        : Color.lerp(palette.sunGlowOuter, palette.rippleSecondary, 0.52)!;
    final columnGlowColor = isFajrMoon ? const Color(0xFF8AAAD6) : palette.waterReflectionGlow;
    final glintColor = isFajrMoon ? const Color(0xFFE8F1FF) : palette.sparkleColor;

    // --- A. Soft Diffused Liquid Reflection Column (Underwater / Surface Scatter Glow) ---
    final glowTopHalfW = width * (isMoon ? 0.068 : 0.090);
    final glowBotHalfW = width * (isMoon ? 0.22 : 0.30);
    final glowColPath = Path()
      ..moveTo(sunX - glowTopHalfW, horizonY)
      ..lineTo(sunX + glowTopHalfW, horizonY)
      ..lineTo(sunX + glowBotHalfW, horizonY + waterHeight)
      ..lineTo(sunX - glowBotHalfW, horizonY + waterHeight)
      ..close();

    final ridgeScatterAtten = 0.48 + 0.52 * discVisibility;
    final glowIntensity = (isMoon ? 0.42 : 0.62) * (0.45 + 0.55 * orbVisibility) * celestialAlpha * ridgeScatterAtten;
    canvas.drawPath(
      glowColPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            columnGlowColor.withOpacity(glowIntensity),
            columnGlowColor.withOpacity(glowIntensity * 0.50),
            columnGlowColor.withOpacity(glowIntensity * 0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 0.30, 0.72, 1.0],
        ).createShader(Rect.fromLTWH(0, horizonY, width, waterHeight))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
    );

    // --- B. Rippled Mirror Silhouette of the Sun / Moon Disc Itself ---
    if (discVisibility > 0.05) {
      final discCenterY = horizonY + (isMoon ? 16.0 : 12.0) + (1.0 - lowOrbFactor) * (waterHeight * 0.22);
      final discVerticalStretch = orbRadius * (0.95 + lowOrbFactor * 0.55);

      // Soft molten bloom behind the reflected disc silhouette
      final discBloomRect = Rect.fromCenter(
        center: Offset(sunX, discCenterY),
        width: orbRadius * 3.5,
        height: discVerticalStretch * 2.5,
      );
      canvas.drawOval(
        discBloomRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              discMidColor.withOpacity((isMoon ? 0.48 : 0.72) * discVisibility),
              discOuterColor.withOpacity((isMoon ? 0.18 : 0.36) * discVisibility),
              Colors.transparent,
            ],
            stops: const [0.0, 0.48, 1.0],
          ).createShader(discBloomRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0),
      );

      // 18 sinuous liquid ribbons forming the wobbling mirror silhouette of the sun/moon disc
      const discSlices = 18;
      for (int s = 0; s < discSlices; s++) {
        final u = ((s + 0.5) / discSlices) * 2.0 - 1.0;
        final envelope = math.sqrt((1.0 - u * u).clamp(0.0, 1.0));
        final sy = discCenterY + u * discVerticalStretch;
        if (sy < horizonY + 1.0 || sy > horizonY + waterHeight - 2.0) continue;

        final waveSway =
            math.sin(elapsedSeconds * 2.3 + s * 0.92) * (2.0 + (u + 1.0) * 2.8) +
            math.cos(elapsedSeconds * 3.6 - s * 1.35) * 1.1;
        final shimmer = 0.76 + 0.24 * math.sin(elapsedSeconds * 3.1 + s * 1.55);

        final sliceW = math.max(5.0, orbRadius * 2.0 * (0.96 + 0.28 * lowOrbFactor) * envelope * (0.88 + 0.20 * shimmer));
        final sliceH = (1.15 + ((sy - horizonY) / waterHeight) * 2.05) * (0.80 + 0.20 * envelope);
        final sliceAlpha = (discVisibility * (isMoon ? 0.78 : (0.88 + 0.12 * lowOrbFactor)) * (0.48 + 0.52 * envelope) * shimmer)
            .clamp(0.0, 1.0);
        final curveDy = math.sin(elapsedSeconds * 2.0 + s * 0.7) * 0.55;

        final slicePath = _buildLiquidFacetPath(sunX + waveSway, sy, sliceW, sliceH, curveDy);
        final sliceRect = Rect.fromCenter(center: Offset(sunX + waveSway, sy), width: sliceW, height: sliceH + 2.0);

        canvas.drawPath(
          slicePath,
          Paint()
            ..shader = LinearGradient(
              colors: [
                discOuterColor.withOpacity(0.0),
                discMidColor.withOpacity(sliceAlpha * 0.86),
                discCoreColor.withOpacity(sliceAlpha),
                discMidColor.withOpacity(sliceAlpha * 0.86),
                discOuterColor.withOpacity(0.0),
              ],
              stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
            ).createShader(sliceRect)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
        );
      }
    }

    // --- C. Organic Cox-Munk Liquid Specular Wave Facets ("Jalan Cahaya") ---
    final baseTopConeHalfW = width * (isMoon ? 0.048 : (0.062 + 0.020 * (1.0 - lowOrbFactor)));
    final baseBotConeHalfW = width * (isMoon ? 0.175 : (0.235 + 0.045 * lowOrbFactor));
    final facetStrength = celestialAlpha * (0.36 + 0.64 * discVisibility);

    for (int i = 0; i < waveBands.length; i++) {
      final band = waveBands[i];
      final yNorm = band.yRel;
      final y = horizonY + yNorm * waterHeight;

      final coneHalfW = baseTopConeHalfW + (baseBotConeHalfW - baseTopConeHalfW) * math.pow(yNorm, 0.86);

      // Natural intensity attenuation into the darker foreground water (never harsh blocky bars at bottom)
      final depthFade = (1.0 - math.pow(yNorm, 1.35).toDouble() * 0.56).clamp(0.24, 1.0);
      final facetHeight = (0.95 + yNorm * 2.55) * (0.80 + 0.30 * band.amplitude);

      // Smooth optical color transition: incandescent white-cream near horizon -> rich golden/amber/silver in foreground
      final localCoreColor = Color.lerp(
        discCoreColor,
        isMoon ? discMidColor : discWarmColor,
        (yNorm * (isMoon ? 0.45 : (0.38 + 0.44 * lowOrbFactor))).clamp(0.0, 0.85),
      )!;
      final localMidColor = Color.lerp(
        discMidColor,
        discOuterColor,
        (yNorm * 0.52).clamp(0.0, 0.75),
      )!;

      final mainWave = math.sin(elapsedSeconds * band.speed * 1.25 + band.phase);
      final secondaryWave = math.cos(elapsedSeconds * (band.speed * 0.88) + band.secondaryPhase);
      final mainShimmer = (0.42 + 0.58 * ((mainWave + 1.0) * 0.5)).clamp(0.0, 1.0);
      final curveDy = secondaryWave * (0.45 + yNorm * 1.45);

      // 1. Central Liquid Crest (sinuous organic wave lens; breaks naturally into asymmetrical shards in foreground)
      final centerSway = mainWave * (2.5 + yNorm * 13.0) + (band.frequency - 0.5) * (4.0 + yNorm * 16.0);
      final coreWidth = coneHalfW * (0.54 + 0.44 * band.amplitude) * (0.68 + 0.38 * mainShimmer);
      final coreAlpha = ((isMoon ? 0.64 : 0.86) *
              (0.32 + 0.68 * orbVisibility) *
              facetStrength *
              depthFade *
              mainShimmer)
          .clamp(0.0, 0.94);

      if (yNorm > 0.22 && coreAlpha > 0.16) {
        final shadowRect = Rect.fromCenter(
          center: Offset(sunX + centerSway, y + facetHeight * 0.72),
          width: coreWidth * 1.10,
          height: facetHeight * 0.90,
        );
        canvas.drawOval(
          shadowRect,
          Paint()
            ..color = Colors.black.withOpacity((0.15 + 0.16 * yNorm) * mainShimmer)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
        );
      }

      final isSplitForeground = yNorm > 0.34 && ((i % 3 == 0) || band.frequency > 0.55);
      if (isSplitForeground) {
        // Asymmetrical split liquid shards separated by a dark undulating wave trough
        final gap = 3.5 + yNorm * 12.0;
        final leftRatio = 0.38 + 0.24 * band.frequency;
        final leftW = math.max(6.0, (coreWidth - gap) * leftRatio * 1.15);
        final rightW = math.max(6.0, (coreWidth - gap) * (1.0 - leftRatio) * 1.15);

        final pieces = [
          (sunX + centerSway - gap * 0.5 - leftW * 0.42, y - 0.5 * yNorm, leftW, curveDy),
          (sunX + centerSway + gap * 0.5 + rightW * 0.42, y + 0.6 * yNorm, rightW, -curveDy * 0.85),
        ];

        for (final piece in pieces) {
          final px = piece.$1;
          final py = piece.$2;
          final pw = piece.$3;
          final pCurve = piece.$4;
          final pPath = _buildLiquidFacetPath(px, py, pw, facetHeight, pCurve);
          final pRect = Rect.fromCenter(center: Offset(px, py), width: pw, height: facetHeight + 3.0);
          canvas.drawPath(
            pPath,
            Paint()
              ..shader = LinearGradient(
                colors: [
                  discOuterColor.withOpacity(0.0),
                  localMidColor.withOpacity(coreAlpha * 0.84),
                  localCoreColor.withOpacity(coreAlpha * (0.62 + 0.38 * orbVisibility)),
                  localMidColor.withOpacity(coreAlpha * 0.84),
                  discOuterColor.withOpacity(0.0),
                ],
                stops: const [0.0, 0.24, 0.50, 0.76, 1.0],
              ).createShader(pRect)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.55 + yNorm * 0.75),
          );
        }
      } else {
        final cx = sunX + centerSway;
        final corePath = _buildLiquidFacetPath(cx, y, math.max(5.0, coreWidth), facetHeight, curveDy);
        final coreRect = Rect.fromCenter(center: Offset(cx, y), width: math.max(5.0, coreWidth), height: facetHeight + 3.0);
        canvas.drawPath(
          corePath,
          Paint()
            ..shader = LinearGradient(
              colors: [
                discOuterColor.withOpacity(0.0),
                localMidColor.withOpacity(coreAlpha * 0.82),
                localCoreColor.withOpacity(coreAlpha * (0.58 + 0.42 * orbVisibility)),
                localMidColor.withOpacity(coreAlpha * 0.82),
                discOuterColor.withOpacity(0.0),
              ],
              stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
            ).createShader(coreRect)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.50 + yNorm * 0.70),
        );
      }

      // 2. Flanking Organic Shimmering Liquid Shards (scattered naturally across the glitter cone)
      final flankCount = yNorm > 0.24 ? 2 : 1;
      for (int f = 0; f < flankCount; f++) {
        for (final side in const [-1.0, 1.0]) {
          final offsetFrac = (0.44 + f * 0.36 + (band.frequency - 0.5) * 0.18).clamp(0.30, 1.08);
          final fWave = math.sin(elapsedSeconds * (band.speed * 1.12) + band.secondaryPhase + side * 1.8 + f * 2.5);
          final fShimmer = ((fWave + 1.0) * 0.5).clamp(0.0, 1.0);
          if (fShimmer < 0.30) continue; // Wave facet tilted away from sun -> natural dark liquid gap

          final fx = sunX + side * coneHalfW * offsetFrac + secondaryWave * (2.5 + yNorm * 8.0);
          final fy = y + side * (0.5 + yNorm * 1.8) + (f == 1 ? 1.2 * yNorm : 0.0);
          final fw = math.max(4.0, coneHalfW * (0.17 + 0.22 * band.amplitude) * (0.62 + 0.48 * fShimmer) * (f == 0 ? 1.0 : 0.72));
          final fh = facetHeight * (f == 0 ? 0.74 : 0.56);

          final radialFalloff = (1.0 - offsetFrac * 0.64).clamp(0.16, 1.0);
          final fAlpha = ((isMoon ? 0.46 : 0.68) *
                  (0.42 + 0.58 * orbVisibility) *
                  facetStrength *
                  depthFade *
                  radialFalloff *
                  fShimmer)
              .clamp(0.0, 0.80);

          final fPath = _buildLiquidFacetPath(fx, fy, fw, fh, curveDy * 0.7 * side);
          final fRect = Rect.fromCenter(center: Offset(fx, fy), width: fw, height: fh + 2.0);
          canvas.drawPath(
            fPath,
            Paint()
              ..shader = LinearGradient(
                colors: [
                  discOuterColor.withOpacity(0.0),
                  (f == 0 ? localMidColor : discOuterColor).withOpacity(fAlpha),
                  discOuterColor.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(fRect)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5 + yNorm * 0.6),
          );
        }
      }
    }

    // --- D. Subtle Pinpoint Specular Light Glints (Delicate horizontal liquid diamond flickers, no harsh "+" crosses) ---
    if (discVisibility > 0.14) {
      for (int k = 0; k < 20; k++) {
        final band = waveBands[(k * 3) % waveBands.length];
        final yNorm = band.yRel;
        final y = horizonY + yNorm * waterHeight;
        final coneHalfW = baseTopConeHalfW + (baseBotConeHalfW - baseTopConeHalfW) * math.pow(yNorm, 0.86);

        final twinkleRaw = (math.sin(elapsedSeconds * (2.0 + band.speed * 1.35) + band.phase * 2.1 + k) + 1.0) * 0.5;
        final flash = math.pow(twinkleRaw, 5.5).toDouble();
        if (flash < 0.08) continue;

        final sx = sunX + ((band.secondaryFrequency * 2.0 - 1.0) * coneHalfW * 0.74);
        final sparkleW = (3.0 + yNorm * 5.2) * (0.65 + 0.50 * flash);
        final sparkleH = (0.9 + yNorm * 1.1) * (0.65 + 0.45 * flash);
        final sAlpha = (flash * discVisibility * (isMoon ? 0.64 : 0.86) * (1.0 - yNorm * 0.35)).clamp(0.0, 0.92);

        // Soft luminous bokeh halo
        canvas.drawOval(
          Rect.fromCenter(center: Offset(sx, y), width: sparkleW * 1.9, height: sparkleH * 3.0),
          Paint()
            ..color = glintColor.withOpacity(sAlpha * 0.38)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
        );
        // Delicate horizontal pinpoint flare on wave ridge
        final flareRect = Rect.fromCenter(center: Offset(sx, y), width: sparkleW, height: sparkleH);
        canvas.drawOval(
          flareRect,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(sAlpha),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(flareRect),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicScenicPainter oldDelegate) {
    return true;
  }
}
