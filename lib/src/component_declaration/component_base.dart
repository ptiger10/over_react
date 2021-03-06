// Copyright 2016 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library over_react.component_declaration.component_base;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';

import 'package:over_react/src/component_declaration/component_type_checking.dart';
import 'package:over_react/src/component_declaration/util.dart';
import 'package:over_react/src/util/test_mode.dart';
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:w_common/disposable.dart';

export 'package:over_react/src/component_declaration/component_type_checking.dart' show isComponentOfType, isValidElementOfType;

/// Helper function that wraps react.registerComponent, and allows attachment of additional
/// component factory metadata.
///
/// * [isWrapper]: whether the component clones or passes through its children and needs to be
/// treated as if it were the wrapped component.
///
/// * [builderFactory]/[componentClass]: the [UiFactory] and [UiComponent] members to be potentially
/// used as types for [isComponentOfType]/[getComponentFactory].
///
/// * [displayName]: the name of the component for use when debugging.
ReactDartComponentFactoryProxy registerComponent(react.Component dartComponentFactory(), {
    bool isWrapper: false,
    ReactDartComponentFactoryProxy parentType,
    UiFactory builderFactory,
    Type componentClass,
    String displayName
}) {
  ReactDartComponentFactoryProxy reactComponentFactory = react.registerComponent(dartComponentFactory);

  if (displayName != null) {
    reactComponentFactory.reactClass.displayName = displayName;
  }

  registerComponentTypeAlias(reactComponentFactory, builderFactory);
  registerComponentTypeAlias(reactComponentFactory, componentClass);

  setComponentTypeMeta(reactComponentFactory, isWrapper: isWrapper, parentType: parentType);

  return reactComponentFactory;
}

/// Helper function that wraps [registerComponent], and allows an easier way to register abstract components with the
/// main purpose of type-checking against the abstract component.
///
/// __The result must be stored in a variable that is named very specifically:__
///
///     var $`AbstractComponentClassName`Factory = registerAbstractComponent(`AbstractComponentClassName`);
ReactDartComponentFactoryProxy registerAbstractComponent(Type abstractComponentClass, {ReactDartComponentFactoryProxy parentType}) =>
    registerComponent(() => new DummyComponent(), componentClass: abstractComponentClass, parentType: parentType);

/// A function that returns a new [TProps] instance, optionally backed by the specified [backingProps].
///
/// For use in wrapping existing Maps in typed getters and setters, and for creating React components
/// via a fluent-style builder interface.
typedef TProps UiFactory<TProps extends UiProps>([Map backingProps]);

/// A utility variation on [UiFactory], __without__ a `backingProps` parameter.
///
/// I.e., a function that takes no parameters and returns a new [TProps] instance backed by a new, empty Map.
///
/// For use as a Function variable type when the `backingProps` argument is not required.
typedef TProps BuilderOnlyUiFactory<TProps extends UiProps>();

/// The basis for an over_react component.
///
/// Includes support for strongly-typed [UiProps] and utilities for prop and CSS classname forwarding.
///
/// __Prop and CSS className forwarding when your component renders a composite component:__
///
///     @Component()
///     class YourComponent extends UiComponent<YourProps> {
///       Map getDefaultProps() => (newProps()
///         ..aPropOnYourComponent = /* default value */
///       );
///
///       @override
///       render() {
///         var classes = forwardingClassNameBuilder()
///           ..add('your-component-base-class')
///           ..add('a-conditional-class', shouldApplyConditionalClass);
///
///         return (SomeChildComponent()
///           ..addProps(copyUnconsumedProps())
///           ..className = classes.toClassName()
///         )(props.children);
///       }
///     }
///
/// __Prop and CSS className forwarding when your component renders a DOM component:__
///
///     @Component()
///     class YourComponent extends UiComponent<YourProps> {
///       @override
///       render() {
///         var classes = forwardingClassNameBuilder()
///           ..add('your-component-base-class')
///           ..add('a-conditional-class', shouldApplyConditionalClass);
///
///         return (Dom.div()
///           ..addProps(copyUnconsumedDomProps())
///           ..className = classes.toClassName()
///         )(props.children);
///       }
///     }
///
/// > Related: [UiStatefulComponent]
abstract class UiComponent<TProps extends UiProps> extends react.Component implements DisposableManagerV7 {
  Disposable _disposableProxy;

