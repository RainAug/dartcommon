Map<String, Map<String, Map<String, Object>>> _servierListMap = new Map<String, Map<String, Map<String, Object>>>();

bool init(List servierList) {
  Map<String, Map<String, Map<String, Object>>> servierListMapTemp = new Map<String, Map<String, Map<String, Object>>>();
  for(var serverGroup in servierList){
    String groupKey = serverGroup["key"];
    Map<String, Map<String, Object>> groupTempMap = servierListMapTemp[groupKey];
    if (null == groupTempMap) {
      groupTempMap = new Map<String, Map<String, Object>>();
      servierListMapTemp[groupKey] = groupTempMap;
    }
    List nodes = serverGroup["node"];
    if (null != nodes && nodes.length > 0) {
      for (var node in nodes) {
        String host = node["value"];
        if(null != host && host.length > 0){
          Map<String, Object> server = new Map<String, Object>();
          server["host"] = host;
          server["name"] = node["name"];
          groupTempMap[server["host"]] = server;
        }
      }
    }
  }
  _servierListMap = servierListMapTemp;
  return true;
}

String getHost(String serverGroupKey){
  if(_servierListMap.containsKey(serverGroupKey)){
    Map<String, Map<String, Object>> map = _servierListMap[serverGroupKey];
    for(var key in map.keys){
      return map[key]["host"];
    }
  }
  return null;
}