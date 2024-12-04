import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/pagination_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///基础的数组数据控制器
class DataListController<T> {
  Key key = UniqueKey();
  final RxList<T> data = <T>[].obs;
  final Rx<int?> currentIndex = Rx<int?>(null);
  final Rx<int?> sortColumnIndex = Rx<int?>(null);
  final Rx<String?> sortColumnName = Rx<String?>(null);
  final RxBool sortAscending = true.obs;

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
    if (this.currentIndex.value != null && data.isNotEmpty) {
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

  addAll(List<T> ds, {bool notify = true}) {
    if (ds.isNotEmpty) {
      this.currentIndex(data.length);
      data.addAll(ds);
    }
  }

  add(T d, {bool notify = true}) {
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

  update(T d, {int? index}) {
    index = index ?? this.currentIndex.value;
    if (index != null && index < data.length) {
      data[index] = d;
    }
  }

  clear({bool notify = true}) {
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
    sortColumnIndex(columnIndex);
    sortColumnName(columnName);
    sortAscending(ascending);
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
}

/// 分页数据控制器，记录了分页的信息
/// 页面迁移时，其中的数组的数据被换掉
class DataPageController<T> extends DataListController<T> {
  ///总行数
  final RxInt count = 0.obs;

  ///当前页的第一行的行号
  final RxInt offset = defaultOffset.obs;

  ///每页行数
  final RxInt limit = defaultLimit.obs;

  DataPageController();

  reset() {
    sortColumnName(null);
    sortColumnIndex(null);
    sortAscending(true);
    count(0);
    offset(defaultOffset);
    limit(defaultLimit);
    data.clear();
  }

  previous() {
    if (offset.value >= limit.value) {
      offset(offset.value - limit.value);
    }
  }

  next() {
    if (offset.value + limit.value <= count.value) {
      offset(offset.value + limit.value);
    }
  }

  first() {
    if (offset.value != 0) {
      offset(0);
    }
  }

  last() {
    int pageCount = PaginationUtil.getPageCount(count.value, limit.value);
    if (pageCount > 0) {
      offset((pageCount - 1) * limit.value);
    }
  }

  movePage(int index) {
    int currentPage = PaginationUtil.getCurrentPage(offset.value, limit.value);
    if (currentPage != index) {
      offset(index * limit.value);
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
