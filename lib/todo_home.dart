import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_new/widgets/task_list.dart';

class TodoHome extends StatefulWidget {
  const TodoHome({super.key});

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final taskController = TextEditingController();
  final subTitleController = TextEditingController();

  // task list
  List<Map<String, dynamic>> taskList = [];

  // hive database reference
  final _hiveDB = Hive.box("todo_db");

  @override
  void initState() {
    taskGet();
    super.initState();
  }

  // task get
  void taskGet() {
    final taskData = _hiveDB.keys.map((key) {
      final task = _hiveDB.get(key);
      return {
        "key": key,
        "taskName": task["taskName"],
        "subTitle": task["subTitle"],
      };
    }).toList();

    setState(() {
      taskList = taskData.reversed.toList();
      taskList.length;
    });
  }

  // create task
  Future<void> _createTask(Map<String, dynamic> newTask) async {
    await _hiveDB.add(newTask);
    taskGet();
  }

  // update task
  Future<void> updateTask(int taskId, Map<String, dynamic> task) async {
    await _hiveDB.put(taskId, task);
    taskGet();
  }

  // delete task
  Future<void> deleteTask(int taskId) async {
    await _hiveDB.delete(taskId);
    taskGet();

    // pop message
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task has been deleted"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (_, index) {
              final currentTask = taskList[index];
              return Card(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(currentTask["taskName"]),
                    subtitle: Text(currentTask["subTitle"]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () {
                              showAddSheet(currentTask["key"]);
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.green,
                            )),
                        IconButton(
                          onPressed: () {
                            deleteTask(currentTask["key"]);
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showAddSheet(null);
        },
      ),
    );
  }

  // show model bottom sheet
  void showAddSheet(int? taskId) {
    if (taskId != null) {
      final existingTask =
          taskList.firstWhere((element) => element["key"] == taskId);
      taskController.text = existingTask["taskName"];
      subTitleController.text = existingTask["subTitle"];
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          child: Padding(
            padding: EdgeInsets.only(
              top: 15,
              left: 15,
              right: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    hintText: "Add a task",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subTitleController,
                  decoration: const InputDecoration(
                    hintText: "Add a sub title",
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (taskId == null) {
                      _createTask({
                        "taskName": taskController.text,
                        "subTitle": subTitleController.text,
                      });
                    }

                    if (taskId != null) {
                      updateTask(
                        taskId,
                        {
                          "taskName": taskController.text.trim(),
                          "subTitle": subTitleController.text.trim(),
                        },
                      );
                    }

                    taskController.text = '';
                    subTitleController.text = '';

                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(taskId == null ? "Add" : "Update"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
