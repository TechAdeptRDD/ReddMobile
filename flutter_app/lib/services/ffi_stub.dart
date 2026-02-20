class Utf8 {}

class Uint32 {}

class Uint64 {}

class Pointer<T> {
  String toDartString() => "";
}

class DynamicLibrary {
  static open(String path) => throw UnimplementedError();
}

extension StringUtf8Pointer on String {
  Pointer<Utf8> toNativeUtf8() => Pointer<Utf8>();
}

void calloc(Pointer pointer) {}
