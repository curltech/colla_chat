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
        this.currentIndex(0);
      } else {
        if (currentIndex < -1 || currentIndex > data.length - 1) {
          this.currentIndex(0);
        } else {
          this.currentIndex(currentIndex);
        }
      }
    }
  }

  T? get current {
    if (this.currentIndex.value != -1 &&
        this.currentIndex.value != null &&
        data.isNotEmpty) {
      return data[this.currentIndex.value!];
    }
    return null;
  }

  set current(T? element) {
    if (element == null) {
      setCurrentIndex = null;
    } else {
      this.currentIndex(data.indexOf(element));
    }
  }

  ///设置当前数据索引
  set setCurrentIndex(int? index) {
    if (index == null || index > data.length - 1) {
      this.currentIndex(null);
      return;
    }
    if (this.currentIndex.value != index) {
      this.currentIndex(index);
    }
  }

  addAll(List<T> ds) {
    if (ds.isNotEmpty) {
      this.currentIndex(data.length);
      data.addAll(ds);
    }
  }

  add(T d) {
    data.add(d);
    this.currentIndex(data.length - 1);
  }

  T? get(int index) {
    if (index >= 0 && index < data.length) {
      return data[index];
    }

    return null;
  }

  insert(int index, T d) {
    if (index >= 0 && index <= data.length) {
      data.insert(index, d);
      this.currentIndex(index);
    }
  }

  insertAll(int index, List<T> ds) {
    if (index >= 0 && index <= data.length) {
      data.insertAll(index, ds);
      this.currentIndex(index);
    }
  }

  T? delete({int? index}) {
    index = index ?? this.currentIndex.value;
    if (index != null && index < data.length) {
      T t = data.removeAt(index);
      if (data.isEmpty) {
        this.currentIndex(null);
      } else if (index == 0) {
        this.currentIndex(0);
      } else {
        this.currentIndex(index - 1);
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

  update(T d, {int? index}) {
    index = index ?? this.currentIndex.value;
    if (index != null && index < data.length) {
      data[index] = d;
    }
  }

  clear() {
    data.clear();
    this.currentIndex(null);
  }

  ///替换了当前的对象
  replace(T d) {
    if (this.currentIndex.value != null && data.isNotEmpty) {
      data[this.currentIndex.value!] = d;
    }
  }

  replaceAll(List<T> ds) {
    data.assignAll(ds);
    if (ds.isNotEmpty) {
      this.currentIndex(0);
    }
  }

  move(int initialIndex, int finalIndex) {
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
  sort<S>(Comparable<S>? Function(T t) getFieldValue, int columnIndex,
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

    this.currentIndex(0);
    this.findCondition.value.sortColumns = [
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

  selectAll(l) {
    for (var t in data) {
      EntityUtil.setSelected(t, true);
    }
  }

  unselectAll() {
    for (var t in data) {
      EntityUtil.setSelected(t, false);
    }
  }
}

/// 分页数据控制器，记录了分页的信息
/// 页面迁移时，其中的数组的数据被换掉
abstract class DataPageController<T> extends DataListController<T> {
  DataPageController();

  previous() async {
    int offset = findCondition.value.offset;
    int limit = findCondition.value.limit;
    if (offset >= limit) {
      findCondition.value = findCondition.value.copy(offset: offset - limit);
      await findData();
    }
  }

  next() async {
    int offset = findCondition.value.offset;
    int limit = findCondition.value.limit;
    int count = findCondition.value.count;
    if (count == 0 || offset + limit <= count) {
      findCondition.value = findCondition.value.copy(offset: offset + limit);
      await findData();
    }
  }

  first() async {
    int offset = findCondition.value.offset;
    if (offset != 0) {
      findCondition.value = findCondition.value.copy(offset: 0);
      await findData();
    }
  }

  last() async {
    int limit = findCondition.value.limit;
    int count = findCondition.value.count;
    int pageCount = PaginationUtil.getPageCount(count, limit);
    if (count == 0 || pageCount > 0) {
      findCondition.value =
          findCondition.value.copy(offset: (pageCount - 1) * limit);
      await findData();
    }
  }

  movePage(int index) async {
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
