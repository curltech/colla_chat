import 'dart:async';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/pagination_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SortColumn {
  final int index;
  final String name;
  final bool ascending;

  SortColumn(this.index, this.name, this.ascending);
}

class FindCondition {
  Map<String, dynamic> whereColumns;
  List<SortColumn> sortColumns;

  ///总行数
  int count;

  ///当前页的第一行的行号
  int offset;

  ///每页行数
  int limit;

  FindCondition({
    this.whereColumns = const {},
    this.sortColumns = const [],
    this.count = 0,
    this.offset = defaultOffset,
    this.limit = defaultLimit,
  });

  FindCondition copy(
      {Map<String, dynamic>? whereColumns,
      List<SortColumn>? sortColumns,
      int? count,
      int? offset,
      int? limit}) {
    FindCondition findCondition = FindCondition(
      whereColumns: whereColumns ?? this.whereColumns,
      sortColumns: sortColumns ?? this.sortColumns,
      count: count ?? this.count,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );

    return findCondition;
  }
}

///基础的数组数据控制器
class DataListController<T> {
  Key key = UniqueKey();
  final RxList<T> data = <T>[].obs;
  final Rx<int?> currentIndex = Rx<int?>(null);
  final Rx<FindCondition> findCondition = Rx<FindCondition>(FindCondition());

  DataListController({List<T>? data, int? currentIndex}) {
    if (data != null && data.isNotEmpty) {
      this.data.addAll(data);
      if (currentIndex == null) {
        this.currentIndex.value = 0;
      } else {
        if (currentIndex < -1 || currentIndex > data.length - 1) {
          this.currentIndex.value = 0;
        } else {
          this.currentIndex.value = currentIndex;
        }
      }
    }
  }

  T? get current {
    if (currentIndex.value != -1 &&
        currentIndex.value != null &&
        currentIndex.value! < data.length &&
        data.isNotEmpty) {
      return data[currentIndex.value!];
    }
    return null;
  }

  set current(T? element) {
    if (element == null) {
      setCurrentIndex = null;
    } else {
      setCurrentIndex = data.indexOf(element);
    }
  }

  ///设置当前数据索引
  set setCurrentIndex(int? index) {
    if (index == null || index > data.length - 1) {
      currentIndex.value = null;
      return;
    }
    if (currentIndex.value != index) {
      currentIndex.value = index;
    }
  }

  void addAll(List<T> ds) {
    if (ds.isNotEmpty) {
      data.addAll(ds);
      currentIndex.value = data.length - 1;
    }
  }

  void add(T d) {
    data.add(d);
    currentIndex.value = data.length - 1;
  }

  T? get(int index) {
    if (index >= 0 && index < data.length) {
      return data[index];
    }

    return null;
  }

  void insert(int index, T d) {
    if (index >= 0 && index <= data.length) {
      data.insert(index, d);
      currentIndex.value = index;
    }
  }

  void insertAll(int index, List<T> ds) {
    if (index >= 0 && index <= data.length) {
      data.insertAll(index, ds);
      currentIndex.value = index;
    }
  }

  T? delete({int? index}) {
    index = index ?? currentIndex.value;
    if (index != null && index < data.length) {
      T t = data.removeAt(index);
      if (data.isEmpty) {
        currentIndex(null);
      } else if (index == 0) {
        currentIndex.value = 0;
      } else {
        currentIndex.value = (index - 1);
      }
      return t;
    }

    return null;
  }

  T? remove(T t) {
    int index = data.indexOf(t);
    if (index == -1) {
      return null;
    }

    return delete(index: index);
  }

  void update(T d, {int? index}) {
    index = index ?? currentIndex.value;
    if (index != null && index < data.length) {
      data[index] = d;
    }
  }

  void clear() {
    if (data.isNotEmpty) {
      data.clear();
      currentIndex.value = null;
    }
  }

  ///替换了当前的对象
  void replace(T d) {
    if (currentIndex.value != null && data.isNotEmpty) {
      data[currentIndex.value!] = d;
    }
  }

  void replaceAll(List<T> ds) {
    data.assignAll(ds);
    if (ds.isNotEmpty) {
      currentIndex.value = data.length - 1;
    }
  }

