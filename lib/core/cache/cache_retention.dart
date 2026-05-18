enum CacheRetentionOption {
  hours8,
  hours12,
  day1,
  days3,
  days7,
  days30,
  forever,
}

extension CacheRetentionOptionLabel on CacheRetentionOption {
  String get label => switch (this) {
    CacheRetentionOption.hours8 => '8 часов',
    CacheRetentionOption.hours12 => '12 часов',
    CacheRetentionOption.day1 => '1 день',
    CacheRetentionOption.days3 => '3 дня',
    CacheRetentionOption.days7 => '7 дней',
    CacheRetentionOption.days30 => '30 дней',
    CacheRetentionOption.forever => 'Не удалять автоматически',
  };

  String get description => switch (this) {
    CacheRetentionOption.hours8 => 'Минимальный срок хранения кэша.',
    CacheRetentionOption.hours12 => 'Подходит для частого обновления релизов.',
    CacheRetentionOption.day1 => 'Баланс между свежестью и экономией сети.',
    CacheRetentionOption.days3 => 'Больше данных доступно без сети.',
    CacheRetentionOption.days7 => 'Удобно при редком подключении.',
    CacheRetentionOption.days30 => 'Долгое хранение страниц и расписания.',
    CacheRetentionOption.forever => 'Кэш будет очищаться только вручную.',
  };

  Duration? get duration => switch (this) {
    CacheRetentionOption.hours8 => const Duration(hours: 8),
    CacheRetentionOption.hours12 => const Duration(hours: 12),
    CacheRetentionOption.day1 => const Duration(days: 1),
    CacheRetentionOption.days3 => const Duration(days: 3),
    CacheRetentionOption.days7 => const Duration(days: 7),
    CacheRetentionOption.days30 => const Duration(days: 30),
    CacheRetentionOption.forever => null,
  };
}
