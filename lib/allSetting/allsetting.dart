import 'interfaces/interfaces.dart' as Interfaces;
import 'servers/servers.dart' as Servers;
import 'sysconfig/sysconfig.dart' as SysConfig;
import 'package:allsetting/src/myfile.dart' as MyFile;
import 'language/language.dart' as Language;
import 'package:allsetting/src/global_context.dart' as GlobalContext;
import 'dart:convert' as convert;
import 'package:allsetting/util/HttpUtil.dart';
import 'package:allsetting/config/interfaceConfig.dart' as InterfaceConfig;
import 'package:allsetting/src/model/common.dart' as Common;

String _allSettingFile;
String _allSettingFileBuiltIn;
String _allSettingVersionFile;

/// 初始化Setting服务
Future<bool> init(String appRootFolder, {int softwareVersion, String language, int languageId, String deviceOSType, String deviceOSVersion, String deviceType, String chipType, String manufacturer, String channel, int areaCode, int platform, String osSdkVersion, String imei, int sdkVersion, String uid}) async {
  //初始化comon信息
  Map<String,Object> _common = new  Map<String,Object>();
  _common["softwareVersion"] = softwareVersion ?? Common.softwareVersion; // int
  _common["language"] = language ?? Common.language;
  _common["languageId"] = languageId ?? Common.languageId; // int
  _common["deviceOSType"] = deviceOSType ?? Common.deviceOSType;
  _common["deviceOSVersion"] = deviceOSVersion ?? Common.deviceOSVersion;
  _common["deviceType"] = deviceType ?? Common.deviceType;
  _common["chipType"] = chipType ?? Common.chipType;
  _common["manufacturer"] = manufacturer ?? Common.manufacturer;
  _common["channel"] = channel ?? Common.chipType;
  _common["areaCode"] = areaCode ?? Common.areaCode; // int
  _common["platform"] = platform ?? Common.platform; // int
  _common["osSdkVersion"] = osSdkVersion ?? Common.osSdkVersion;
  _common["imei"] = imei;
  _common["sdkVersion"] = sdkVersion ?? Common.softwareVersion;// int
  _common["uid"] = uid;// 这里用的是String不是long
  GlobalContext.setCommon(_common);
  GlobalContext.setAppRootFolder(appRootFolder);

  String allSettingRootFolder = "${GlobalContext.getAppRootFolder()}/BuiltIn/AllSetting";
  _allSettingFile = allSettingRootFolder+"/temp/getAllSetting";
  _allSettingFileBuiltIn = allSettingRootFolder+"/getAllSetting";
  _allSettingVersionFile = allSettingRootFolder+"/getAllSettingVersion";

  //初始化AllSetting，若失败直接返回false
  int initAllSettingBack = await _initAllSetting();
  if(initAllSettingBack == 0){
    return false;
  }
  
  //版本检查
  if(initAllSettingBack == 2){
    //异步检查版本更新情况
    _checkVersion();
  }

  return true;
}

/// 初始化getAllSetting
/// 返回结果：0:初始化失败，1：初始化成功，2：初始化成功，需要后续检查版本信息
Future<int> _initAllSetting() async{
  //从临时文件里读取AllSetting的配置
  String allSettingData = await MyFile.readAll(_allSettingFile);
  if(null == allSettingData || allSettingData.length <= 0){
    //如果临时文件没有，从内置文件里获取
    String allSettingBuiltInData = await MyFile.readAll(_allSettingFileBuiltIn);
    if(null != allSettingBuiltInData && allSettingBuiltInData.length > 0){
      allSettingData = allSettingBuiltInData;
      await MyFile.reWrite(_allSettingFile, allSettingData);
    }
  }
  if(null != allSettingData && allSettingData.length > 0){
    //解析字符串并初始化相关类
    if(await  _analyzeAllSetting(allSettingData)){
      return 2;
    }
  }
  //同步更新allsetting数据
  return await _reLoadAllSettingFromWeb()?1:0;
}

