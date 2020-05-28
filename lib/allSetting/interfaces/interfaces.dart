
Map<String, Map<String, Map<String, Object>>> _interfacesMap = new Map<String, Map<String, Map<String, Object>>>();

bool init(List interfaces) {
  Map<String, Map<String, Map<String, Object>>> interfacesMapTemp = new Map<String, Map<String, Map<String, Object>>>();
  for (var interfaceGroup in interfaces) {
    String groupKey = interfaceGroup["key"];
    Map<String, Map<String, Object>> groupTempMap = interfacesMapTemp[groupKey];
    if (null == groupTempMap) {
      groupTempMap = new Map<String, Map<String, Object>>();
      interfacesMapTemp[groupKey] = groupTempMap;
    }
    List nodes = interfaceGroup["node"];
    if (null != nodes && nodes.length > 0) {
      for (var node in nodes) {
        Map<String, Object> interface = new Map<String, Object>();
        interface["key"] = node["key"];
        interface["value"] = node["value"];
        interface["serverKey"] = node["extend"];
        List exts = node["ext"];
        if(null != exts && exts.length > 0){
          for(var ext in exts){
            interface[ext["key"]] = ext["value"];
          }
        }
        groupTempMap[node["key"]] = interface;
      }
    }
  }
  _interfacesMap = interfacesMapTemp;
  return true;
}

Map<String, Object> getInterface(String groupKey, String interfaceKey){
  if(_interfacesMap.containsKey(groupKey)){
    return _interfacesMap[groupKey][interfaceKey];
  }else{
    return null;
  }
}