  /// The props for the non-forwarding props defined in this component.
  Iterable<ConsumedProps> get consumedProps => null;

  /// Returns a copy of this component's props with keys found in [consumedProps] omitted.
  ///
  /// > Should be used alongside [forwardingClassNameBuilder].
  ///
  /// > Related [copyUnconsumedDomProps]
  Map copyUnconsumedProps() {
    var consumedPropKeys = consumedProps?.map((ConsumedProps consumedProps) => consumedProps.keys) ?? const [];

    return copyProps(keySetsToOmit: consumedPropKeys);
  }

  /// Returns a copy of this component's props with keys found in [consumedProps] and non-DOM props omitted.
  ///
  /// > Should be used alongside [forwardingClassNameBuilder].
  ///
  /// > Related [copyUnconsumedProps]
  Map copyUnconsumedDomProps() {
    var consumedPropKeys = consumedProps?.map((ConsumedProps consumedProps) => consumedProps.keys) ?? const [];

    return copyProps(onlyCopyDomProps: true, keySetsToOmit: consumedPropKeys);
  }

  /// Returns a copy of this component's props with React props optionally omitted, and
  /// with the specified [keysToOmit] and [keySetsToOmit] omitted.
  Map copyProps({bool omitReservedReactProps: true, bool onlyCopyDomProps: false, Iterable keysToOmit, Iterable<Iterable> keySetsToOmit}) {
    return getPropsToForward(this.props,
        omitReactProps: omitReservedReactProps,
        onlyCopyDomProps: onlyCopyDomProps,
        keysToOmit: keysToOmit,
        keySetsToOmit: keySetsToOmit
    );
  }

  /// Throws a [PropError] if [appliedProps] are invalid.
  ///
  /// This is called automatically with the latest props available during [componentWillReceiveProps] and
  /// [componentWillMount], and can also be called manually for custom validation.
  ///
  /// Override with a custom implementation to easily add validation (and don't forget to call super!)
  ///
  ///     @mustCallSuper
  ///     void validateProps(Map appliedProps) {
  ///       super.validateProps(appliedProps);
  ///
  ///       var tProps = typedPropsFactory(appliedProps);
  ///       if (tProps.items.length.isOdd) {
  ///         throw new PropError.value(tProps.items, 'items', 'must have an even number of items, because reasons');
  ///       }
  ///     }
  @mustCallSuper
  void validateProps(Map appliedProps) {
    validateRequiredProps(appliedProps);
  }

  /// Validates that props with the `@requiredProp` annotation are present.
  void validateRequiredProps(Map appliedProps) {
    consumedProps?.forEach((ConsumedProps consumedProps) {
      consumedProps.props.forEach((PropDescriptor prop) {
        if (!prop.isRequired) return;
        if (prop.isNullable && appliedProps.containsKey(prop.key)) return;
        if (!prop.isNullable && appliedProps[prop.key] != null) return;

        throw new PropError.required(prop.key, prop.errorMessage);
      });
    });
  }

  /// Returns a new ClassNameBuilder with className and blacklist values added from [CssClassPropsMixin.className] and
  /// [CssClassPropsMixin.classNameBlacklist], if they are specified.
  ///
  /// This method should be used as the basis for the classNames of components receiving forwarded props.
  ///
  /// > Should be used alongside [copyUnconsumedProps] or [copyUnconsumedDomProps].
  ClassNameBuilder forwardingClassNameBuilder() {
    return new ClassNameBuilder.fromProps(this.props);
  }

  @override
  @mustCallSuper
  void componentWillReceiveProps(Map nextProps) {
    if (inReactDevMode) {
      validateProps(nextProps);
    }
  }

  @override
  @mustCallSuper
  void componentWillMount() {
    if (inReactDevMode) {
      validateProps(props);
    }
  }

