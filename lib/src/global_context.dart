/*
 *  全局的上下文环境变量信息
 */

/// common信息
Map<String,Object> _common = new  Map<String,Object>();
/// 设置common
void setCommon(Map<String,Object> common){
  _common = common;
}
/// 获取common
Map<String,Object> getCommon(){
  return _common;
}
/// 获取当前语言id
int getLanguageId(){
  return _common["languageId"];
}
/// 设置语言id
void setLanguageId(int languageId){
  _common["languageId"] = languageId;
}
/// 获取语言国际编码
String getLanguageCode(){
  return _common["language"];
}
/// 设置语言国际编码
void setLanguageCode(String languageCode){
  _common["language"] = languageCode;
}


/// 全局的app跟目录，必须有读写和创建删除文件文件夹的权限
String _appRootFolder;
void setAppRootFolder(String appRootFolder){
  _appRootFolder = appRootFolder;
}
String getAppRootFolder(){
  return _appRootFolder;
}