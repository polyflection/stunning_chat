enum ChangeType { added, modified, removed }

class DataChange<T> {
  DataChange(this.type, this.data, this.oldIndex, this.newIndex);
  final ChangeType type;
  final T data;
  final int oldIndex;
  final int newIndex;
}
