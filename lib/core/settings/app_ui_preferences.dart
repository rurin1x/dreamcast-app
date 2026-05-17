import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appUiPreferencesProvider =
    NotifierProvider<AppUiPreferencesController, AppUiPreferences>(
      AppUiPreferencesController.new,
    );

final class AppUiPreferences {
  const AppUiPreferences({
    required this.isSupportBannerHidden,
    required this.homeGridColumns,
  });

  final bool isSupportBannerHidden;
  final int homeGridColumns;

  AppUiPreferences copyWith({
    bool? isSupportBannerHidden,
    int? homeGridColumns,
  }) {
    return AppUiPreferences(
      isSupportBannerHidden:
          isSupportBannerHidden ?? this.isSupportBannerHidden,
      homeGridColumns: homeGridColumns ?? this.homeGridColumns,
    );
  }
}

final class AppUiPreferencesController extends Notifier<AppUiPreferences> {
  static const _supportBannerHiddenKey = 'ui.support_banner_hidden';
  static const _homeGridColumnsKey = 'ui.home_grid_columns';

  @override
  AppUiPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final columns = prefs.getInt(_homeGridColumnsKey) ?? 3;

    return AppUiPreferences(
      isSupportBannerHidden: prefs.getBool(_supportBannerHiddenKey) ?? false,
      homeGridColumns: columns == 4 ? 4 : 3,
    );
  }

  Future<void> hideSupportBanner() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_supportBannerHiddenKey, true);
    state = state.copyWith(isSupportBannerHidden: true);
  }

  Future<void> setHomeGridColumns(int columns) async {
    final normalized = columns == 4 ? 4 : 3;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_homeGridColumnsKey, normalized);
    state = state.copyWith(homeGridColumns: normalized);
  }
}
