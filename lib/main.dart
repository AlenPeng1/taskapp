import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  DateTime _focusDate = DateTime.now();
  List<Task> tasks = [];
  List<String> presetTasks = [];
  TextEditingController presetTaskController = TextEditingController();
  TextEditingController taskController = TextEditingController();

  String? selectedPresetTask;

  @override
  Widget build(BuildContext context) {
    int incompleteTasksCount = tasks.where((task) => !task.completed).length;

    tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '$incompleteTasksCount Tasks',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              _clearAllTasks();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          EasyDateTimeLine(
            initialDate: DateTime.now(),
            onDateChange: (selectedDate) {
              setState(() {
                _focusDate = selectedDate;
              });
            },
            headerProps: const EasyHeaderProps(
              monthPickerType: MonthPickerType.switcher,
              dateFormatter: DateFormatter.fullDateDMY(),
            ),
            dayProps: const EasyDayProps(
              dayStructure: DayStructure.dayStrDayNum,
              activeDayStyle: DayStyle(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xff3371FF),
                      Color(0xff8426D6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                Color priorityColor = _getPriorityColor(task.priority);
                TextStyle taskTextStyle = TextStyle(
                  fontSize: 20,
                  color: priorityColor,
                );
                return Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (bool? value) {
                        setState(() {
                          task.completed = value!;
                          _updateTask(task); // Update task completion status
                        });
                      },
                    ),
                    title: Text(
                      '${task.date.day}/${task.date.month}/${task.date.year}: ${task.name} (${task.time})',
                      style: taskTextStyle,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: priorityColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showEditTaskDialog(context, task);
                          },
                        ),
                        if (task.completed)
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                tasks.removeAt(index);
                                _deleteTask(task); // Delete task
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  _showSettingsBottomSheet(context);
                },
                child: Icon(Icons.settings),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  _showAddTaskDialog(context);
                },
                label: Text(
                  'Add Task${selectedPresetTask != null ? " - $selectedPresetTask" : ""}',
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Preset Task Descriptions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: presetTasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(presetTasks[index]),
                      onTap: () {
                        setState(() {
                          selectedPresetTask = presetTasks[index];
                          Navigator.pop(context);
                        });
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            presetTasks.removeAt(index);
                            _updatePresetTasks(); // Update preset tasks in storage
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: presetTaskController,
                decoration: InputDecoration(
                  labelText: "New Task Description",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        presetTasks.add(presetTaskController.text);
                        _updatePresetTasks();
                        presetTaskController.clear();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    TimeOfDay? selectedTime;
    TaskPriority priority = TaskPriority.low;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPresetTask,
                onChanged: (value) {
                  setState(() {
                    selectedPresetTask = value;
                    taskController.text = value ?? '';
                  });
                },
                items: presetTasks.map((String presetTask) {
                  return DropdownMenuItem<String>(
                    value: presetTask,
                    child: Text(presetTask),
                  );
                }).toList(),
              ),
              TextField(
                controller: taskController,
                decoration: InputDecoration(labelText: 'Task name'),
              ),
              TextButton(
                onPressed: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {});
                },
                child: Text(
                  selectedTime != null
                      ? 'Selected Time: ${selectedTime!.format(context)}'
                      : 'Select Time',
                ),
              ),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                onChanged: (value) {
                  setState(() {
                    priority = value!;
                  });
                },
                items: TaskPriority.values.map((TaskPriority priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(priority.toString().split('.').last),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Add"),
              onPressed: () {
                if (selectedTime != null && taskController.text.isNotEmpty) {
                  setState(() {
                    Task task = Task(
                      name: taskController.text,
                      time: selectedTime!.format(context),
                      date: _focusDate,
                      priority: priority,
                    );
                    tasks.add(task);
                    _insertTask(task); // Insert new task
                  });
                  Navigator.of(context).pop();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Error"),
                        content: Text("Please enter a task name and select a time."),
                        actions: <Widget>[
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    TextEditingController taskController = TextEditingController(text: task.name);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.date);
    TaskPriority priority = task.priority;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(labelText: 'Task name'),
              ),
              TextButton(
                onPressed: () async {
                  selectedTime = (await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  ))!;
                  setState(() {});
                },
                child: Text(
                  'Selected Time: ${selectedTime.format(context)}',
                ),
              ),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                onChanged: (value) {
                  setState(() {
                    priority = value!;
                  });
                },
                items: TaskPriority.values.map((TaskPriority priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(priority.toString().split('.').last),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                setState(() {
                  task.name = taskController.text;
                  task.time = selectedTime.format(context);
                  task.date = _focusDate;
                  task.priority = priority;
                  _updateTask(task); // Update task
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Database> _openDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = path.join(documentsDirectory.path, 'tasks.db');
    return openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE Tasks (id INTEGER PRIMARY KEY, name TEXT, time TEXT, date TEXT, completed INTEGER, priority INTEGER)');
          await db.execute(
              'CREATE TABLE PresetTasks (id INTEGER PRIMARY KEY, name TEXT)');
        });
  }

  Future<void> _insertTask(Task task) async {
    final Database db = await _openDatabase();
    await db.insert(
      'Tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updateTask(Task task) async {
    final Database db = await _openDatabase();
    await db.update(
      'Tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> _deleteTask(Task task) async {
    final Database db = await _openDatabase();
    await db.delete(
      'Tasks',
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> _updatePresetTasks() async {
    final Database db = await _openDatabase();
    await db.transaction((txn) async {
      // Clear existing preset tasks
      await txn.delete('PresetTasks');

      // Insert new preset tasks
      for (String task in presetTasks) {
        await txn.insert('PresetTasks', {'name': task});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load tasks when the widget initializes
    _loadPresetTasks(); // Load preset tasks when the widget initializes
  }

  Future<void> _loadTasks() async {
    final Database db = await _openDatabase();
    final List<Map<String, dynamic>> maps = await db.query('Tasks');
    setState(() {
      tasks = List.generate(maps.length, (i) {
        return Task(
          id: maps[i]['id'],
          name: maps[i]['name'],
          time: maps[i]['time'],
          date: DateTime.parse(maps[i]['date']),
          completed: maps[i]['completed'] == 1,
          priority: TaskPriority.values[maps[i]['priority']],
        );
      });
    });
  }

  Future<void> _loadPresetTasks() async {
    final Database db = await _openDatabase();
    final List<Map<String, dynamic>> maps = await db.query('PresetTasks');
    setState(() {
      presetTasks = List.generate(maps.length, (i) {
        return maps[i]['name'] as String;
      });
    });
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade900;
      case TaskPriority.medium:
        return Colors.yellow.shade700;
      case TaskPriority.low:
      default:
        return Colors.green.shade900;
    }
  }

  void _clearAllTasks() {
    setState(() {
      tasks.clear();
      _deleteAllTasks(); // Delete all tasks from database
    });
  }

  Future<void> _deleteAllTasks() async {
    final Database db = await _openDatabase();
    await db.delete('Tasks');
  }
}

class Task {
  int? id;
  String name;
  String time;
  DateTime date;
  bool completed;
  TaskPriority priority;

  Task({
    this.id,
    required this.name,
    required this.time,
    required this.date,
    this.completed = false,
    this.priority = TaskPriority.low,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'date': date.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority.index,
    };
  }
}

enum TaskPriority { low, medium, high }
