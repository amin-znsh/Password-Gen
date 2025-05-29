import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('en');

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'en' ? Locale('fa') : Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpha',
      locale: _locale,
      supportedLocales: [Locale('en'), Locale('fa')],
      home: PasswordGenerator(toggleLanguage: _toggleLanguage),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PasswordGenerator extends StatefulWidget {
  final VoidCallback toggleLanguage;

  PasswordGenerator({required this.toggleLanguage});

  @override
  _PasswordGeneratorState createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  String _password = '';
  List<String> _history = [];
  List<Map<String, String>> _savedCredentials = [];
  int _length = 12;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadSavedCredentials();
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random rnd = Random();
    String result = String.fromCharCodes(
      Iterable.generate(
        _length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );

    setState(() {
      _password = result;
      _history.add(result);
      _saveHistory();
    });
  }

  void _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('history', _history);
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('history') ?? [];
    });
  }

  void _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('history');
    setState(() {
      _history.clear();
    });
  }

  void _saveCredential() async {
    String encoded = base64.encode(
      utf8.encode('${_usernameController.text}:${_passwordController.text}'),
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedCredentials.add({
        'username': _usernameController.text,
        'password': encoded,
      });
      prefs.setString('credentials', jsonEncode(_savedCredentials));
    });
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('credentials');
    setState(() {
      _savedCredentials = List<Map<String, String>>.from(jsonDecode(data));
    });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Alpha Password Generator',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            onPressed: widget.toggleLanguage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Generated Password:', style: TextStyle(fontSize: 18)),
            SelectableText(
              _password,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _length.toDouble(),
                    min: 8,
                    max: 64,
                    divisions: 56,
                    label: _length.toString(),
                    onChanged: (value) {
                      setState(() {
                        _length = value.toInt();
                      });
                    },
                  ),
                ),
                Text('${_length}'),
              ],
            ),
            ElevatedButton(
              onPressed: _generatePassword,
              child: Text('Generate Password'),
            ),
            Divider(),
            Text('History:', style: TextStyle(fontSize: 18)),
            ..._history.reversed.map((pwd) => ListTile(title: Text(pwd))),
            ElevatedButton(
              onPressed: _clearHistory,
              child: Text('Clear History'),
            ),
            Divider(),
            Text('Save Username & Password:', style: TextStyle(fontSize: 18)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _saveCredential,
              child: Text('Save Credential'),
            ),
            Divider(),
            Text('Saved Credentials:', style: TextStyle(fontSize: 18)),
            ..._savedCredentials.map((cred) {
              String decoded = utf8.decode(base64.decode(cred['password']!));
              return ListTile(
                title: Text(cred['username']!),
                subtitle: Text(decoded.split(':')[1]),
              );
            }),
          ],
        ),
      ),
    );
  }
}
