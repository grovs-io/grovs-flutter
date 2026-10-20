/// Why an in-app message was dismissed
enum InAppDismissReason {
  closeButton,
  backdrop,
  swipe,
  app,
  orientation,
  unknown;

  static InAppDismissReason fromWire(Object? value) {
    switch (value) {
      case 'close_button':
        return closeButton;
      case 'backdrop':
        return backdrop;
      case 'swipe':
        return swipe;
      case 'app':
        return app;
      case 'orientation':
        return orientation;
      default:
        return unknown;
    }
  }
}

/// An event reported by the native SDK while an in-app message is displayed
sealed class InAppMessageEvent {
  const InAppMessageEvent();

  /// The campaign the event belongs to, when known
  String? get campaignId;

  /// Builds an event from the native wire map.
  ///
  /// Returns null for an unknown `type` or a missing required field.
  static InAppMessageEvent? fromMap(Map<dynamic, dynamic> map) {
    final campaignId = map['campaignId'] as String?;
    switch (map['type']) {
      case 'shown':
        return campaignId == null ? null : InAppMessageShown(campaignId);
      case 'clicked':
        if (campaignId == null) return null;
        final payload = map['payload'];
        return InAppMessageClicked(
          campaignId,
          buttonId: map['buttonId'] as String?,
          payload: payload is Map ? _toStringKeyedMap(payload) : null,
        );
      case 'dismissed':
        if (campaignId == null) return null;
        return InAppMessageDismissed(
          campaignId,
          InAppDismissReason.fromWire(map['reason']),
        );
      case 'answered':
        final value = map['value'];
        if (campaignId == null || value == null) return null;
        return InAppMessageAnswered(
          campaignId,
          value,
          comment: map['comment'] as String?,
        );
      case 'failed':
        final message = map['message'] as String?;
        return message == null
            ? null
            : InAppMessageFailed(message, campaignId: campaignId);
      default:
        return null;
    }
  }
}

/// The message appeared on screen
final class InAppMessageShown extends InAppMessageEvent {
  @override
  final String campaignId;

  const InAppMessageShown(this.campaignId);
}

/// The user tapped a button or the message body
final class InAppMessageClicked extends InAppMessageEvent {
  @override
  final String campaignId;

  /// The tapped button, null when the message body was tapped
  final String? buttonId;

  /// Custom data attached to the button or message
  final Map<String, dynamic>? payload;

  const InAppMessageClicked(this.campaignId, {this.buttonId, this.payload});
}

/// The message was closed
final class InAppMessageDismissed extends InAppMessageEvent {
  @override
  final String campaignId;

  final InAppDismissReason reason;

  const InAppMessageDismissed(this.campaignId, this.reason);
}

/// The user answered a survey or rating message
final class InAppMessageAnswered extends InAppMessageEvent {
  @override
  final String campaignId;

  /// The selected option id, or the star rating
  final Object value;

  /// Optional free text given with the answer
  final String? comment;

  const InAppMessageAnswered(this.campaignId, this.value, {this.comment});
}

/// The message could not be shown
final class InAppMessageFailed extends InAppMessageEvent {
  @override
  final String? campaignId;

  final String message;

  const InAppMessageFailed(this.message, {this.campaignId});
}

Map<String, dynamic> _toStringKeyedMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key as String, _convert(value)));
}

Object? _convert(Object? value) {
  if (value is Map) return _toStringKeyedMap(value);
  if (value is List) return value.map(_convert).toList();
  return value;
}
