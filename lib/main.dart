import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


const request = "https://api.hgbrasil.com/finance?format=json-cors&key=e2a6237c";

void main() {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(hintColor: Colors.amber, primaryColor: Colors.amber),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos = 0;
  TextEditingController _todoController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _readData().then((data){
      setState((){
        _todoList = json.decode(data);
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    Scaffold screen = Scaffold(
      appBar: AppBar(),
      body: Column(children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
          child: Row(children: <Widget>[
          Expanded(
            child: TextField(
              controller: _todoController,
              decoration: const InputDecoration(
                labelText: "Nova Tarefa",
                labelStyle: TextStyle(color: Colors.blueAccent)
              ),
            )
          ),
          ElevatedButton(onPressed: addTodo, child: Text("ADD"))
        ],)),
        Expanded(child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: EdgeInsets.only(top: 10),
            itemCount: _todoList.length,
            itemBuilder: buildItem
          )
          ))
      ]),
    );

    return screen;
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), 
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c){
          checkTodo(index, c);
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida."),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<String> _readData() async {
    final file = await _getFile();
    return file.readAsString();
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a,b){
        if(a["ok"] && !b["ok"])
          return 1;
        else if(!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

     _saveData();
    });
  }

  void addTodo(){
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      _todoController.text = "";
      newTodo["ok"] = false;
      _todoList.add(newTodo);
      _saveData();
    });
  }

  Future<File> _saveData() async{
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  void checkTodo(index, c) {
    setState(() {
      _todoList[index]["ok"] = c;
      _saveData();
    });
  }
}