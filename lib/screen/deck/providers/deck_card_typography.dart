import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When true, [DeckCardTypography.baseTextStyle] skips Google Fonts (no HTTP) so
/// widget tests can assert font sizes without loading Noto Sans JP.
@visibleForTesting
bool deckCardTypographyUsePlainTextStyleInTests = false;

/// Per-deck card field typography (main line + wiki ruby readings), persisted locally.
class DeckCardTypography {
  const DeckCardTypography({
    required this.baseFontSize,
    required this.rubyFontSize,
  });

  static const DeckCardTypography defaults = DeckCardTypography(
    baseFontSize: 18,
    rubyFontSize: 9.9,
  );

  static const double minBase = 12;
  static const double maxBase = 32;
  static const double minRuby = 6;
  static const double maxRuby = 28;

  final double baseFontSize;
  final double rubyFontSize;

  DeckCardTypography clamped() => DeckCardTypography(
    baseFontSize: baseFontSize.clamp(minBase, maxBase),
    rubyFontSize: rubyFontSize.clamp(minRuby, maxRuby),
  );

  DeckCardTypography copyWith({double? baseFontSize, double? rubyFontSize}) =>
      DeckCardTypography(
        baseFontSize: baseFontSize ?? this.baseFontSize,
        rubyFontSize: rubyFontSize ?? this.rubyFontSize,
      );

  TextStyle baseTextStyle(Color color) {
    if (deckCardTypographyUsePlainTextStyleInTests) {
      return TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
      );
    }
    return GoogleFonts.notoSansJp(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color,
    );
  }

  TextStyle rubyTextStyle(Color color) =>
      wikiRubyReadingStyle(baseTextStyle(color), rubyFontSize: rubyFontSize);
}

/// Front and back typography for a deck (separate sliders in the Font sheet).
class DeckCardSidesTypography {
  const DeckCardSidesTypography({required this.front, required this.back});

  static const DeckCardSidesTypography defaults = DeckCardSidesTypography(
    front: DeckCardTypography.defaults,
    back: DeckCardTypography.defaults,
  );

  final DeckCardTypography front;
  final DeckCardTypography back;

  DeckCardTypography forSide(bool isFront) => isFront ? front : back;

  DeckCardSidesTypography copyWith({
    DeckCardTypography? front,
    DeckCardTypography? back,
  }) => DeckCardSidesTypography(
    front: front ?? this.front,
    back: back ?? this.back,
  );
}

String _prefsBaseFrontKey(String deckId) =>
    'deck_typography_base_front_v1_$deckId';

String _prefsRubyFrontKey(String deckId) =>
    'deck_typography_ruby_front_v1_$deckId';

String _prefsBaseBackKey(String deckId) =>
    'deck_typography_base_back_v1_$deckId';

String _prefsRubyBackKey(String deckId) =>
    'deck_typography_ruby_back_v1_$deckId';

/// Legacy single-side keys (pre front/back split); migrated on first load.
String _prefsLegacyBaseKey(String deckId) => 'deck_typography_base_v1_$deckId';

String _prefsLegacyRubyKey(String deckId) => 'deck_typography_ruby_v1_$deckId';

/// Deck front/back typography per deck id. (Notifier class was renamed so Riverpod
/// does not reuse a stale registration after the state type moved to [DeckCardSidesTypography].)
final deckSidesTypographyProvider = NotifierProvider.autoDispose
    .family<DeckSidesTypographyNotifier, DeckCardSidesTypography, String>(
      DeckSidesTypographyNotifier.new,
    );

class DeckSidesTypographyNotifier extends Notifier<DeckCardSidesTypography> {
  DeckSidesTypographyNotifier(this.deckId);

  final String deckId;

  @override
  DeckCardSidesTypography build() {
    Future<void>.microtask(_hydrate);
    return DeckCardSidesTypography.defaults;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final bf = prefs.getDouble(_prefsBaseFrontKey(deckId));
    final rf = prefs.getDouble(_prefsRubyFrontKey(deckId));
    final bb = prefs.getDouble(_prefsBaseBackKey(deckId));
    final rb = prefs.getDouble(_prefsRubyBackKey(deckId));

    if (bf != null || rf != null || bb != null || rb != null) {
      state = DeckCardSidesTypography(
        front: DeckCardTypography(
          baseFontSize: bf ?? DeckCardTypography.defaults.baseFontSize,
          rubyFontSize: rf ?? DeckCardTypography.defaults.rubyFontSize,
        ).clamped(),
        back: DeckCardTypography(
          baseFontSize: bb ?? DeckCardTypography.defaults.baseFontSize,
          rubyFontSize: rb ?? DeckCardTypography.defaults.rubyFontSize,
        ).clamped(),
      );
      return;
    }

    final legacyB = prefs.getDouble(_prefsLegacyBaseKey(deckId));
    final legacyR = prefs.getDouble(_prefsLegacyRubyKey(deckId));
    if (legacyB != null || legacyR != null) {
      final leg = DeckCardTypography(
        baseFontSize: legacyB ?? DeckCardTypography.defaults.baseFontSize,
        rubyFontSize: legacyR ?? DeckCardTypography.defaults.rubyFontSize,
      ).clamped();
      state = DeckCardSidesTypography(front: leg, back: leg);
      await _persist(state);
    }
  }

  Future<void> _persist(DeckCardSidesTypography value) async {
    final prefs = await SharedPreferences.getInstance();
    final f = value.front.clamped();
    final b = value.back.clamped();
    await prefs.setDouble(_prefsBaseFrontKey(deckId), f.baseFontSize);
    await prefs.setDouble(_prefsRubyFrontKey(deckId), f.rubyFontSize);
    await prefs.setDouble(_prefsBaseBackKey(deckId), b.baseFontSize);
    await prefs.setDouble(_prefsRubyBackKey(deckId), b.rubyFontSize);
  }

  void setBaseFontSize(bool isFront, double value) {
    final side = state.forSide(isFront);
    final next = side.copyWith(baseFontSize: value).clamped();
    state = isFront ? state.copyWith(front: next) : state.copyWith(back: next);
  }

  void setRubyFontSize(bool isFront, double value) {
    final side = state.forSide(isFront);
    final next = side.copyWith(rubyFontSize: value).clamped();
    state = isFront ? state.copyWith(front: next) : state.copyWith(back: next);
  }

  Future<void> persistCurrent() => _persist(state);
}
