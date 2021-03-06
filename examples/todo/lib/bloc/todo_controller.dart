import 'package:bloc_lite/bloc_lite.dart';
import 'package:bloc_lite_todo/model/enums.dart';
import 'package:bloc_lite_todo/model/todo.dart';

class TodoController extends BlocStateController<TodoState> {
  TodoController([TodoState state]) : super.withState(state);

  @override
  TodoState get initialState => TodoState();

  void addTodo(Todo todo) {
    state.mutate(() {
      state.todos.add(todo);
    });
  }

  void removeTodo(Todo todo) {
    state.mutate(() {
      state.todos.remove(todo);
    });
  }

  void updateTodo(Todo todo, {String task, String note, bool complete}) {
    state.mutate(() {
      final idx = state.todos.indexOf(todo);
      state.todos[idx].task = task ?? todo.task;
      state.todos[idx].note = note ?? todo.note;
      state.todos[idx].complete = complete ?? todo.complete;
    });
  }

  void clearCompleted() {
    state.mutate(() {
      state.todos.removeWhere((todo) => todo.complete);
    });
  }

  void toggleAll() {
    state.mutate(() {
      final allCompleted = state.allComplete;
      state.todos.forEach((todo) => todo.complete = !allCompleted);
    });
  }
}

class TodoState extends BlocState {
  bool isLoading = false;
  List<Todo> todos = [];

  bool get allComplete => todos.every((todo) => todo.complete);
  bool get hasCompletedTodos => todos.any((todo) => todo.complete);
  int get numActive =>
      todos.fold(0, (sum, todo) => !todo.complete ? ++sum : sum);
  int get numCompleted =>
      todos.fold(0, (sum, todo) => todo.complete ? ++sum : sum);

  List<Todo> filterTodos(VisibilityFilter filter) => todos.where((todo) {
        if (filter == VisibilityFilter.all) return true;
        if (filter == VisibilityFilter.active) return !todo.complete;
        return todo.complete;
      }).toList();
}
