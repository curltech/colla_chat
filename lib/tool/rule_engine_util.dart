import 'package:drules/drules.dart';
import 'package:template_expressions/template_expressions.dart';

class RuleEngineUtil {
  /// 运行规则集
  // 规则是json格式，有以下字段组成：
  // id: 唯一编号，可以不提供
  // name: 名称，可以不提供
  // priority: 优先级，缺省0
  // enabled: 缺省true.
  // conditions: 规则
  //    operator: 运算符，==,!=,>,<,>=,<=,all,any,contains,startsWith,endsWith,matches,expression
  //    operands：运算子, ["age", 18]
  // 如果幺使用对象，则使用MemberAccessor数组，MemberAccessor的模版参数是类
  // MemberAccessor<Counter>({
  //         'value': (c) => c.value,
  //         'increment': (c) => c.increment,
  //     }),
  // context.addFact('counter', Counter(2));
  // {
  //     "operator": "expression",
  //     "operands": ["counter.value == 2"]
  // }
  // 自定义条件：ruleEngine.registerCondition(CustomCondition('isEven', (operands, context) {
  //     return operands[0] % 2 == 0;
  // }));
  // actionInfo: 行为信息，包含以下属性：
  // onSuccess: 规则成功的行为
  //    operation: 成功执行的行为，print,expression,stop,chain,parallel,pipe
  //    parameters: 参数
  // onFailure: 规则失败的行为
  //    operation: 失败执行的行为
  //    parameters: 参数
  // expression行为
  // {
  //     "operation": "expression",
  //     "parameters": ["counter.increment()"]
  // }
  // 自定义行为：ruleEngine.registerAction(CustomAction('log', (parameters, context) {
  //     print(parameters[0]);
  // }));
  // 加事件监听器：ruleEngine.addListener((event) {
  //     print(event);
  // });
  // ruleEngine + print;
  static Future<void> run(List<String> rules, Map<String, dynamic> facts,
      {List<MemberAccessor<dynamic>> resolve = const []}) async {
    var ruleRepository = StringRuleRepository(rules);
    var ruleEngine = RuleEngine(ruleRepository);

    var context = RuleContext(resolve: resolve);
    for (var entry in facts.entries) {
      String key = entry.key;
      dynamic value = entry.value;

      context.addFact(key, value);
    }

    return await ruleEngine.run(context);
  }
}
