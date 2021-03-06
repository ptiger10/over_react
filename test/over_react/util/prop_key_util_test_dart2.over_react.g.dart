// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prop_key_util_test_dart2.dart';

// **************************************************************************
// OverReactBuilder (package:over_react/src/builder.dart)
// **************************************************************************

// React component factory implementation.
//
// Registers component implementation and links type meta to builder factory.
final $TestComponentFactory = registerComponent(() => new _$TestComponent(),
    builderFactory: Test,
    componentClass: TestComponent,
    isWrapper: false,
    parentType: null,
    displayName: 'Test');

abstract class _$TestPropsAccessorsMixin implements _$TestProps {
  @override
  Map get props;

  /// <!-- Generated from [_$TestProps.foo] -->
  @override
  String get foo =>
      props[_$key__foo___$TestProps] ??
      null; // Add ` ?? null` to workaround DDC bug: <https://github.com/dart-lang/sdk/issues/36052>;
  /// <!-- Generated from [_$TestProps.foo] -->
  @override
  set foo(String value) => props[_$key__foo___$TestProps] = value;

  /// <!-- Generated from [_$TestProps.bar] -->
  @override
  String get bar =>
      props[_$key__bar___$TestProps] ??
      null; // Add ` ?? null` to workaround DDC bug: <https://github.com/dart-lang/sdk/issues/36052>;
  /// <!-- Generated from [_$TestProps.bar] -->
  @override
  set bar(String value) => props[_$key__bar___$TestProps] = value;
  /* GENERATED CONSTANTS */
  static const PropDescriptor _$prop__foo___$TestProps =
      const PropDescriptor(_$key__foo___$TestProps);
  static const PropDescriptor _$prop__bar___$TestProps =
      const PropDescriptor(_$key__bar___$TestProps);
  static const String _$key__foo___$TestProps = 'TestProps.foo';
  static const String _$key__bar___$TestProps = 'TestProps.bar';

  static const List<PropDescriptor> $props = const [
    _$prop__foo___$TestProps,
    _$prop__bar___$TestProps
  ];
  static const List<String> $propKeys = const [
    _$key__foo___$TestProps,
    _$key__bar___$TestProps
  ];
}

const PropsMeta _$metaForTestProps = const PropsMeta(
  fields: _$TestPropsAccessorsMixin.$props,
  keys: _$TestPropsAccessorsMixin.$propKeys,
);

class TestProps extends _$TestProps with _$TestPropsAccessorsMixin {
  static const PropsMeta meta = _$metaForTestProps;
}

_$$TestProps _$Test([Map backingProps]) => new _$$TestProps(backingProps);

// Concrete props implementation.
//
// Implements constructor and backing map, and links up to generated component factory.
class _$$TestProps extends _$TestProps
    with _$TestPropsAccessorsMixin
    implements TestProps {
  // This initializer of `_props` to an empty map, as well as the reassignment
  // of `_props` in the constructor body is necessary to work around an unknown ddc issue.
  // See <https://jira.atl.workiva.net/browse/CPLAT-4673> for more details
  _$$TestProps(Map backingMap) : this._props = {} {
    this._props = backingMap ?? {};
  }

  /// The backing props map proxied by this class.
  @override
  Map get props => _props;
  Map _props;

  /// Let [UiProps] internals know that this class has been generated.
  @override
  bool get $isClassGenerated => true;

  /// The [ReactComponentFactory] associated with the component built by this class.
  @override
  ReactComponentFactoryProxy get componentFactory => $TestComponentFactory;

  /// The default namespace for the prop getters/setters generated for this class.
  @override
  String get propKeyNamespace => 'TestProps.';
}

// Concrete component implementation mixin.
//
// Implements typed props/state factories, defaults `consumedPropKeys` to the keys
// generated for the associated props class.
class _$TestComponent extends TestComponent {
  @override
  _$$TestProps typedPropsFactory(Map backingMap) =>
      new _$$TestProps(backingMap);

  /// Let [UiComponent] internals know that this class has been generated.
  @override
  bool get $isClassGenerated => true;

  /// The default consumed props, taken from _$TestProps.
  /// Used in [UiProps.consumedProps] if [consumedProps] is not overridden.
  @override
  final List<ConsumedProps> $defaultConsumedProps = const [_$metaForTestProps];
}