/// 解析给定的getAllSetting接口字符串
Future<bool> _analyzeAllSetting(String data) async {
  try{
    var interfaceList;
    var serverList;
    var sys_config;
    List resultCJson = convert.jsonDecode(data)["c"]["child"];
    for(var item in resultCJson){
      if("interface_list" == item["key"]){
        var interfaceGroupList = item["child"];
        if(null != interfaceGroupList){
          for(var xx in interfaceGroupList){
            if("interface_list" == xx["key"]){
              interfaceList = xx["child"];
            }else if("server_list" == xx["key"]){
              serverList = xx["child"];
            }
          }
        }
      }else if("SYS_CONFIG" == item["key"]){
        sys_config = item;
      }
    }
    if(null == interfaceList || null == serverList){
      return false;
    }
    //Servers未初始化成功直接返回失败
    if(!Servers.init(serverList)){
      return false;
    }
    //接口未初始化成功直接返回失败
    if(!Interfaces.init(interfaceList)){
      return false;
    }
     //配置没有初始化成功直接返回失败
    if(!await SysConfig.init(sys_config)){
        return false;
      }
    return true;
  }catch(e){
    print(e);
  }
  return false;
}

/// 检查getAllSetting版本号是否发生变化
Future<bool> _checkVersion() async{
  bool reloadAllSetting = true;
  bool relaodLanguage = true;
  //从服务器获取allSetting版本号信息
  String allSettingVersionWebData =  await _getAllSettingVersionFromWeb();
  if(null != allSettingVersionWebData && allSettingVersionWebData.length > 0){
    String allSettingVersionData = await MyFile.readAll(_allSettingVersionFile);
    if(null != allSettingVersionData && allSettingVersionData.length > 0){
      var webJson = convert.jsonDecode(allSettingVersionWebData)["c"];
      var localJson = convert.jsonDecode(allSettingVersionData)["c"];
      if(null != webJson && null != localJson){
        if(webJson["setting_getAllSetting"] == localJson["setting_getAllSetting"]){
          reloadAllSetting = false;
        }
        if(webJson["setting_getLanguageBundle"] == localJson["setting_getLanguageBundle"]){
          relaodLanguage = false;
        }
      }
    }
  }

  // 此List不为空且全是true是更新版本文件
  List<bool> updated = new List<bool>();
  //更新allSetting
  if(reloadAllSetting){
    updated.add(await _reLoadAllSettingFromWeb());
  }
  //更新语言
  if(relaodLanguage){
    updated.add(await Language.resetLanguageList(GlobalContext.getLanguageId()));
  }
  //重新加载成功后，更改本地版本号文件
  if(updated.length > 0 && null != allSettingVersionWebData && allSettingVersionWebData.length > 0){
    if(!updated.contains(false)){
      await MyFile.reWrite(_allSettingVersionFile, allSettingVersionWebData);
    }
  }
  return true;
}

/// 从网络重新加载初始化AllSetting
Future<bool> _reLoadAllSettingFromWeb() async{
  try{
    String allSettingData = await _getAllSettingFromWeb();
    if(null != allSettingData && allSettingData.length > 0){
      bool b = await _analyzeAllSetting(allSettingData);
      if(b){
        await MyFile.reWrite(_allSettingFile, allSettingData);
      }
      return b;
    }
  }catch(e){
    print(e);
  }
  return false;
}

/// 通过接口获取getAllSetting数据
/// https://setting.tlkg.com.cn/setting/getAllSetting?softwareVersion=12&osSdkVersion=12.0&deviceOSType=ios&channel=TLKG77&&&&deviceType=iPhone
Future<String> _getAllSettingFromWeb() async{
  Map results =  await HttpUtil.doHttpByKey(
    InterfaceConfig.setting_interface_groupKey,
    InterfaceConfig.setting_getAllSetting_Key,
     null);
  return results['results'];
}

Future<String> _getAllSettingVersionFromWeb() async{
  Map results =  await HttpUtil.doHttpByKey(
    InterfaceConfig.version_control_groupKey,
    InterfaceConfig.version_control_Key,
     null);
  return results['results'];
}
