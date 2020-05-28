import 'dart:io';

/// 读取文件全部内容
Future<String> readAll(String file) async {
  File f = new File(file);
  if(!await f.exists()){
    return null;
  }
  List<String> lines = await f.readAsLines();
  String backStr = "";
  for(var l in lines){
    if(null != l){
      backStr = backStr+l;
    }
  }
  return backStr;
}

/// 复写文件，覆盖原有内容
Future<bool> reWrite(String filePath, String fileData) async {
  try{
    var file = await new File(filePath).create(recursive: true);
    await file.writeAsString(fileData);
    return true;
  }catch(e){
    print(e);
  }
  return false;
}

/// 追加文件内容
Future<bool> write(String filePath, String fileData) async {
  try{
    var file = await new File(filePath).create(recursive: true);
    await file.writeAsString(fileData, mode: FileMode.append);
    return true;
  }catch(e){
    print(e);
  }
  return false;
}

/// 删除 deleteFolder文件夹下所有文件，给定的retainList中的文件除外
/// 不处理子级文件夹
Future<bool> deleteFile(String deleteFolder, {List<String> retainList}) async {
  Directory d = new Directory(deleteFolder);
  if(!await d.exists()){
    return true;
  }
  Stream<FileSystemEntity> entityList = d.list(recursive: false, followLinks: false);
  await for(FileSystemEntity entity in entityList) {
    try{
      if(await FileSystemEntity.isFile(entity.path)){
        if(!(null != retainList && retainList.length > 0 && retainList.contains(entity.path))){
          await entity.delete();
        }
      }
    }catch(e){
      print(e);
    }
  }
  return true;
}

main() {
  deleteFile("/Users/abic/DartWorkSpace/allsetting/allSetting/getLanguage");
}