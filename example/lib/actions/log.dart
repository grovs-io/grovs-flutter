enum LogGroup { links, events, inApp, push, sdk }

enum LogType {
  link('LINK', LogGroup.links),
  create('CREATE', LogGroup.links),
  inspect('INSPECT', LogGroup.links),
  event('EVENT', LogGroup.events),
  screen('SCREEN', LogGroup.events),
  purchase('PURCHASE', LogGroup.events),
  inApp('IN-APP', LogGroup.inApp),
  push('PUSH', LogGroup.push),
  sdk('SDK', LogGroup.sdk);

  const LogType(this.label, this.group);
  final String label;
  final LogGroup group;
}

enum LogState { ok, warning, error, neutral }

enum LogFilter {
  all('All'),
  links('Links'),
  inApp('In-app'),
  events('Events'),
  push('Push'),
  errors('Errors');

  const LogFilter(this.label);
  final String label;

  bool matches(LogEntry entry) => switch (this) {
    all => true,
    links => entry.type.group == LogGroup.links,
    inApp => entry.type.group == LogGroup.inApp,
    events => entry.type.group == LogGroup.events,
    push => entry.type.group == LogGroup.push,
    errors => entry.state == LogState.error,
  };
}

/// One SDK call with its values, kept by the log so it can be run again.
/// Setters are not [repeatable]: running an old one again would leave the screen
/// showing a newer value than the SDK has.
class TestAction {
  const TestAction(
    this.type,
    this.title,
    this.code,
    this.run, {
    this.repeatable = true,
  });

  final LogType type;
  final String title;
  final String code;
  final bool repeatable;
  final Future<ActionResult> Function() run;
}

class ActionResult {
  const ActionResult(this.state, this.detail, {this.value, this.code});

  final LogState state;
  final String detail;
  final String? value;
  final String? code;
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.time,
    required this.type,
    required this.state,
    required this.title,
    required this.detail,
    required this.code,
    this.action,
    this.link,
  });

  final int id;
  final DateTime time;
  final LogType type;
  final LogState state;
  final String title;
  final String detail;
  final String code;
  final TestAction? action;
  final String? link;

  LogEntry withId(int id) => LogEntry(
    id: id,
    time: time,
    type: type,
    state: state,
    title: title,
    detail: detail,
    code: code,
    action: action,
    link: link,
  );
}