  @override
  @mustCallSuper
  void componentWillUnmount() {
    _disposableProxy?.dispose();
  }


  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  //   BEGIN Typed props helpers
  //

  var _typedPropsCache = new Expando<TProps>();

  /// A typed props object corresponding to the current untyped props Map ([unwrappedProps]).
  ///
  /// Created using [typedPropsFactory] and cached for each Map instance.
  @override
  TProps get props {
    var unwrappedProps = this.unwrappedProps;
    var typedProps = _typedPropsCache[unwrappedProps];
    if (typedProps == null) {
      typedProps = typedPropsFactory(inReactDevMode ? _WarnOnModify(unwrappedProps, true) : unwrappedProps);
      _typedPropsCache[unwrappedProps] = typedProps;
    }
    return typedProps;
  }
  /// Equivalent to setting [unwrappedProps], but needed by react-dart to effect props changes.
  @override
  set props(Map value) => super.props = value;

  /// The props Map that will be used to create the typed [props] object.
  Map get unwrappedProps => super.props;
  set unwrappedProps(Map value) => super.props = value;

  /// Returns a typed props object backed by the specified [propsMap].
  ///
  /// Required to properly instantiate the generic [TProps] class.
  TProps typedPropsFactory(Map propsMap);

  /// Returns a typed props object backed by a new Map.
  ///
  /// Convenient for use with [getDefaultProps].
  TProps newProps() => typedPropsFactory({});

  //
  //   END Typed props helpers
  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  //   BEGIN DisposableManagerV7 interface implementation
  //

  @override
  Future<T> awaitBeforeDispose<T>(Future<T> future) =>
    _getDisposableProxy().awaitBeforeDispose<T>(future);

  @override
  Future<T> getManagedDelayedFuture<T>(Duration duration, T callback()) =>
    _getDisposableProxy().getManagedDelayedFuture<T>(duration, callback);

  @override
  ManagedDisposer getManagedDisposer(Disposer disposer) => _getDisposableProxy().getManagedDisposer(disposer);

  @override
  Timer getManagedPeriodicTimer(Duration duration, void callback(Timer timer)) =>
    _getDisposableProxy().getManagedPeriodicTimer(duration, callback);

  @override
  Timer getManagedTimer(Duration duration, void callback()) =>
    _getDisposableProxy().getManagedTimer(duration, callback);

