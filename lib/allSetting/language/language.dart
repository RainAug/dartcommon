import 'package:dartcommon/src/myfile.dart' as MyFile;
import 'package:dartcommon/src/global_context.dart' as GlobalContext;
import 'dart:convert' as Convert;
import '../../config/interfaceConfig.dart' as InterfaceConfig;
import '../../util/HttpUtil.dart';

/// 客户端语言选择列表
List<Map<String,String>> _languageSelectList = new List<Map<String,String>>();
/// 未选择语言时客户端的默认语言配置
Map<String,int> _defaultLanguageMap = new Map<String,int>();
/// 存放所有的语言翻译信息
Map<String,String> _languageMap = new Map<String,String>();
/// 临时存放语言列表拉取的所有内容的文件夹
String _languageFileTempFolder;
/// 打包时，打进来的语言列表文件存放文件夹
String _languageFileBuiltInFolder;

/// 初始化默认语言列表和语言选择列表
/// languageSelectList：语言选择列表
/// defaultLanguageList：默认语言对照表
Future<bool> init(List languageSelectList, List defaultLanguageList) async {
  _languageFileBuiltInFolder = GlobalContext.getAppRootFolder()+"/BuiltIn/language";
  _languageFileTempFolder = _languageFileBuiltInFolder+"/temp";

  //语言选择列表初始化
  if(null != languageSelectList){
    List<Map<String,String>> languageSelectListTemp = new List<Map<String,String>>();
    for(var item in languageSelectList){
      if(null != item && item["value"] != null){
        Map<String,String> temp = new Map<String,String>();
        temp["languageId"] = item["value"];
        temp["name"] = item["name"];
        languageSelectListTemp.add(temp);
      }
    }
    _languageSelectList = languageSelectListTemp;
  }
  //默认语言初始化
  if(null != defaultLanguageList){
    Map<String,int> defaultLanguageMapTemp = new Map<String,int>();
    for(var item in defaultLanguageList){
      if(null != item && item["value"] != null){
        defaultLanguageMapTemp[item["key"]] = int.parse(item["value"]);
      }
    }
    _defaultLanguageMap = defaultLanguageMapTemp;
  }

  /// 设置默认语言
  if(GlobalContext.getLanguageId() == null){
    GlobalContext.setLanguageId(getLanguageId(languageCode:GlobalContext.getLanguageCode()));
  }
  //语言必须初始化成功
  if(null == GlobalContext.getLanguageId()){
    return false;
  }

  //初始化语言国际化翻译列表
  if(await reloadLanguageList(GlobalContext.getLanguageId()) == 0){
    return false;
  }
  return true;
}

/// 初始化语言相关
/// 返回结果：0:初始化失败，1：初始化成功，2：初始化成功，需要后续检查版本更新
Future<int> reloadLanguageList(int languageId) async{
  String tempFile = "${_languageFileTempFolder}/${languageId}";
  //从临时文件里读取的配置
  String languageData = await MyFile.readAll(tempFile);
  if(null == languageData || languageData.length <= 0){
    //如果临时文件没有，从内置文件里获取
    String languageFileBuiltInData = await MyFile.readAll("${_languageFileBuiltInFolder}/${languageId}");
    if(null != languageFileBuiltInData && languageFileBuiltInData.length > 0){
      languageData = languageFileBuiltInData;
      await MyFile.reWrite(tempFile, languageData);
    }
  }
  if(null != languageData && languageData.length > 0){
    if(_setLanguageList(languageData)){
      GlobalContext.setLanguageId(languageId);
      return 2;
    }
  }
  //同步更新allsetting数据
  return await _reloadLanguageListFromWeb(languageId)?1:0;
}

/// 重置所有语言包内容
Future<bool> resetLanguageList(int languageId) async{
  //重置给定语言包，删除其他所有语言包
  List<String> list = new List<String>();
  list.add("${_languageFileTempFolder}/${languageId}");
  await MyFile.deleteFile(_languageFileTempFolder, retainList:list);
  return await _reloadLanguageListFromWeb(languageId);
}

/// 获取语言选择列表
String  getValueByKey(String key){
  return _languageMap[key];
}

/// 获取用户当前使用的语言id
int getLanguageId({String languageCode}){
  //Abic1111111此处有待完善，从本地数据库中读取历史用过的语言是什么
  //省略读取本地数据库代码。。。。。。。。。。
  //等有了用户自己选择语言后。记录了用户的选择，再完成这里代码

  //如果本地数据库没有，获取一个默认语言
  int language = _getDefaultLanguageId(languageCode:languageCode);
  //返回null，未找到语言设置
  return language;
}

/// 从网络重新加载初始化语言包
Future<bool> _reloadLanguageListFromWeb(int languageId) async{
  String languageData = await _getLanguageFromWeb(languageId);
  if(null != languageData && languageData.length > 0){
    bool b = _setLanguageList(languageData);
    if(b){
      GlobalContext.setLanguageId(languageId);
      await MyFile.reWrite("${_languageFileTempFolder}/${languageId}", languageData);
    }
    return b;
  }
  return false;
}

/// 获取默认的语言id
int _getDefaultLanguageId({String languageCode}){
  // 是否有匹配语言
  if(null != languageCode){
    if(_defaultLanguageMap.containsKey(languageCode)){
      return _defaultLanguageMap[languageCode];
    }
  }
  // 是否有默认语言
  if(_defaultLanguageMap.containsKey("default_language")){
    return _defaultLanguageMap["default_language"];
  }
  //返回null，未找到语言设置
  return null;
}

/// 从网络获取语言列表
Future<String> _getLanguageFromWeb(int languageId) async{
   Map results =  await HttpUtil.doHttpByKey(
    InterfaceConfig.setting_interface_groupKey,
    InterfaceConfig.setting_getLanguageBunle_Key,
     null);
  return results['results'];
}

/// 从字符串重新解析加载初始化语言包
bool _setLanguageList(String languageData){
  List languageList;
  try{
    if(null != languageData && languageData.length > 0){
      Map c = Convert.jsonDecode(languageData)["c"];
      if(null != c && c.containsKey("node")){
        languageList = c["node"];
      }
    }
  }catch(e){
    print(e);
  }
  if(null != languageList){
    for(var item in languageList){
      if(null != item){
        _languageMap[item["key"]] = item["value"];
      }
    }
    return true;
  }
  return false;
}