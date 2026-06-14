import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lobmindergo/models/cron.dart';
import 'package:lobmindergo/models/task_model.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  static const String _graphqlUrl =
      'https://graphql-api-theta.vercel.app/graphql';

  List<Cron> _cronList = [];
  Cron? _currentCron;
  List<Map<String, dynamic>> _projects = [];

  List<Cron> get cronList => _cronList;
  Cron? get currentCron => _currentCron;
  List<Map<String, dynamic>> get projects => _projects;

  Future<void> initialize() async {
    await fetchCrons(limit: 20);
    await fetchProjects();
  }

  Future<void> fetchCrons({int limit = 20}) async {
    const query = r'''
      query Crons($limit: Int!) {
        crons(limit: $limit) {
          date
          id
          name
        }
      }
    ''';

    try {
      final result = await _executeQuery(query, {'limit': limit}, 'Crons');
      final cronsData = result['crons'] as List;
      _cronList = cronsData.map((cron) => Cron.fromJson(cron)).toList();
      if (_cronList.isNotEmpty && _currentCron == null) {
        _currentCron = _cronList.first;
      }
    } catch (e) {
      print('Error fetching crons: $e');
    }
  }

  Future<Cron?> fetchCronById(String cronId) async {
    const query = r'''
      query Cron($cronId: ID!) {
        cron(id: $cronId) {
          date
          id
          name
          tasks {
            description
            hour
            minute
            id
            project {
              id
              name
            }
            state
            __typename
          }
          __typename
        }
      }
    ''';

    try {
      final result = await _executeQuery(query, {'cronId': cronId}, 'Cron');
      final cronData = result['cron'];
      if (cronData != null) {
        final tasks = cronData['tasks'] as List?;
        if (tasks != null) {
          for (var task in tasks) {
            print('Task from API: ${task['id']} - state: ${task['state']}');
          }
        }
        _currentCron = Cron.fromJson(cronData);
        return _currentCron;
      }
    } catch (e) {
      print('Error fetching cron by id: $e');
    }
    return null;
  }

  Future<void> fetchProjects() async {
    const query = r'''
      query Projects {
        projects {
          name
          id
        }
      }
    ''';

    try {
      final result = await _executeQuery(query, {}, 'Projects');
      final projectsData = result['projects'] as List?;
      _projects =
          projectsData?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
      print('Loaded ${_projects.length} projects: $_projects');
    } catch (e) {
      print('Error fetching projects: $e');
    }
  }

  Future<bool> createTask(
    String cronogramaId,
    String description,
    int hour,
    int minute,
    Map<String, dynamic> project,
  ) async {
    const mutation = r'''
      mutation CreateTask($cronogramaId: String!, $task: EditTaskInput!) {
        createTask(cronograma_id: $cronogramaId, task: $task)
      }
    ''';

    try {
      final result = await _executeMutation(mutation, {
        'cronogramaId': cronogramaId,
        'task': {
          'description': description,
          'hour': hour,
          'minute': minute,
          'project': project,
        },
      }, 'CreateTask');
      return result['createTask'] == 'OK';
    } catch (e) {
      print('Error creating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    const mutation = r'''
      mutation RemoveTask($removeTaskId: ID!) {
        removeTask(id: $removeTaskId)
      }
    ''';

    try {
      final result = await _executeMutation(mutation, {
        'removeTaskId': taskId,
      }, 'RemoveTask');
      return result['removeTask'] == 'OK';
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  Future<bool> updateTaskState(String taskId, bool completed) async {
    const mutation = r'''
      mutation EditTask($editTaskId: ID!, $task: EditTaskInput!) {
        editTask(id: $editTaskId, task: $task)
      }
    ''';

    try {
      final result = await _executeMutation(mutation, {
        'editTaskId': taskId,
        'task': {'state': completed},
      }, 'EditTask');
      return result['editTask'] == 'OK';
    } catch (e) {
      print('Error updating task state: $e');
      return false;
    }
  }

  Future<bool> editTask(
    String taskId,
    String description,
    int hour,
    int minute,
    Map<String, dynamic> project,
  ) async {
    const mutation = r'''
      mutation EditTask($editTaskId: ID!, $task: EditTaskInput!) {
        editTask(id: $editTaskId, task: $task)
      }
    ''';

    try {
      final result = await _executeMutation(mutation, {
        'editTaskId': taskId,
        'task': {
          'description': description,
          'hour': hour,
          'minute': minute,
          'project': project,
        },
      }, 'EditTask');
      return result['editTask'] == 'OK';
    } catch (e) {
      print('Error editing task: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _executeQuery(
    String query,
    Map<String, dynamic> variables, [
    String? operationName,
  ]) async {
    final requestBody = {
      'operationName': operationName ?? 'Query',
      'variables': variables,
      'query': query,
    };
    print('>>> GraphQL Query Request');
    print('URL: $_graphqlUrl');
    print('Body: ${jsonEncode(requestBody)}');

    final headers = {'Content-Type': 'application/json'};
    final response = await http.Client().post(
      Uri.parse(_graphqlUrl),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('<<< GraphQL Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        final errorMsg = data['errors'][0]['message'];
        print('GraphQL Error: $errorMsg');
        throw Exception('GraphQL Error: $errorMsg');
      }
      return data['data'];
    } else {
      print('Response: ${response.statusCode} - ${response.body}');
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> _executeMutation(
    String mutation,
    Map<String, dynamic> variables, [
    String? operationName,
  ]) async {
    final opName = operationName ?? 'Mutation';
    final requestBody = {
      'operationName': opName,
      'variables': variables,
      'query': mutation,
    };
    print('>>> GraphQL Mutation: $opName');
    print('URL: $_graphqlUrl');
    print('Body: ${jsonEncode(requestBody)}');

    final headers = {'Content-Type': 'application/json'};
    final response = await http.Client().post(
      Uri.parse(_graphqlUrl),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('<<< GraphQL Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        final errorMsg = data['errors'][0]['message'];
        final locations = data['errors'][0]['locations'];
        final path = data['errors'][0]['path'];
        throw Exception(
          'GraphQL Error: $errorMsg\nLocations: $locations\nPath: $path\nResponse: ${response.body}',
        );
      }
      return data['data'];
    } else {
      throw Exception(
        'HTTP Error: ${response.statusCode}\nResponse: ${response.body}\nMutation: $mutation\nVariables: $variables',
      );
    }
  }
}
