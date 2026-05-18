import 'package:dream_cast/features/releases/domain/release.dart';

final class ReleaseSchedule {
  const ReleaseSchedule({required this.days});

  final List<ReleaseScheduleDay> days;
}

final class ReleaseScheduleDay {
  const ReleaseScheduleDay({required this.title, required this.releases});

  final String title;
  final List<DreamRelease> releases;
}