  void move(int initialIndex, int finalIndex) {
    var mediaSource = data[initialIndex];
    data[initialIndex] = data[finalIndex];
    data[finalIndex] = mediaSource;
  }

  int get length => data.length;

  /// 获取数据的方法，子类可以覆盖
  FutureOr<void> findData() async {}

  String? orderBy() {
    String? orderBy;
    for (var sortColumn in findCondition.value.sortColumns) {
      orderBy = orderBy == null ? '' : ',';
      orderBy += '$sortColumn.name ${sortColumn.ascending ? 'asc' : 'desc'}';
    }

    return orderBy;
  }

  /// 已有数据的排序
  void sort<S>(Comparable<S>? Function(T t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    data.sort((T a, T b) {
      Comparable<S>? av = getFieldValue(a);
      Comparable<S>? bv = getFieldValue(b);
      if (ascending) {
        if (av == null) {
          return 0;
        }
        if (bv == null) {
          return 1;
        }
        return Comparable.compare(av, bv);
      } else {
        if (av == null) {
          return 1;
        }
        if (bv == null) {
          return 0;
        }
        return Comparable.compare(bv, av);
      }
    });

    currentIndex.value = 0;
    findCondition.value.sortColumns = [
      SortColumn(columnIndex, columnName, ascending)
    ];
  }

  List<T> get selected {
    List<T> selectedData = [];
    for (var t in data) {
      bool? selected = EntityUtil.getSelected(t);
      if (selected != null && selected) {
        selectedData.add(t);
      }
    }

    return selectedData;
  }

  void selectAll() {
    for (var t in data) {
      EntityUtil.setSelected(t, true);
    }
  }

  void unselectAll() {
    for (var t in data) {
      EntityUtil.setSelected(t, false);
    }
  }

  List<T> get checked {
    List<T> checkedData = [];
    for (var t in data) {
      bool? checked = EntityUtil.getChecked(t);
      if (checked != null && checked) {
        checkedData.add(t);
      }
    }

    return checkedData;
  }

  void checkAll() {
    for (var t in data) {
      EntityUtil.setChecked(t, true);
    }
  }

  void uncheckAll() {
    for (var t in data) {
      EntityUtil.setChecked(t, false);
    }
  }
}

/// 分页数据控制器，记录了分页的信息
/// 页面迁移时，其中的数组的数据被换掉
abstract class DataPageController<T> extends DataListController<T> {
  DataPageController();

  Future<void> previous() async {
    int offset = findCondition.value.offset;
    int limit = findCondition.value.limit;
    if (offset >= limit) {
      findCondition.value = findCondition.value.copy(offset: offset - limit);
      await findData();
    }
  }

  Future<void> next() async {
    int offset = findCondition.value.offset;
    int limit = findCondition.value.limit;
    int count = findCondition.value.count;
    if (count == 0 || offset + limit <= count) {
      findCondition.value = findCondition.value.copy(offset: offset + limit);
      await findData();
    }
  }

  Future<void> first() async {
    int offset = findCondition.value.offset;
    if (offset != 0) {
      findCondition.value = findCondition.value.copy(offset: 0);
      await findData();
    }
  }

  Future<void> last() async {
    int limit = findCondition.value.limit;
    int count = findCondition.value.count;
    int pageCount = PaginationUtil.getPageCount(count, limit);
    if (count == 0 || pageCount > 0) {
      findCondition.value =
          findCondition.value.copy(offset: (pageCount - 1) * limit);
      await findData();
    }
  }

  Future<void> movePage(int index) async {
    int offset = findCondition.value.offset;
    int limit = findCondition.value.limit;
    int currentPage = PaginationUtil.getCurrentPage(offset, limit);
    if (currentPage != index) {
      findCondition.value = findCondition.value.copy(offset: index * limit);
      await findData();
    }
  }
}

///更多数据的数据控制器
///支持通过more方法往数组中添加更多的数据
abstract class DataMoreController<T> extends DataListController<T> {
  DataMoreController({
    super.data,
    super.currentIndex,
  });

  ///取更多旧的数据，添加
  Future<int> previous({int? limit});

  ///取更多新的数据，添加
  Future<int> latest({int? limit});
}
