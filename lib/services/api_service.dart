import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:activities_notifier_app/models/cron.dart';
import 'package:activities_notifier_app/models/task_model.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  static const String _graphqlUrl =
      'https://graphql-api-theta.vercel.app/graphql';

  List<Cron> _cronList = [];
  Cron? _currentCron;

  List<Cron> get cronList => _cronList;
  Cron? get currentCron => _currentCron;

  Future<void> initialize() async {
    await fetchCrons(limit: 10);
  }

  Future<void> fetchCrons({int limit = 10}) async {
    final query = '''
      query GetCrons(\$limit: Int!) {
        crons(limit: \$limit) {
          id
          name
          date
          tasks {
            id
            description
            state
            hour
            minute
            project {
              id
              name
            }
          }
        }
      }
    ''';

    try {
      final result = await _executeQuery(query, {'limit': limit});
      final cronsData = result['crons'] as List;
      _cronList = cronsData.map((cron) => Cron.fromJson(cron)).toList();
      if (_cronList.isNotEmpty && _currentCron == null) {
        _currentCron = _cronList.first;
      }
    } catch (e) {
      print('Error fetching crons: $e');
    }
  }

  Future<Cron?> fetchCronById(String id) async {
    final query = '''
      query GetCronById(\$id: ID!) {
        cron(id: \$id) {
          id
          name
          date
          tasks {
            id
            description
            state
            hour
            minute
            project {
              id
              name
            }
          }
        }
      }
    ''';

    try {
      final result = await _executeQuery(query, {'id': id});
      final cronData = result['cron'];
      if (cronData != null) {
        _currentCron = Cron.fromJson(cronData);
        return _currentCron;
      }
    } catch (e) {
      print('Error fetching cron by id: $e');
    }
    return null;
  }

  Future<bool> updateTaskState(String taskId, bool state) async {
    final mutation = '''
      mutation EditTask(\$id: ID!, \$task: EditTaskInput!) {
        editTask(id: \$id, task: \$task)
      }
    ''';

    try {
      final result = await _executeMutation(mutation, {
        'id': taskId,
        'task': {'state': state},
      });
      return result['editTask'] == 'OK';
    } catch (e) {
      print('Error updating task state: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _executeQuery(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final response = await http.Client().post(
      Uri.parse(_graphqlUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query, 'variables': variables}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        throw Exception(data['errors'][0]['message']);
      }
      return data['data'];
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _executeMutation(
    String mutation,
    Map<String, dynamic> variables,
  ) async {
    final response = await http.Client().post(
      Uri.parse(_graphqlUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': mutation, 'variables': variables}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        throw Exception(data['errors'][0]['message']);
      }
      return data['data'];
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }
}