  @override
  StreamSubscription<T> listenToStream<T>(
      Stream<T> stream, void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) =>
      _getDisposableProxy().listenToStream(
        stream, onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Disposable manageAndReturnDisposable(Disposable disposable) =>
      _getDisposableProxy().manageAndReturnDisposable(disposable);

  @override
  Completer<T> manageCompleter<T>(Completer<T> completer) =>
    _getDisposableProxy().manageCompleter<T>(completer);

  @override
  void manageDisposable(Disposable disposable) =>
    _getDisposableProxy().manageDisposable(disposable);

  /// DEPRECATED. Use [getManagedDisposer] instead.
  @Deprecated('2.0.0')
  @override
  void manageDisposer(Disposer disposer) =>
    _getDisposableProxy().manageDisposer(disposer);

  @override
  void manageStreamController(StreamController controller) =>
    _getDisposableProxy().manageStreamController(controller);

  /// DEPRECATED. Use [listenToStream] instead.
  @Deprecated('2.0.0')
  @override
  void manageStreamSubscription(StreamSubscription subscription) =>
    _getDisposableProxy().manageStreamSubscription(subscription);

  /// Instantiates a new [Disposable] instance on the first call to the
  /// [DisposableManagerV7] method.
  Disposable _getDisposableProxy() {
    if (_disposableProxy == null) {
      _disposableProxy = new Disposable();
    }
    return _disposableProxy;
  }

  /// Automatically dispose another object when this object is disposed.
  ///
  /// This method is an extension to `manageAndReturnDisposable` and returns the
  /// passed in [Disposable] as its original type in addition to handling its
  /// disposal. The method should be used when a variable is set and should
  /// conditionally be managed for disposal. The most common case will be dealing
  /// with optional parameters:
  ///
  ///      class MyDisposable extends Disposable {
  ///        // This object also extends disposable
  ///        MyObject _internal;
  ///
  ///        MyDisposable({MyObject optional}) {
  ///          // If optional is injected, we should not manage it.
  ///          // If we create our own internal reference we should manage it.
  ///          _internal = optional ??
  ///              manageAndReturnTypedDisposable(new MyObject());
  ///        }
  ///
  ///        // ...
  ///      }
  ///
  /// The parameter may not be `null`.
  @override
  T manageAndReturnTypedDisposable<T extends Disposable>(T disposable) =>
      _disposableProxy.manageAndReturnTypedDisposable(disposable);

  //
  //   END DisposableManagerV7 interface implementation
  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
}

/// The basis for a _stateful_ over_react component.
///
/// Includes support for strongly-typed [UiState] in-addition-to the
/// strongly-typed props and utilities for prop and CSS classname forwarding provided by [UiComponent].
///
/// __Initializing state:__
///
///     @Component()
///     class YourComponent extends UiStatefulComponent<YourProps, YourState> {
///       Map getInitialState() => (newState()
///         ..aStateKeyWithinYourStateClass = /* default value */
///       );
///
///       @override
///       render() {
///         var classes = forwardingClassNameBuilder()
///           ..add('your-component-base-class')
///           ..add('a-conditional-class', state.aStateKeyWithinYourStateClass);
///
///         return (SomeChildComponent()
///           ..addProps(copyUnconsumedProps())
///           ..className = classes.toClassName()
///         )(props.children);
///       }
///     }
abstract class UiStatefulComponent<TProps extends UiProps, TState extends UiState> extends UiComponent<TProps> {
  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  //   BEGIN Typed state helpers
  //

  var _typedStateCache = new Expando<TState>();

  /// A typed state object corresponding to the current untyped state Map ([unwrappedState]).
  ///
  /// Created using [typedStateFactory] and cached for each Map instance.
  @override
  TState get state {
    var unwrappedState = this.unwrappedState;
    var typedState = _typedStateCache[unwrappedState];
    if (typedState == null) {
    typedState = typedStateFactory(inReactDevMode ? _WarnOnModify(unwrappedState, false) : unwrappedState);
      _typedStateCache[unwrappedState] = typedState;
    }
    return typedState;
  }
  /// Equivalent to setting [unwrappedState], but needed by react-dart to effect state changes.
  @override
  set state(Map value) => super.state = value;

  /// The state Map that will be used to create the typed [state] object.
  Map get unwrappedState => super.state;
  set unwrappedState(Map value) => super.state = value;

  /// Returns a typed state object backed by the specified [stateMap].
  ///
  /// Required to properly instantiate the generic [TState] class.
  TState typedStateFactory(Map stateMap);

  /// Returns a typed state object backed by a new Map.
  ///
  /// Convenient for use with [getInitialState] and [setState].
  TState newState() => typedStateFactory({});

  //
  //   END Typed state helpers
  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
}

class _WarnOnModify<K, V> extends MapView<K, V> {
  //Used to customize warning based on whether the data is props or state
  bool isProps;

  String message;

  _WarnOnModify(Map componentData, this.isProps): super(componentData);

