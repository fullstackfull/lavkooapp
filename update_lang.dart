import 'dart:io';
import 'dart:convert';

void main() {
  void update(String path) {
    var file = File(path);
    if (!file.existsSync()) return;
    String content = file.readAsStringSync();
    var jsonMap = jsonDecode(content) as Map<String, dynamic>;
    
    jsonMap['order_details'] = path.contains('ar.json') ? 'تفاصيل الطلب' : 'Order Details';
    jsonMap['personal_info'] = path.contains('ar.json') ? 'المعلومات الشخصية' : 'Personal Info';
    
    file.writeAsStringSync(jsonEncode(jsonMap));
  }
  
  update('assets/language/ar.json');
  update('assets/language/en.json');
  update('assets/language/bn.json');
  update('assets/language/es.json');
  update('assets/language/hi.json');
}
