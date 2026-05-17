import 'package:dream_cast/features/releases/domain/release.dart';

final class ReleaseListState {
  const ReleaseListState({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.isStale,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  const ReleaseListState.empty({this.pageSize = 16})
    : items = const [],
      totalCount = 0,
      page = 0,
      isStale = false,
      isLoadingMore = false,
      loadMoreError = null;

  final List<DreamRelease> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool isStale;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => items.length < totalCount || page == 0;

  ReleaseListState copyWith({
    List<DreamRelease>? items,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? isStale,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ReleaseListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isStale: isStale ?? this.isStale,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}
