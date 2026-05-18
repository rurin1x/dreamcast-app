import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PreferredStreamTechnology { none, hls, dash }

extension PreferredStreamTechnologyLabel on PreferredStreamTechnology {
  String get label => switch (this) {
    PreferredStreamTechnology.none => 'Не выбрано',
    PreferredStreamTechnology.hls => 'HLS',
    PreferredStreamTechnology.dash => 'DASH',
  };
}

final preferredStreamTechnologyProvider =
    NotifierProvider<
      PreferredStreamTechnologyController,
      PreferredStreamTechnology
    >(PreferredStreamTechnologyController.new);

final class PreferredStreamTechnologyController
    extends Notifier<PreferredStreamTechnology> {
  static const _key = 'player.preferred_stream_technology';

  @override
  PreferredStreamTechnology build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return PreferredStreamTechnology.values.firstWhere(
      (value) => value.name == name,
      orElse: () => PreferredStreamTechnology.none,
    );
  }

  Future<void> setTechnology(PreferredStreamTechnology technology) async {
    await ref.read(sharedPreferencesProvider).setString(_key, technology.name);
    state = technology;
  }
}

PreferredStreamTechnology technologyFromStreamType(DreamStreamType type) {
  return switch (type) {
    DreamStreamType.hls => PreferredStreamTechnology.hls,
    DreamStreamType.dash => PreferredStreamTechnology.dash,
    _ => PreferredStreamTechnology.none,
  };
}

DreamStreamType? streamTypeFromTechnology(PreferredStreamTechnology value) {
  return switch (value) {
    PreferredStreamTechnology.hls => DreamStreamType.hls,
    PreferredStreamTechnology.dash => DreamStreamType.dash,
    PreferredStreamTechnology.none => null,
  };
}

List<DreamStream> sortStreamsByPreference(
  List<DreamStream> streams,
  PreferredStreamTechnology preference,
) {
  final preferredType = streamTypeFromTechnology(preference);
  if (preferredType == null) return streams;

  return [...streams]..sort((a, b) {
    final aPreferred = a.type == preferredType;
    final bPreferred = b.type == preferredType;
    if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
    return b.quality.compareTo(a.quality);
  });
}

DreamStream pickPreferredStream(
  List<DreamStream> streams,
  PreferredStreamTechnology preference, {
  DreamStream? fallback,
}) {
  final preferredType = streamTypeFromTechnology(preference);
  if (preferredType != null) {
    for (final stream in streams) {
      if (stream.type == preferredType) return stream;
    }
  }
  if (fallback != null) {
    for (final stream in streams) {
      if (stream.type == fallback.type && stream.quality == fallback.quality) {
        return stream;
      }
    }
  }
  return streams.first;
}
