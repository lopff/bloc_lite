import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:bloc_lite/bloc_lite.dart';

import 'typedefs.dart';
import 'inherited_bloc.dart';

/// A builder [Widget] that subscribes to a [BlocController] and automatically
/// refreshes whenever updates to the controller are published.
class BlocWidget<B extends BlocController> extends StatefulWidget {
  BlocWidget({
    Key key,
    @required this.controller,
    @required this.builder,
    this.builderOnError,
    this.builderOnClose,
  })  : assert(controller != null),
        assert(builder != null),
        super(key: key);

  /// A factory constructor that subscribes to a [BlocController] of the
  /// specified type that has been injected into the widget tree as an
  /// ancestor to this widget.
  factory BlocWidget.inherited({
    Key key,
    @required BuildContext context,
    @required BlocBuilder<B> builder,
    BlocBuilderOnError<B> builderOnError,
    BlocBuilderOnClose<B> builderOnClose,
  }) {
    final controller = InheritedBloc.of<B>(context);
    assert(controller != null);

    return BlocWidget(
      key: key,
      controller: controller,
      builder: builder,
      builderOnError: builderOnError,
      builderOnClose: builderOnClose,
    );
  }

  /// The [BlocController] that this widget subscribes to.
  final B controller;

  /// The builder function for this widget. The function is passed a reference
  /// to the controller as an argument and is fired once when the widget is
  /// first built and then again when the controller publishes an update.
  final BlocBuilder<B> builder;

  /// An optional builder function that fires when the controller reports an
  /// error. The controller as well as the error and stacktrace are passed to
  /// the function as arguments.
  ///
  /// (If this function is null, the widget will instead print a debug message
  /// containing the error message and stacktrace.)
  final BlocBuilderOnError<B> builderOnError;

  /// An optional builder function that fires when the controller reports that
  /// its underlying stream has closed. The controller is passed to the
  /// function as arguments.
  final BlocBuilderOnClose<B> builderOnClose;

  @override
  _BlocWidgetState<B> createState() => _BlocWidgetState<B>();
}

class _BlocWidgetState<B extends BlocController> extends State<BlocWidget<B>> {
  StreamSubscription _subscription;
  BlocWidgetBlocState _builderState;
  Object _error;
  StackTrace _stackTrace;

  @override
  void initState() {
    _subscribe();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(BlocWidget<B> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_subscription != null) {
      _unsubscribe();
    }
    _subscribe();
  }

  void _onData(B value) {
    setState(() {
      _builderState = BlocWidgetBlocState.normal;
    });
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (widget.builderOnError == null) {
      print('[WARNING] Subscribed bloc stream threw an error.');
      print(stackTrace);
    }

    setState(() {
      _error = error;
      _stackTrace = stackTrace;
      _builderState = BlocWidgetBlocState.error;
    });
  }

  void _onDone() {
    setState(() {
      _builderState = BlocWidgetBlocState.done;
    });
  }

  void _subscribe() {
    _subscription = widget.controller
        .subscribeToUpdates(_onData, onError: _onError, onDone: _onDone);
  }

  void _unsubscribe() {
    if (_subscription == null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  @override
  Widget build(BuildContext cxt) {
    if (_builderState == BlocWidgetBlocState.done &&
        widget.builderOnClose != null) {
      return widget.builderOnClose(cxt, widget.controller);
    }

    if (_builderState == BlocWidgetBlocState.error &&
        widget.builderOnError != null) {
      return widget.builderOnError(cxt, widget.controller, _error, _stackTrace);
    }

    return widget.builder(cxt, widget.controller);
  }
}
