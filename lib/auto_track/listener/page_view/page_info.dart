import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/manager.dart';
import '../../utils/element_util.dart';

class PageInfo {
  PageInfo._(this.timer);

  factory PageInfo.fromElement(Element element, Route route) {
    AutoTrackPageConfig pageConfig = AutoTrackConfigManager.instance.getPageConfig(element.widget);
    PageInfo pageInfo = PageInfo._(PageTimer());
    pageInfo._pageKey = element.widget.runtimeType.toString();
    pageInfo._pagePath = pageConfig.pagePath ?? route.settings.name ?? '';
    pageInfo._pageTitle = pageConfig.pageTitle ?? pageInfo._findTitle(element) ?? '';
    pageInfo._pageManualKey = pageConfig.pageID ?? md5.convert(utf8.encode('${pageInfo._pageKey}${pageInfo._pagePath}${pageInfo._pageTitle}')).toString();
    pageInfo.ignore = pageInfo._checkIgnore(pageConfig);
    return pageInfo;
  }

  final PageTimer timer;
  bool isBack = false;
  bool ignore = false;

  String _pageKey = '';
  String get pageKey => _pageKey;

  String _pageTitle = '';
  String get pageTitle => _pageTitle;

  String _pageManualKey = '';
  String get pageManualKey => _pageManualKey;

  String _pagePath = '';
  String get pagePath => _pagePath;

  bool _checkIgnore(AutoTrackPageConfig pageConfig) {
    if (pageConfig.ignore) {
      return true;
    }

    if (AutoTrackConfigManager.instance.config.enableIgnoreNullKey && pageConfig.pageID == null) {
      return true;
    }

    return false;
  }

  String? _findTitle(Element element) {
    String? title;
    ElementUtil.walkElement(element, (child, _) {
      if (child.widget is NavigationToolbar) {
        NavigationToolbar toolBar = child.widget as NavigationToolbar;
        if (toolBar.middle == null) {
          return false;
        }

        if (toolBar.middle is Text) {
          title = (toolBar.middle as Text).data;
          return false;
        }

        int layoutIndex = 0;
        if (toolBar.leading != null) {
          layoutIndex += 1;
        }
        title = _findTextsInMiddle(child, layoutIndex);
        return false;
      }
      return true;
    });
    return title;
  }
  String? _findTextsInMiddle(Element element, int layoutIndex) {
    String? text;
    int index = 0;
    ElementUtil.walkElement(element, ((child, _) {
      if (child.widget is LayoutId) {
        if (index == layoutIndex) {
          text = ElementUtil.findTexts(child).join('');
          return false;
        }
        index += 1;
      }
      return true;
    }));
    return text;
  }

  @override
  String toString() => '{ pageKey: $pageKey,  pageTitle: $pageTitle,  pageManualKey: $pageManualKey,  pagePath: $pagePath, isBack: $isBack }';
}

enum PageTimerState {
  init,
  start,
  pause,
  resume,
  end,
}

class PageTimer {
  PageTimer();

  PageTimerState _state = PageTimerState.init;
  PageTimerState get state => _state;

  int _lastTimeStamp = 0;

  Duration _duration = const Duration();
  Duration get duration => _duration;

  int _computeMilliseconds() {
    return DateTime.now().millisecondsSinceEpoch - _lastTimeStamp;
  }

  start() {
    if (_state != PageTimerState.init && _state != PageTimerState.end) {
      return;
    }

    _state = PageTimerState.start;
    _lastTimeStamp = DateTime.now().millisecondsSinceEpoch;
    _duration = const Duration();
  }

  pause() {
    if (_state != PageTimerState.start && _state != PageTimerState.resume) {
      return;
    }

    _state = PageTimerState.pause;
    _duration = Duration(milliseconds: _duration.inMilliseconds + _computeMilliseconds());
  }

  resume() {
    if (_state != PageTimerState.pause) {
      return;
    }

    _state = PageTimerState.resume;
    _lastTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  end() {
    if (_state == PageTimerState.pause) {
      _state = PageTimerState.end;
      return;
    }

    if (_state == PageTimerState.start || _state == PageTimerState.resume) {
      _state = PageTimerState.end;
      _duration = Duration(milliseconds: _duration.inMilliseconds + _computeMilliseconds());
    }
  }
}
