class PaginationUtil {
  /// 计算当前页号
  static int getCurrentPage(int offset, int limit) {
    int page = offset ~/ limit + 1;

    return page;
  }

  /// 计算总页数
  static int getPageCount(int count, int limit) {
    int mod = count % limit;
    int pageCount = count ~/ limit;
    if (mod > 0) {
      pageCount++;
    }

    return pageCount;
  }
}