  @override
  operator []=(K key, V value) {
    if (isProps) {
      message =
        '''
          props["$key"] was updated incorrectly. Never mutate this.props directly, as it can cause unexpected behavior; 
          props must be updated only by passing in new values when re-rendering this component.

          This will throw in UiComponentV2 (to be released as part of the React 16 upgrade).
        ''';
    } else {
      message =
        '''
          state["$key"] was updated incorrectly. Never mutate this.state directly, as it can cause unexpected behavior; 
          state must be updated only via setState.

          This will throw in UiComponentV2 (to be released as part of the React 16 upgrade).
        ''';
    }
    super[key] = value;
    ValidationUtil.warn(unindent(message));
  }
}

/// A `dart.collection.MapView`-like class with strongly-typed getters/setters for React state.
///
/// > Note: Implements [MapViewMixin] instead of extending it so that the abstract state declarations
/// don't need a constructor. The generated implementations can mix that functionality in.
abstract class UiState extends Object with MapViewMixin, StateMapViewMixin {}

/// The string used by default for the key of the attribute added by [UiProps.addTestId].
const defaultTestIdKey = 'data-test-id';

/// Enforces that a function take a single parameter of type [Map].
///
/// Used in [UiProps.modifyProps].
typedef PropsModifier(Map props);

/// A `dart.collection.MapView`-like class with strongly-typed getters/setters for React props that
/// is also capable of creating React component instances.
///
/// For use as a typed view into existing props [Map]s, or as a builder to create new component
/// instances via a fluent-style interface.
///
/// > Note: Implements [MapViewMixin] instead of extending it so that the abstract [Props] declarations
/// don't need a constructor. The generated implementations can mix that functionality in.
abstract class UiProps extends MapBase
    with
        MapViewMixin,
        PropsMapViewMixin,
        ReactPropsMixin,
        UbiquitousDomPropsMixin,
        CssClassPropsMixin
    implements
        Map {
  /// Adds an arbitrary [propKey]/[value] pair if [shouldAdd] is `true`.
  ///
  /// Is a noop if [shouldAdd] is `false`.
  ///
  /// > Related: [addProps]
  void addProp(propKey, value, [bool shouldAdd = true]) {
    if (!shouldAdd) return;

    this[propKey] = value;
  }

  /// Adds an arbitrary [propMap] of arbitrary props if [shouldAdd] is true.
  ///
  /// Is a noop if [shouldAdd] is `false` or [propMap] is `null`.
  ///
  /// > Related: [addProp], [modifyProps]
  void addProps(Map propMap, [bool shouldAdd = true]) {
    if (!shouldAdd || propMap == null) return;

    this.addAll(propMap);
  }

  /// Allows [modifier] to alter the instance if [shouldModify] is true.
  ///
  /// Is a noop if [shouldModify] is `false` or [modifier] is `null`.
  ///
  /// > Related: [addProps]
  void modifyProps(PropsModifier modifier, [bool shouldModify = true]){
    if (!shouldModify || modifier == null) return;

    modifier(this);
  }

  /// Whether [UiProps] is in a testing environment.
  ///
  /// Do not set this directly; Call [enableTestMode] or [disableTestMode] instead.
  static bool testMode = false;

  /// Whether [UiProps] is in a testing environment at build time.
  static const bool _testModeFromEnvironment = const bool.fromEnvironment('testing');

  /// Whether [UiProps] is in a testing environment at build time or otherwise.
  ///
  /// Used in [addTestId].
  ///
  /// TODO: Only use bool.fromEnvironment() when it is supported in Dartium.
  /// See: <https://github.com/dart-lang/pub/issues/798>.
  bool get _inTestMode => testMode || _testModeFromEnvironment;

  /// Adds [value] to the prop [key] _(delimited with a single space)_.
  ///
  /// Allows for an element to have multiple test IDs to prevent overwriting when cloning elements or components.
  ///
  /// > For use in a testing environment (when [testMode] is true).
  void addTestId(String value, {String key: defaultTestIdKey}) {
    if (!_inTestMode || value == null) {
      return;
    }

    String testId = getTestId(key: key);

    if (testId == null) {
      props[key] = value;
    } else {
      props[key] = getTestId(key: key) + ' $value';
    }
  }

  /// Gets the [defaultTestIdKey] prop value, or one testId from the prop _(or custom [key] prop value)_.
  ///
  /// > For use in a testing environment (when [testMode] is true).
  String getTestId({String key: defaultTestIdKey}) {
    return props[key];
  }

  /// Gets the `data-test-id` prop key for use in a testing environment.
  ///
  /// DEPRECATED. Use [getTestId] instead.
  @Deprecated('2.0.0')
  String get testId {
    return getTestId();
  }

  /// Returns a new component with this builder's [props] and the specified [children].
  ReactElement build([dynamic children]) {
    assert(_validateChildren(children));

    return componentFactory(props, children);
  }

  /// Creates a new component with this builder's props and the specified [children].
  ///
  /// _(alias for [build] with support for variadic children)_
  ///
  /// This method actually takes any number of children as arguments ([c2], [c3], ...) via [noSuchMethod].
  ///
  /// Restricted statically to 40 arguments until the dart2js fix in
  /// <https://github.com/dart-lang/sdk/pull/26032> is released.
  ///
  ReactElement call([c1 = notSpecified, c2 = notSpecified, c3 = notSpecified, c4 = notSpecified, c5 = notSpecified, c6 = notSpecified, c7 = notSpecified, c8 = notSpecified, c9 = notSpecified, c10 = notSpecified, c11 = notSpecified, c12 = notSpecified, c13 = notSpecified, c14 = notSpecified, c15 = notSpecified, c16 = notSpecified, c17 = notSpecified, c18 = notSpecified, c19 = notSpecified, c20 = notSpecified, c21 = notSpecified, c22 = notSpecified, c23 = notSpecified, c24 = notSpecified, c25 = notSpecified, c26 = notSpecified, c27 = notSpecified, c28 = notSpecified, c29 = notSpecified, c30 = notSpecified, c31 = notSpecified, c32 = notSpecified, c33 = notSpecified, c34 = notSpecified, c35 = notSpecified, c36 = notSpecified, c37 = notSpecified, c38 = notSpecified, c39 = notSpecified, c40 = notSpecified]) {
    List childArguments;
    // Use `identical` since it compiles down to `===` in dart2js instead of calling equality helper functions,
    // and we don't want to allow any object overriding `operator==` to claim it's equal to `_notSpecified`.
    if (identical(c1, notSpecified)) {
      childArguments = [];
    } else if (identical(c2, notSpecified)) {
      childArguments = [c1];
    } else if (identical(c3, notSpecified)) {
      childArguments = [c1, c2];
    } else if (identical(c4, notSpecified)) {
      childArguments = [c1, c2, c3];
    } else if (identical(c5, notSpecified)) {
      childArguments = [c1, c2, c3, c4];
    } else if (identical(c6, notSpecified)) {
      childArguments = [c1, c2, c3, c4, c5];
    } else if (identical(c7, notSpecified)) {
      childArguments = [c1, c2, c3, c4, c5, c6];
    } else {
      childArguments = [c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30, c31, c32, c33, c34, c35, c36, c37, c38, c39, c40]
        .takeWhile((child) => !identical(child, notSpecified))
        .toList();
    }

    assert(_validateChildren(childArguments.length == 1 ? childArguments.single : childArguments));

    final factory = componentFactory;
    if (factory is ReactComponentFactoryProxy) {
      // Use `build` instead of using emulated function behavior to work around DDC issue
      // https://github.com/dart-lang/sdk/issues/29904
      // Should have the benefit of better performance;
      return factory.build(props, childArguments);
    } else {
      var parameters = []
        ..add(props)
        ..addAll(childArguments);
      return Function.apply(factory, parameters);
    }
  }

  /// Validates that no [children] are instances of [UiProps], and prints a helpful message for a better debugging
  /// experience.
  bool _validateChildren(dynamic children) {
    // Should not validate non-list iterables to avoid more than one iteration.
    if (children != null && (children is! Iterable || children is List)) {
      if (children is! List) {
        children = [children];
      }

      if (children.any((child) => child is UiProps)) {
        var errorMessage = unindent(
            '''
            It looks like you are trying to use a non-invoked builder as a child. That is an invalid use of UiProps, try
            invoking the builder before passing it as a child.
            '''
        );

        // TODO: Remove ValidationUtil.warn call when https://github.com/dart-lang/sdk/issues/26093 is resolved.
        ValidationUtil.warn(errorMessage, this);
        throw new ArgumentError(errorMessage);
      }
    }

    return true;
  }

  ReactComponentFactoryProxy get componentFactory;

  /// An unmodifiable map view of the default props for this component brought
  /// in from the [componentFactory].
  Map get componentDefaultProps => componentFactory is ReactDartComponentFactoryProxy
      // ignore: avoid_as
      ? (componentFactory as ReactDartComponentFactoryProxy).defaultProps
      : const {};
}

/// A class that declares the `_map` getter shared by [PropsMapViewMixin]/[StateMapViewMixin] and [MapViewMixin].
///
/// Necessary in order to work around Dart 1.23 strong mode change that disallows conflicting private members
/// in mixins: <https://github.com/dart-lang/sdk/issues/28809>.
abstract class _OverReactMapViewBase<K, V> {
  Map<K, V> get _map;
}

/// Works in conjunction with [MapViewMixin] to provide `dart.collection.MapView`-like
/// functionality to [UiProps] subclasses.
///
/// > Related: [StateMapViewMixin]
abstract class PropsMapViewMixin implements _OverReactMapViewBase {
  /// The props maintained by this builder and used passed into the component when built.
  /// In this case, it's the current MapView object.
  Map get props;

