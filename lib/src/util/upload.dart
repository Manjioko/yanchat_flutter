import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:yanchat01/src/util/request.dart';
import 'package:yanchat01/src/util/share.dart';
import 'package:yanchat01/src/util/uuid.dart';

void mediaUpload(File fileData, Function callback) async {
    final Uint8List file = fileData.readAsBytesSync();
    final localFileName = path.basename(fileData.path);
    final Function cb = callback;
    int uploadedSize = 0;
    String uid = 'bit_slice_${Uid.instance.v4}';

    // 切分文件
    List<Uint8List> slice(Uint8List file) {
        int LEN = 1024 * 1024 * 1;
        int start = 0;
        int end = LEN;
        int size = file.length;
        List<Uint8List> sliceAry = [];
        while (size > LEN) {
            sliceAry.add(file.sublist(start, end));
            size = size - LEN;
            start = end;
            end = end + LEN;
        }
        if (size > 0) {
            sliceAry.add(file.sublist(start));
        }
        return sliceAry;
    }

    // 读百分比函数
    void getPercent(int loaded, int total) {
        final fileSize = file.length;
        final percent = (loaded*100/total);
        if (percent >= 100) {
            uploadedSize += total;
            cb(null, (uploadedSize / fileSize * 100).round(), null);
        }
    }

    // 确认合并
    Future<void> confirmCombine(String localFileName, String dirName)  async {
        final url = await Share.instance.getString('baseUrl') ?? '';
        
        Request.instance.dio.post('$url/joinFile', data: {
            'fileName': localFileName,
            'uid': dirName
        }).then((res) {
          // print('res -> $res');
          if (res.statusCode == 200) {
            cb(null, null, res.data);
          }
        }).catchError((err) {
            if (err) {
              cb('确认合并错误 -> $err');
                return;
            }
        });
    }


    // 文件切片上传
    Future<String> sliceFile (Uint8List data, int index, String uid) async {
        final d = data;
        final i = index;
        final fd =  FormData.fromMap({
            'file': MultipartFile.fromBytes(d, filename: Uid.instance.v4),
        });
        try {
          final url = await Share.instance.getString('baseUrl') ?? '';
          final res = await Request.instance.dio.post('$url/uploadSliceFile', data: fd, onSendProgress: getPercent, queryParameters: {
            'index': i,
            'uid': uid
          });
          if (res.statusCode == 200) {
            return('Ok');
          } else {
            return('上传错误 -> $res');
          }
        } catch (error) {
          return('上传错误 -> $error');
        }
    }

    // 失败上传列表处理
    Future<void> failListHandle(List<Map<String, dynamic>> list, String localFileName) async {
        List<Map<String, dynamic>> tryList = list;
        // 尝试 5 次
        for (var re = 0; re < 5; re++) {
            List<Map<String, dynamic>> failList = [];
            for (var i = 0; i < tryList.length; i++) {
                try {
                    await sliceFile(tryList[i]['data'], tryList[i]['index'], uid);
                } catch (error) {
                    uploadedSize -= (tryList[i]['data']?.length as int);
                    failList.add(tryList[i]);
                }

            }
            // failList.length === 0 证明全部上传成功
            if (failList.isEmpty) {
                confirmCombine(localFileName, uid);
                return;
            }
            tryList = failList;
        }

        // 尝试 5 次后, 如果还是失败, 则直接提示失败
        Request.instance.dio.post('${await Share.instance.getString('baseUrl')}/clearDir', data: {
            'dirName': uid
        });
    }

    // 切片
    final fileAry = slice(file);

    // 每次上传 3 个
    const everyTimeNumber = 3;
    // 上传切片次数
    int loopTime = (fileAry.length / everyTimeNumber).ceil();

    // 失败切片列表
    List<Map<String, dynamic>> failList = [];

    // 成功数量
    int successNumber = 0;

    // 上传切片
    for (var i = 0; i < loopTime; i++) {

        // 上传
        final sliceFileDataAry = fileAry
        .sublist(
          i * everyTimeNumber,
          i == loopTime - 1 ? fileAry.length : (i + 1) * everyTimeNumber,
        )
        .asMap()
        .entries
        .map((entry) => sliceFile(entry.value, entry.key + i * everyTimeNumber, uid))
        .toList();
        // allsettled 后返回的是一个数组, 可能有失败也有成功
        final List<Future<Map<String, dynamic>>> futures = sliceFileDataAry.map((future) async {
          try {
            final result = await future;
            return {'status': 'fulfilled', 'value': result};
          } catch (e) {
            return {'status': 'rejected', 'reason': e};
          }
        }).toList();

        final List<Map<String, dynamic>> res = await Future.wait(futures);

        // 处理上传失败的片段
        for(var ri = 0; ri < res.length; ri++) {
          if (res[ri]['status'] != 'fulfilled') {
                // 减去多余的上传进度
                uploadedSize -= fileAry[i * everyTimeNumber + ri].length;
                failList.add({
                    'index': i * everyTimeNumber + ri,
                    'data': fileAry[i * everyTimeNumber + ri]
                });
                return;
            }
            successNumber += 1;
        }
    }

    // 全部上传成功后, 确认合并
    if (successNumber == fileAry.length) {
        confirmCombine(localFileName, uid);
        return;
    }

    // 处理上传失败的切片
    failListHandle(failList, localFileName);
}