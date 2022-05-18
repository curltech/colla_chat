class DataProxy<T> {
  late T data;

  DataProxy(T data) {
    data = data;
  }
}

mixin DataModel<T> {
  DataProxy<T>? model;
}
