import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_nats/dart_nats.dart';
import 'package:test/test.dart';

import 'model/student.dart';

void main() {
  group('all', () {
    test('string to string', () async {
      var client = Client();

      await client.connect(Uri.parse('nats://localhost:4222'),
          retryInterval: 1);
      var sub = client.sub<String>('subject1', jsonConverter: string2string);
      client.pub('subject1', Uint8List.fromList('message1'.codeUnits));
      var msg = await sub.stream.first;
      await client.close();
      expect(msg.data, equals('message1'));
    });

    test('sub', () async {
      var client = Client();
      await client.connect(Uri.parse('nats://localhost:4222'),
          retryInterval: 1);
      var sub = client.sub<Student>('subject1', jsonConverter: josn2Student);
      var student = Student('id', 'name', 1);
      client.pubString('subject1', jsonEncode(student.toJson()));
      var msg = await sub.stream.first;
      await client.close();
      expect(msg.data.id, student.id);
      expect(msg.data.name, student.name);
      expect(msg.data.score, student.score);
    });
    test('sub no type', () async {
      var client = Client();
      await client.connect(Uri.parse('nats://localhost:4222'),
          retryInterval: 1);
      var sub = client.sub('subject1', jsonConverter: josn2Student);
      var student = Student('id', 'name', 1);
      client.pubString('subject1', jsonEncode(student.toJson()));
      var msg = await sub.stream.first;
      await client.close();
      expect(msg.data.id, student.id);
      expect(msg.data.name, student.name);
      expect(msg.data.score, student.score);
    });
    test('sub no type no converter', () async {
      var client = Client();
      await client.connect(Uri.parse('nats://localhost:4222'),
          retryInterval: 1);
      var sub = client.sub('subject1');
      var student = Student('id', 'name', 1);
      client.pubString('subject1', jsonEncode(student.toJson()));
      var msg = await sub.stream.first;
      await client.close();
      if (!(msg.data is Uint8List)) {
        throw Exception('missing data type');
      }
    });
    test('resquest', () async {
      var server = Client();
      await server.connect(Uri.parse('nats://localhost:4222'));
      var service = server.sub<Student>('service', jsonConverter: josn2Student);
      unawaited(service.stream.first.then((m) {
        m.respondString(jsonEncode(m.data.toJson()));
      }));

      var client = Client();
      var s1 = Student('id', 'name', 1);
      await client.connect(Uri.parse('ws://localhost:8080'));
      var receive =
          await client.requestString('service', jsonEncode(s1.toJson()));
      var s2 = Student.fromJson(jsonDecode(receive.string));
      await client.close();
      await server.close();
      expect(s1.score, equals(s2.score));
    });
  });
}

String string2string(String input) {
  return input;
}

Student josn2Student(String json) {
  var map = jsonDecode(json);
  return Student.fromJson(map);
}