  @override
  Map get _map => this.props;

  @override
  String toString() => '$runtimeType: ${prettyPrintMap(_map)}';
}

/// Works in conjunction with [MapViewMixin] to provide `dart.collection.MapView`-like
/// functionality to [UiState] subclasses.
///
/// > Related: [PropsMapViewMixin]
abstract class StateMapViewMixin implements _OverReactMapViewBase {
  Map get state;

  @override
  Map get _map => this.state;

  @override
  String toString() => '$runtimeType: ${prettyPrintMap(_map)}';
}

/// Provides `dart.collection.MapView`-like behavior by proxying an internal map.
///
/// Works in conjunction with [PropsMapViewMixin] and [StateMapViewMixin] to implement [Map]
/// in [UiProps] and [UiState] subclasses.
///
/// For use by concrete [UiProps] and [UiState] implementations (either generated or manual),
/// and thus must remain public.
abstract class MapViewMixin<K, V> implements _OverReactMapViewBase<K, V>, Map<K, V> {
  @override Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> f(K key, V value)) => _map.map<K2, V2>(f);
  @override Iterable<MapEntry<K, V>> get entries => _map.entries;
  @override void addEntries(Iterable<MapEntry<K, V>> newEntries) => _map.addEntries(newEntries);
  @override void removeWhere(bool predicate(K key, V value)) => _map.removeWhere(predicate);
  @override V update(K key, V update(V value), {V ifAbsent()}) => _map.update(key, update, ifAbsent: ifAbsent);
  @override void updateAll(V update(K key, V value)) => _map.updateAll(update);
  @override Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();
  @override V operator[](Object key) => _map[key];
  @override void operator[]=(K key, V value) { _map[key] = value; }
  @override void addAll(Map<K, V> other) { _map.addAll(other); }
  @override void clear() { _map.clear(); }
  @override V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
  @override bool containsKey(Object key) => _map.containsKey(key);
  @override bool containsValue(Object value) => _map.containsValue(value);
  @override void forEach(void action(K key, V value)) { _map.forEach(action); }
  @override bool get isEmpty => _map.isEmpty;
  @override bool get isNotEmpty => _map.isNotEmpty;
  @override int get length => _map.length;
  @override Iterable<K> get keys => _map.keys;
  @override V remove(Object key) => _map.remove(key);
  @override Iterable<V> get values => _map.values;
}

