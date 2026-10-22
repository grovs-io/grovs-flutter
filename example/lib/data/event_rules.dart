// Same list the native SDKs refuse.
const reservedEventNames = {
  'app_open',
  'custom',
  'in_app_answered',
  'in_app_clicked',
  'in_app_commented',
  'in_app_dismissed',
  'in_app_held',
  'in_app_viewed',
  'install',
  'journey_entered',
  'journey_held',
  'journey_path',
  'open',
  'push_delivered',
  'push_held',
  'push_open',
  'reactivation',
  'reinstall',
  'screen_view',
  'time_spent',
  'user_referred',
  'view',
};

const maxTags = 20;
const maxTagLength = 255;

bool isReservedEventName(String name) => reservedEventNames.contains(name.trim().toLowerCase());

String? eventNameError(String name) {
  if (name.trim().isEmpty) return 'Enter an event name';
  if (isReservedEventName(name)) return '"${name.trim()}" is reserved by the SDK';
  return null;
}

String? tagsError(List<String> tags) {
  if (tags.length > maxTags) return 'Up to $maxTags tags';
  if (tags.any((t) => t.length > maxTagLength)) {
    return 'Each tag can have up to $maxTagLength characters';
  }
  return null;
}
