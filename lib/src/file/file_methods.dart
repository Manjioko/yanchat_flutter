// 输入一个文件大小，转换成 KB MB GB 等更加直观的方式
String byteCovert(int size)  {
    final msize = size / (1024 * 1024);
    if (msize < 1) {
        return '${(msize * 1024).toStringAsFixed(2)} K';
    }

    if (msize > 1024) {
        return '${(msize / 1024).toStringAsFixed(2)} G';
    }

    return '$msize M';
}