import 'package:http/http.dart' as Http;
import 'package:dartcommon/allsetting/servers/servers.dart' as Servers;
import 'package:dartcommon/allsetting/interfaces/interfaces.dart' as Interfaces;
import 'package:dartcommon/allsetting/language/language.dart' as language;
import 'package:dartcommon/src/global_context.dart' as global_context;
import 'dart:convert' as convert;
import 'package:dartcommon/util/tool.dart' as tool;

class HttpUtil{
  /*
 * http请求 通过key
 * 系统错误返回-1
 * 正常返回结果为：接口成功 {flag: 1, result: {s: 008fG0900a2, c: {uid: 1578127134000800001, initInfo: false, token: PdXHPzXPG5fffHffffPBPdXHzPH6555zRB6dfRdzfdRX56XfPRBPfHd6d5-PUBLIC}}}
 * 正常返回结果为：接口失败 {message: 用户不存在或非法用户id！, flag: 0, result: {s: 008fG1j0156, c: }}
 * flag：1:成功  0:失败  -1:系统异常    message:flag为0时，此为错误信息   result：接口返回结果
 */
static Future<Object> doHttpByKey (String interfaceGroupKey,String interfaceKey,Map parameters)async{
  if(parameters == null){
      parameters = Map();
  }
  //获取公共参数
  Map<String,Object> common = global_context.getCommon();
   //通过interfaceKey去取接口信息
  Map<String, Object> interfaceMessage = Interfaces.getInterface(interfaceGroupKey, interfaceKey);
  String serverKey = interfaceMessage['serverKey'];
  //通过serverKey去取域名
  String server = Servers.getHost(serverKey);
  //url后半截
  String suffixUrl = interfaceMessage['value'].toString();
  //返回的失败统一标识
  int errCode = -1;
  //返回结果
  Map<String,Object> resultMap = Map<String,Object>();

  //url校验
  if(server == null || server.isEmpty || suffixUrl == null || suffixUrl.isEmpty){
    resultMap['flag'] = errCode;
    return resultMap;
  }
  List<String> pathArg = suffixUrl.split('?');
  //url前半截和后半截转换方法不同，前半截直接替换，后半截拆分，有没取到值的参数key也去掉
  String realPath = pathReplaceAgrs(pathArg[0],parameters,common);
  String realParameters = '';

  if(pathArg.length>1){
    //获取需要的全部真实参数
    realParameters = replaceArgToString(pathArg[1],parameters,common);//会把没有值的key去掉
  }
  //http返回值
  var result;
  try {
    if(interfaceMessage['http_method'].toString() == '0'){//get请求
      result = await get(server+realPath,realParameters);
    }else{
      if(interfaceMessage['http_encrypt'].toString() != '0'){//参数是否加密
          return '需要加密';
      }
      result = await post(server+realPath,realParameters);
    }
  }catch(e){
    print('url可能配置不正确,请求失败:请求url为：$interfaceMessage:'+e.toString());
    resultMap['flag'] = errCode;
    return resultMap;
  }
  if(result.statusCode != 200){
    print('${pathArg[0]}:接口返回状态码为：'+result.statusCode.toString());
    resultMap['flag'] = errCode;
    return resultMap;
  }

  if(result.body !=null && result.body!=''){
    try {
      var resultJson = convert.json.decode(result.body);
      Map<String,Object> returnMap = resultAsnalysis(resultJson,resultMap);
      return returnMap;
    } catch (e) {
      return result.body;
    }
  }else{ //如果接口返回空，则返回错误            
    resultMap['flag'] = errCode;
    return resultMap;
  }
}
/*
 * 获取完整的url;一般是获取html的url
 */
static String getWholeUrl(String serverKey,String interfaceGroupKey,String interfaceKey,Map parameters){
   //获取公共参数
  Map<String,Object> common = global_context.getCommon();
  //通过serverKey去取域名
  String server = Servers.getHost(serverKey);
  //通过interfaceKey去取接口信息
  Map<String, Object> interfaceMessage = Interfaces.getInterface(interfaceGroupKey, interfaceKey);
  //url后半截
  String suffixUrl = interfaceMessage['value'].toString();

  //url校验
  if(server == null || server.isEmpty || suffixUrl == null || suffixUrl.isEmpty){
    return '-1';
  }
  List<String> pathArg = suffixUrl.split('?');
  //url前半截和后半截转换方法不同，前半截直接替换，后半截拆分，有没取到值的参数key也去掉
  String realPath = pathReplaceAgrs(pathArg[0],parameters,common);
  String realParameters = '';
  if(pathArg.length>1){
    //获取需要的全部真实参数
    realParameters = replaceArgToString(pathArg[1],parameters,common);//会把没有值的key去掉
  }
  return server+realPath+'?'+realParameters;
}

/*
 * get请求,通过key调用
 */
static get(String url,String parameters) async{
  print('get11111111111:'+url+'?'+parameters);
  var results = await Http.get(url+'?'+parameters);
  return results;
}

/*
 * post请求请求,通过key调用
 */
 static post(String url,String parameters) async{
  print('post url1:'+url);
  print('post url2:'+parameters.toString());
  var results = await Http.post(url,body: parameters);
  return results;
}

/*
 * get请求替换url真实参数
 */
static String replaceArgToString(String args,Map parameters,Map<String,Object> common){
  //加了{}的旧参数map
  Map<String,Object> newParameters = Map<String,Object>();
  //给parameters key加上{}
  parameters.forEach((k,v){
    newParameters['\${$k}'] = v;
  });
  StringBuffer buffer = StringBuffer();
  List<String> keyValues = args.split('&');
  //拼接参数
  keyValues.forEach((keyValueStr){
    List<String> keyValue = keyValueStr.split("=");
    if(keyValue.length > 1){
      String key = keyValue[0];
      String value = keyValue[1];
      if(newParameters[value] != null){
        buffer.write('$key=${Uri.encodeComponent(newParameters[value])}&');
      }else{
        if(value.indexOf('\${')==-1){
            buffer.write('$key=$value&');
        }else{
          if(common[key] != null){
            buffer.write('$key=${Uri.encodeComponent(common[key].toString())}&');
          }
        }
      }
    }else{
      if(keyValueStr != null && keyValueStr !=''){
         String arg = keyValueStr.substring(2,keyValueStr.length-1);
         if(arg == '__random'){
           String random = tool.getMilliseconds();
           buffer.write('$random');
         }
      }
    }
  });
  return buffer.toString();
}

/*
 * 根据url占位符取到真实、完整参数map
 */
static Map<String,String> getCompleteArg(String args,Map parameters,Map<String,Object> common){
  //要返回的真实参数
  Map<String,String> realParameters = Map<String,String>();
  //加了{}的旧参数map
  Map<String,Object> newParameters = Map<String,Object>();
  //给parameters key加上{}
  parameters.forEach((k,v){
    newParameters['\${$k}'] = v;
  });
  List<String> keyValues = args.split('&');
    //拼接参数
  keyValues.forEach((String keyValueStr){
      if(keyValueStr != null && keyValueStr != ''){
        if(keyValueStr.indexOf('=')!=-1){
          List<String> keyValue = keyValueStr.split("=");
          String key = keyValue[0];
          String value = keyValue[1];
          if(newParameters[value] != null){
            realParameters[key] = newParameters[value].toString();
          }else{
            if(value.indexOf('\${')==-1){
                realParameters[key] = value;
            }else{
              if(common[key] != null){
              realParameters[key] = common[key].toString();
              }
            }
          }
        }else{
          String arg = keyValueStr.substring(2,keyValueStr.length-1);
          if(arg == '__random'){
            realParameters[arg] = tool.getMilliseconds(); 
          }
        }
        
      }
    });
  return realParameters;
}

/*
 * 返回结果解析
 */
static Map<String,Object> resultAsnalysis(var result,Map<String,Object> resultMap){
  if(result == null || result == ''){//如果返回为空，则flag为-1
    resultMap['flag'] = -1;
    return resultMap;
  }
  //返回数据解析
  String s = result['s'];
  var c = result['c'];
  //判断返回码是否错误  flag:1:成功  0:失败  -1:系统异常
  String endCode = s.substring(s.length-2);
  int flag = 0;
  List<int> units = endCode.codeUnits;
  if(endCode == '00'){//00 (00~0^) 底层占用【00成功，其他都为失败】
      flag = 1;
  }
  if(units[0]>=49 && units[0]<=52){//10 (10~4^) 通用成功
      flag = 1;
  }
  if(units[0]>=97 && units[0]<=122){//a0 (a0~z^) 自定义成功
      flag = 1;
  }
  //如果错误则去获取翻译
  if(flag == 0){
    String message = language.getValueByKey(s.substring(s.length-6));
    if(message == null){
        message = language.getValueByKey(s.substring(s.length-4));
    }
    if(message == null){
        message = language.getValueByKey(s.substring(s.length-2));
    }
    resultMap['message'] = message;
  }
  // resultMap
  resultMap['flag'] = flag;
  resultMap['result'] = result;
  return resultMap;
}

/*
 * 替换路径重的占位符
 */
static String pathReplaceAgrs(String oldUrl,Map parameters,Map<String,Object> common){
  String url = oldUrl;
  for(int a=0;a<4;a++){
    if(url.indexOf('\${')!=-1){
      int flag = 0;
      int tempFlag = 0;
      StringBuffer result = new StringBuffer();
      StringBuffer buffer = new StringBuffer();
      for (int n = 0; n < url.length; n++) {
        if(url[n] == '\$'){
          flag = 1;
          tempFlag = tempFlag+1;
        }
        if(tempFlag >= 2){
          result.write(buffer);
          buffer = new StringBuffer();
          tempFlag = 1;
        }
        if(flag == 1){
          buffer.write(url[n]);
        }
        if(url[n] == '}' && tempFlag == 1){
          flag = 0;
          tempFlag = 0;
          String key = buffer.toString().substring(2,buffer.length-1);
          if(parameters[key] != null){
            result.write(parameters[key]);
          }else if(common[key] != null){
            result.write(common[key]);
          }else{
            result.write('');
          }
          buffer = new StringBuffer();
        }else if(flag == 0){
          result.write(url[n]);
        }
      }
          url = result.toString();
    }else{
      break;
    }
  }
  return url;
}
}
