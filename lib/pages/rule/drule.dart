/// "onSuccess": {
//                 "operation": "print",
//                 "parameters": ["You are an adult"]
//             }
class ActionInfo {
  late Map<String, dynamic> onSuccess;
  Map<String, dynamic>? onFailure;

  ActionInfo(String operation, List<dynamic> parameters,
      {String? failureOperation, List<dynamic>? failureParameters}) {
    onSuccess = {"operation": operation, "parameters": parameters};
    if (failureOperation != null && failureParameters != null) {
      onFailure = {
        "operation": failureOperation,
        "parameters": failureParameters
      };
    }
  }

  ActionInfo.fromJson(Map<String, dynamic> json)
      : onSuccess = json['onSuccess'],
        onFailure = json['onFailure'];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json.addAll({
      'onSuccess': onSuccess,
      'onFailure': onFailure,
    });
    return json;
  }
}

/// "conditions": {
//               "operator": "expression",
//               "operands": ["email.subject.contains('Hello')"]
//             }
class Drule {
  String? id;
  String? name;
  int priority;
  bool enabled;
  late Map<String, dynamic> conditions;
  ActionInfo actionInfo;

  Drule(String operator, List<dynamic> operands, this.actionInfo,
      {this.id, this.name, this.priority = 0, this.enabled = true}) {
    conditions = {'operator': operator, 'operands': operands};
  }

  Drule.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        priority = json['priority'],
        enabled = json['enabled'],
        conditions = json['conditions'],
        actionInfo = json['actionInfo'];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json.addAll({
      'id': id,
      'name': name,
      'priority': priority,
      'enabled': enabled,
      'conditions': conditions,
      'actionInfo': actionInfo,
    });
    return json;
  }
}
