import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:dream_cast/features/releases/data/dream_cast_diagnostics.dart';
import 'package:dream_cast/features/releases/data/release_providers.dart';
import 'package:dream_cast/features/releases/data/release_repository.dart';
import 'package:dream_cast/features/releases/domain/release.dart';
import 'package:dream_cast/features/releases/presentation/release_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final latestReleasesProvider =
    AsyncNotifierProvider<LatestReleasesController, ReleaseListState>(
      LatestReleasesController.new,
    );

final searchReleasesProvider =
    AsyncNotifierProvider<SearchReleasesController, SearchState>(
      SearchReleasesController.new,
    );

final releaseDetailProvider = FutureProvider.autoDispose
    .family<DreamData<DreamReleaseDetail>, DreamRelease>((ref, release) {
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      return ref
          .watch(releaseRepositoryProvider)
          .getDetail(release, cancelToken: cancelToken);
    });

final releaseEpisodesProvider = FutureProvider.autoDispose
    .family<DreamData<List<DreamEpisode>>, DreamReleaseDetail>((
      ref,
      detail,
    ) async {
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      try {
        final data = await ref
            .watch(releaseRepositoryProvider)
            .getEpisodes(detail, cancelToken: cancelToken);
        logDreamCastDiagnostic(
          'Provider episodes emitted: release=${detail.release.id}, '
          'count=${data.value.length}, stale=${data.isStale}, '
          'diagnostics="${_snippet(data.diagnostics ?? '')}"',
        );
        return data;
      } catch (error, stackTrace) {
        logDreamCastDiagnostic(
          'Provider episodes failed: release=${detail.release.id}, '
          'errorType=${error.runtimeType}, error=$error, stackTrace=$stackTrace',
        );
        rethrow;
      }
    });

final episodeStreamsProvider = FutureProvider.autoDispose
    .family<DreamData<List<DreamStream>>, DreamEpisode>((ref, episode) {
      return ref.watch(releaseRepositoryProvider).getStreams(episode);
    });

class LatestReleasesController extends AsyncNotifier<ReleaseListState> {
  CancelToken? _cancelToken;

  @override
  Future<ReleaseListState> build() async {
    ref.onDispose(() => _cancelToken?.cancel());
    return _loadPage(1);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel();
    state = const AsyncLoading<ReleaseListState>();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNullCompat;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final next = await _loadPage(current.page + 1);
      state = AsyncData(
        next.copyWith(
          items: [...current.items, ...next.items],
          isStale: current.isStale || next.isStale,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  Future<ReleaseListState> _loadPage(int page) async {
    _cancelToken = CancelToken();
    final data = await ref
        .read(releaseRepositoryProvider)
        .ongoingCached(page: page, pageSize: 16, cancelToken: _cancelToken);
    final value = data.value;
    logReleaseSample(
      source: 'Provider latest page=$page',
      releases: value.items,
      totalCount: value.totalCount,
      isStale: data.isStale,
    );
    return ReleaseListState(
      items: value.items,
      totalCount: value.totalCount,
      page: value.page,
      pageSize: value.pageSize,
      isStale: data.isStale,
    );
  }
}

final class SearchState {
  const SearchState({
    required this.query,
    required this.history,
    required this.items,
    required this.isSearching,
    required this.isStale,
    this.error,
  });

  const SearchState.initial({required this.history})
    : query = '',
      items = const [],
      isSearching = false,
      isStale = false,
      error = null;

  final String query;
  final List<String> history;
  final List<DreamRelease> items;
  final bool isSearching;
  final bool isStale;
  final Object? error;

  SearchState copyWith({
    String? query,
    List<String>? history,
    List<DreamRelease>? items,
    bool? isSearching,
    bool? isStale,
    Object? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      history: history ?? this.history,
      items: items ?? this.items,
      isSearching: isSearching ?? this.isSearching,
      isStale: isStale ?? this.isStale,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final class SearchReleasesController extends AsyncNotifier<SearchState> {
  static const _historyKey = 'search.history';

  Timer? _debounce;
  CancelToken? _cancelToken;

  @override
  Future<SearchState> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel();
    });
    return SearchState.initial(history: _readHistory());
  }

  void setQuery(String query) {
    final current =
        state.valueOrNullCompat ?? SearchState.initial(history: _readHistory());
    final normalized = query.trim();
    _debounce?.cancel();
    _cancelToken?.cancel();

    if (normalized.length < 2) {
      state = AsyncData(
        current.copyWith(
          query: query,
          items: const [],
          isSearching: false,
          isStale: false,
          clearError: true,
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(query: query, isSearching: true, clearError: true),
    );
    _debounce = Timer(const Duration(milliseconds: 420), () {
      unawaited(_search(normalized));
    });
  }

  Future<void> submit(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    _debounce?.cancel();
    await _search(normalized, saveHistory: true);
  }

  Future<void> removeHistoryItem(String query) async {
    final history = _readHistory().where((item) => item != query).toList();
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_historyKey, history);
    final current =
        state.valueOrNullCompat ?? const SearchState.initial(history: []);
    state = AsyncData(current.copyWith(history: history));
  }

  Future<void> _search(String query, {bool saveHistory = false}) async {
    final current =
        state.valueOrNullCompat ?? SearchState.initial(history: _readHistory());
    _cancelToken = CancelToken();
    state = AsyncData(
      current.copyWith(query: query, isSearching: true, clearError: true),
    );

    try {
      final result = await ref
          .read(releaseRepositoryProvider)
          .searchCached(query, cancelToken: _cancelToken);
      logReleaseSample(
        source: 'Provider search "$query"',
        releases: result.value.items,
        totalCount: result.value.totalCount,
        isStale: result.isStale,
      );
      final history = saveHistory ? await _saveHistory(query) : _readHistory();
      state = AsyncData(
        current.copyWith(
          query: query,
          history: history,
          items: result.value.items,
          isSearching: false,
          isStale: result.isStale,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_cancelToken?.isCancelled == true) return;
      state = AsyncData(
        current.copyWith(query: query, isSearching: false, error: error),
      );
    }
  }

  List<String> _readHistory() {
    return ref.read(sharedPreferencesProvider).getStringList(_historyKey) ??
        const [];
  }

  Future<List<String>> _saveHistory(String query) async {
    final normalized = query.trim();
    final history = [
      normalized,
      ..._readHistory().where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(12).toList();
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_historyKey, history);
    return history;
  }
}

extension AsyncValueCompat<T> on AsyncValue<T> {
  T? get valueOrNullCompat => switch (this) {
    AsyncData(:final value) => value,
    _ => null,
  };
}

String _snippet(String value, {int max = 300}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}
