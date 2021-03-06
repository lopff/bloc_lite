import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_controller.dart';

/// Provides a BLoC model interface to a class. Provides a `PublishSubject`
/// stream that can be subscribed to for updates. Also exposes a `StreamSink` and
/// an `Observable` for more control over the output. Updates are typically
/// triggered by calling the `publishUpdate` method.
abstract class BlocState {
  BlocState() : _subject = PublishSubject();

  final PublishSubject<BlocState> _subject;

  /// The enclosing controller for this state
  BlocController controller;

  StreamSink<BlocState> get sink => _subject.sink;
  Observable<BlocState> get stream => _subject.stream;

  /// Registers the given callback methods with the underlying stream and returns
  /// the resulting `StreamSubscription`.
  StreamSubscription listen(void Function(BlocState) onMutate,
      {void Function(Error, StackTrace) onError, void Function() onDone}) {
    return _subject.listen(onMutate, onError: onError, onDone: onDone);
  }

  /// Executes the provided closure function, then notifies the state of a mutation.
  ///
  /// Whenever you mutate the state's data, do it within a function that you pass to `mutate`:
  ///
  /// ```dart
  /// state.mutate(() { state.value = newValue });
  /// ```
  ///
  /// The provided callback is immediately called synchronously. It must not
  /// return a future (the callback cannot be `async`), since then it would be
  /// unclear when the state was actually being set.
  void mutate(void Function() mutation) {
    dynamic result = mutation() as dynamic;
    if (result is Future) {
      print('[WARNING] The closure function passed to mutate was marked as asynchronous or ' +
          'returned a Future. The state cannot guarantee that the mutation will have completed ' +
          'before the state is accessed by stream subscribers.');
    }
    publishMutation();
  }

  /// Notify the underlying stream that the internal state has mutated.
  ///
  /// This method allows the state to manually trigger a mutation signal. However, it is recommended
  /// that mutations be performed within a call to [mutate] instead.
  @protected
  void publishMutation() {
    try {
      preMutate();
      _subject.add(this);
      postMutate();
    } catch (e, st) {
      this.onError(e, st);
    }
  }

  /// Closes the underlying stream. Inheriting classes that overload this method must call `super.dispose()`.
  @mustCallSuper
  void dispose() {
    _subject.close();
  }

  /// Method that is called when the stream reports an error. Prints the error message by default.
  @protected
  void onError(Object error, StackTrace stackTrace) => print(error);

  /// Method that is called when [publishMutation] is called but before the stream is notified. Does nothing by default.
  @protected
  void preMutate() => null;

  /// Method that is called when [publishMutation] is called, after the stream is notified. Does nothing by default.
  @protected
  void postMutate() => null;
}
