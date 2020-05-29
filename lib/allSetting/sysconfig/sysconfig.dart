import 'package:dartcommon/allsetting/language/language.dart' as Language;

Future<bool> init(Map configMap) async {
  List _languageSelectList;
  List _defaultLanguageList;
  List _configList = configMap["child"];
  for(var _config in _configList){
    if("language" == _config["key"]){
      _defaultLanguageList = _config["node"];
    }else if("language_select_list" == _config["key"]){
      _languageSelectList = _config["node"];
    }
  }
  bool initLanguage = await Language.init(_languageSelectList, _defaultLanguageList);

  return initLanguage;
}
