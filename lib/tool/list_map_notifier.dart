import 'package:flutter/material.dart';

class ListNotifier<T> {
  late final ValueNotifier<List<T>> _list;

  ListNotifier(List<T>? list) {
    _list = ValueNotifier<List<T>>(list ?? []);
  }

  List<T> get value => _list.value;

  set value(Iterable<T>? items) {
    _list.value = items == null ? [] : [...items];
  }

  ValueNotifier<List<T>> get listenable => _list;

  T operator [](int index) {
    return _list.value[index];
  }

  void operator []=(int index, T item) {
    if (index >= 0 && index < _list.value.length) {
      final newList = List.of(_list.value);
      newList[index] = item;
      _list.value = newList;
    }
  }

  int get length {
    return _list.value.length;
  }

  bool get isEmpty {
    return _list.value.isEmpty;
  }

  bool get isNotEmpty {
    return _list.value.isNotEmpty;
  }

  int indexOf(T item) {
    return _list.value.indexOf(item);
  }

  /// 添加单个元素
  void add(T item) {
    _list.value = [..._list.value, item];
  }

  /// 批量添加元素
  void addAll(List<T> items) {
    _list.value = [..._list.value, ...items];
  }

  /// 删除指定元素
  void remove(T item) {
    _list.value = _list.value.where((element) => element != item).toList();
  }

  /// 根据索引删除元素
  T removeAt(int index) {
    if (index >= 0 && index < _list.value.length) {
      final newList = List.of(_list.value);
      T item = newList.removeAt(index);
      _list.value = newList;

      return item;
    }
    throw '[index] must be in the range `0 ≤ index < length`';
  }

  void insert(int index, T newItem) {
    if (index >= 0 && index < _list.value.length) {
      _list.value = [..._list.value];
      _list.value.insert(index, newItem);
    }
  }

  void insertAll(int index, Iterable<T> items) {
    if (index >= 0 && index < _list.value.length) {
      _list.value = [..._list.value];
      _list.value.insertAll(index, items);
    }
  }

  /// 清空列表
  void clear() {
    _list.value = [];
  }

  void sort([int Function(T a, T b)? compare]) {
    _list.value.sort(compare);
  }

  /// 释放资源，页面销毁时必须调用
  void dispose() {
    _list.dispose();
  }
}

/// ValueNotifier 监听Map通用工具类，支持泛型，自动触发UI刷新
class MapNotifier<K, V> {
  late final ValueNotifier<Map<K, V>> _map;

  /// 初始化：可传入初始Map，默认空Map
  MapNotifier(Map<K, V>? initialMap) {
    _map = ValueNotifier(initialMap ?? {});
  }

  /// 获取当前Map数据
  Map<K, V> get value => _map.value;

  set value(Map<K, V> mapData) {
    _map.value = {...mapData};
  }

  /// 获取可监听对象，专供ValueListenableBuilder使用
  ValueNotifier<Map<K, V>> get listenable => _map;

  V? operator [](K key) {
    return _map.value[key];
  }

  void operator []=(K key, V value) {
    _map.value[key] = value;
  }

  /// 添加/修改单个键值对
  void put(K key, V value) {
    _map.value = {..._map.value, key: value};
  }

  /// 批量添加键值对
  void putAll(Map<K, V> mapData) {
    _map.value = {..._map.value, ...mapData};
  }

  /// 根据key删除键值对
  void remove(K key) {
    final newMap = Map.of(_map.value)..remove(key);
    _map.value = newMap;
  }

  /// 清空Map
  void clear() {
    _map.value = {};
  }

  /// 替换整个Map
  void replace(Map<K, V> newMap) {
    _map.value = newMap;
  }

  /// 释放资源，页面销毁时必须调用
  void dispose() {
    _map.dispose();
  }
}
