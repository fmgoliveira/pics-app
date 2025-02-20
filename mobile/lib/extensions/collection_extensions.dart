import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:immich_mobile/shared/models/asset.dart';
import 'package:immich_mobile/shared/models/user.dart';

extension ListExtension<E> on List<E> {
  List<E> uniqueConsecutive({
    int Function(E a, E b)? compare,
    void Function(E a, E b)? onDuplicate,
  }) {
    compare ??= (E a, E b) => a == b ? 0 : 1;
    int i = 1, j = 1;
    for (; i < length; i++) {
      if (compare(this[i - 1], this[i]) != 0) {
        if (i != j) {
          this[j] = this[i];
        }
        j++;
      } else if (onDuplicate != null) {
        onDuplicate(this[i - 1], this[i]);
      }
    }
    length = length == 0 ? 0 : j;
    return this;
  }

  ListSlice<E> nestedSlice(int start, int end) {
    if (this is ListSlice) {
      final ListSlice<E> self = this as ListSlice<E>;
      return ListSlice<E>(self.source, self.start + start, self.start + end);
    }
    return ListSlice<E>(this, start, end);
  }
}

extension IntListExtension on Iterable<int> {
  Int64List toInt64List() {
    final list = Int64List(length);
    list.setAll(0, this);
    return list;
  }
}

extension AssetListExtension on Iterable<Asset> {
  /// Returns the assets that are already available in the Pics server
  Iterable<Asset> remoteOnly({
    void Function()? errorCallback,
  }) {
    final bool onlyRemote = every((e) => e.isRemote);
    if (!onlyRemote) {
      if (errorCallback != null) errorCallback();
      return where((a) => a.isRemote);
    }
    return this;
  }

  /// Returns the assets that are owned by the user passed to the [owner] param
  /// If [owner] is null, an empty list is returned
  Iterable<Asset> ownedOnly(
    User? owner, {
    void Function()? errorCallback,
  }) {
    if (owner == null) return [];
    final userId = owner.isarId;
    final bool onlyOwned = every((e) => e.ownerId == userId);
    if (!onlyOwned) {
      if (errorCallback != null) errorCallback();
      return where((a) => a.ownerId == userId);
    }
    return this;
  }

  /// Returns the assets that are present on a file system which has write permission
  /// This filters out assets on readOnly external library to which we cannot perform any write operation
  Iterable<Asset> writableOnly({
    void Function()? errorCallback,
  }) {
    final bool onlyWritable = every((e) => !e.isReadOnly);
    if (!onlyWritable) {
      if (errorCallback != null) errorCallback();
      return where((a) => !a.isReadOnly);
    }
    return this;
  }

  /// Filters out offline assets and returns those that are still accessible by the Pics server
  Iterable<Asset> nonOfflineOnly({
    void Function()? errorCallback,
  }) {
    final bool onlyLive = every((e) => !e.isOffline);
    if (!onlyLive) {
      if (errorCallback != null) errorCallback();
      return where((a) => !a.isOffline);
    }
    return this;
  }
}

extension SortedByProperty<T> on Iterable<T> {
  Iterable<T> sortedByField(Comparable Function(T e) key) {
    return sorted((a, b) => key(a).compareTo(key(b)));
  }
}
