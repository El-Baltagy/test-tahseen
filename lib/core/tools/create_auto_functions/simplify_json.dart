import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('lib/core/tools/create_auto_functions/post_man_collection.json');
  final content = await file.readAsString();
  final data = json.decode(content);
  
  final newData = {
    'item': data['item']
  };
  
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(newData));
  print("Simplified JSON saved.");
}
