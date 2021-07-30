import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/theme/avatar_theme.dart';

/// Theme for channel preview
class ChannelPreviewTheme with Diagnosticable {
  /// Constructor for creating [ChannelPreviewTheme]
  const ChannelPreviewTheme({
    this.titleStyle,
    this.subtitleStyle,
    this.lastMessageAtStyle,
    this.avatarTheme,
    this.unreadCounterColor,
    this.indicatorIconSize,
  });

  /// Theme for title
  final TextStyle? titleStyle;

  /// Theme for subtitle
  final TextStyle? subtitleStyle;

  /// Theme of last message at
  final TextStyle? lastMessageAtStyle;

  /// Avatar theme
  final AvatarThemeData? avatarTheme;

  /// Unread counter color
  final Color? unreadCounterColor;

  /// Indicator icon size
  final double? indicatorIconSize;

  /// Copy with theme
  ChannelPreviewTheme copyWith({
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? lastMessageAtStyle,
    AvatarThemeData? avatarTheme,
    Color? unreadCounterColor,
    double? indicatorIconSize,
  }) =>
      ChannelPreviewTheme(
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        lastMessageAtStyle: lastMessageAtStyle ?? this.lastMessageAtStyle,
        avatarTheme: avatarTheme ?? this.avatarTheme,
        unreadCounterColor: unreadCounterColor ?? this.unreadCounterColor,
        indicatorIconSize: indicatorIconSize ?? this.indicatorIconSize,
      );

  /// Merge with theme
  ChannelPreviewTheme merge(ChannelPreviewTheme? other) {
    if (other == null) return this;
    return copyWith(
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      subtitleStyle:
          subtitleStyle?.merge(other.subtitleStyle) ?? other.subtitleStyle,
      lastMessageAtStyle: lastMessageAtStyle?.merge(other.lastMessageAtStyle) ??
          other.lastMessageAtStyle,
      avatarTheme: avatarTheme?.merge(other.avatarTheme) ?? other.avatarTheme,
      unreadCounterColor: other.unreadCounterColor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('titleStyle', titleStyle))
      ..add(DiagnosticsProperty('subtitleStyle', subtitleStyle))
      ..add(DiagnosticsProperty('lastMessageAtStyle', lastMessageAtStyle))
      ..add(DiagnosticsProperty('avatarTheme', avatarTheme))
      ..add(ColorProperty('unreadCounterColor', unreadCounterColor));
  }
}