abstract class _Descriptor {
  String get key;
}

/// Provides a representation of a single `prop` declared within a [UiProps] subclass or props mixin.
///
/// > Related: [StateDescriptor]
class PropDescriptor implements _Descriptor {
  /// The string key associated with the `prop`.
  @override
  final String key;
  /// Whether the `prop` is required to be set.
  final bool isRequired;
  /// Whether setting the `prop` to `null` is valid.
  final bool isNullable;
  /// The message included in the thrown [PropError] if the `prop` is not set.
  final String errorMessage;

  const PropDescriptor(this.key, {this.isRequired: false, this.isNullable: false, this.errorMessage: ''});
}

/// Provides a representation of a single `state` declared within a [UiState] subclass or state mixin.
///
/// > Related: [PropDescriptor]
class StateDescriptor implements _Descriptor {
  /// The string key associated with the `state`.
  @override
  final String key;
  /// Whether the `state` is required to be set.
  ///
  /// __Currently not used.__
  final bool isRequired;
  /// Whether setting the `state` to `null` is valid.
  ///
  /// __Currently not used.__
  final bool isNullable;
  /// The message included in the thrown error if the `state` is not set.
  ///
  /// __Currently not used.__
  final String errorMessage;

  const StateDescriptor(this.key, {this.isRequired: false, this.isNullable: false, this.errorMessage});
}

