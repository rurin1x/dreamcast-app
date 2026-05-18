import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReleaseBookmarkStatus { watching, completed, dropped, planned }

extension ReleaseBookmarkStatusLabel on ReleaseBookmarkStatus {
  String get label {
    return switch (this) {
      ReleaseBookmarkStatus.watching => 'Смотрю',
      ReleaseBookmarkStatus.completed => 'Просмотрено',
      ReleaseBookmarkStatus.dropped => 'Брошено',
      ReleaseBookmarkStatus.planned => 'В планах',
    };
  }
}

final releaseBookmarkProvider =
    NotifierProvider.family<
      ReleaseBookmarkController,
      ReleaseBookmarkStatus?,
      int
    >(ReleaseBookmarkController.new);

final class ReleaseBookmarkController extends Notifier<ReleaseBookmarkStatus?> {
  ReleaseBookmarkController(this._releaseId);

  static const _prefix = 'library.release.status.';
  final int _releaseId;

  @override
  ReleaseBookmarkStatus? build() {
    final value = ref
        .watch(sharedPreferencesProvider)
        .getString('$_prefix$_releaseId');
    return _statusFromName(value);
  }

  Future<void> setStatus(ReleaseBookmarkStatus status) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString('$_prefix$_releaseId', status.name);
    state = status;
  }

  Future<void> remove() async {
    await ref.read(sharedPreferencesProvider).remove('$_prefix$_releaseId');
    state = null;
  }
}

ReleaseBookmarkStatus? _statusFromName(String? name) {
  return switch (name) {
    'watching' => ReleaseBookmarkStatus.watching,
    'completed' => ReleaseBookmarkStatus.completed,
    'dropped' => ReleaseBookmarkStatus.dropped,
    'planned' => ReleaseBookmarkStatus.planned,
    _ => null,
  };
}