/// Provides a list of [PropDescriptor]s and a top-level list of their keys, for easy access.
class ConsumedProps {
  /// Rich views of prop declarations.
  ///
  /// This includes string keys, and required prop validation related fields.
  final List<PropDescriptor> props;
  /// Top-level accessor of string keys of props stored in [props].
  final List<String> keys;

  const ConsumedProps(this.props, this.keys);
}

abstract class AccessorMeta<T extends _Descriptor> {
  List<T> get fields;
  List<String> get keys;
}

/// Metadata for the prop fields declared in a specific props class--
/// a class annotated with @[Props], @[PropsMixin], @[AbstractProps], etc.
/// for which prop accessors are generated.
///
/// This metadata includes map key values corresponding to these fields, which
/// is used in [UiComponent.consumedPropKeys], as well as other prop
/// configuration done via @[Accessor]/@[requiredProp]/etc., which is used to
/// perform prop validation within [UiComponent] lifecycle methods.
///
/// This metadata is generated as part of the over_react builder, and should be
/// exposed like so:
///     @Props()
///     class FooProps {
///       static const PropsMeta meta = _$metaForFooProps;
///
///       String foo;
///
///       @Accessor(isRequired: true, key: 'custom_key', keyNamespace: 'custom_namespace')
///       int bar;
///     }
///
/// What the metadata looks like:
///     main() {
///       print(FooProps.meta.keys); // [FooProps.foo, custom_namespace.custom_key]
///       print(FooProps.meta.props.map((p) => p.isRequired); // (false, true))
///     }
///
/// _See also: [getPropKey]_
class PropsMeta implements ConsumedProps, AccessorMeta<PropDescriptor> {
  /// Rich views of prop field declarations.
  ///
  /// This includes string keys, and required prop validation related fields.
  @override
  final List<PropDescriptor> fields;

  /// Top-level accessor of string keys of props stored in [fields].
  @override
  final List<String> keys;

  const PropsMeta({this.fields, this.keys});

  @override
  List<PropDescriptor> get props => fields;
}

/// Metadata for the state fields declared in a specific state class--
/// a class annotated with @[State], @[StateMixin], @[AbstractState], etc.
/// for which state accessors are generated.
///
/// This metadata includes map key values corresponding to these fields, which
/// is used to perform state validation within [UiComponent] lifecycle methods.
///
/// This metadata is generated as part of the over_react builder, and should be
/// exposed like so:
///     @State()
///     class FooState {
///       static const StateMeta meta = _$metaForFooState;
///
///       String foo;
///
///       @Accessor(key: 'custom_key', keyNamespace: 'custom_namespace')
///       int bar;
///     }
///
/// What the metadata looks like:
///     main() {
///       print(FooState.meta.keys); // [FooState.foo, custom_namespace.custom_key]
///       print(FooState.meta.fields.map((s) => s.key); // [FooState.foo, custom_namespace.custom_key]
///     }
class StateMeta implements AccessorMeta<StateDescriptor> {
  /// Rich views of state field declarations.
  ///
  /// This includes string keys, and required state validation related fields.
  @override
  final List<StateDescriptor> fields;

  /// Top-level accessor of string keys of state stored in [fields].
  @override
  final List<String> keys;

  const StateMeta({this.fields, this.keys});
}

