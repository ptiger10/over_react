import 'dart:collection';

import 'package:over_react/component_base.dart' as component_base show UiProps;
import 'package:over_react/over_react.dart';
import 'package:over_react/src/component_declaration/util.dart';
import 'package:react/react_client.dart';

/// A `MapView` helper that stubs in unimplemented pieces of [UiProps].
///
/// Useful when you need a `MapView` for a [PropsMixin] that implements [UiProps].
class UiPropsMapView extends MapView
    with
        ReactPropsMixin,
        UbiquitousDomPropsMixin,
        CssClassPropsMixin
    implements
        component_base.UiProps {
  /// Create a new instance backed by the specified map.
  UiPropsMapView(Map map) : super(map);

  /// The props to be manipulated via the getters/setters.
  /// In this case, it's the current MapView object.
  @override
  Map get props => this;

  bool get $isClassGenerated =>
      throw new UnimplementedError('@PropsMixin instances do not implement \$isClassGenerated');

  String get propKeyNamespace => throw new UnimplementedError('@PropsMixin instances do not implement propKeyNamespace');

  // ----- component_base.UiProps ----- //

  @override
  void addProp(propKey, value, [bool shouldAdd = true]) =>
      throw new UnimplementedError('@PropsMixin instances do not implement addProp');

  @override
  void addProps(Map propMap, [bool shouldAdd = true]) =>
      throw new UnimplementedError('@PropsMixin instances do not implement addProps');

  @override
  void modifyProps(PropsModifier modifier, [bool shouldModify = true]) =>
      throw new UnimplementedError('@PropsMixin instances do not implement modifyProps');

  @override
  void addTestId(String value, {String key: defaultTestIdKey}) =>
      throw new UnimplementedError('@PropsMixin instances do not implement addTestId');

  @override
  String getTestId({String key: defaultTestIdKey}) =>
      throw new UnimplementedError('@PropsMixin instances do not implement getTestId');

  @override
  String get testId => getTestId();

  @override
  Map get componentDefaultProps => throw new UnimplementedError('@PropsMixin instances do not implement defaultProps');

  @override
  ReactElement build([dynamic children]) =>
      throw new UnimplementedError('@PropsMixin instances do not implement build');

  @override
  ReactComponentFactoryProxy get componentFactory =>
      throw new UnimplementedError('@PropsMixin instances do not implement componentFactory');

  @override
  ReactElement call([c1 = notSpecified, c2 = notSpecified, c3 = notSpecified, c4 = notSpecified, c5 = notSpecified, c6 = notSpecified, c7 = notSpecified, c8 = notSpecified, c9 = notSpecified, c10 = notSpecified, c11 = notSpecified, c12 = notSpecified, c13 = notSpecified, c14 = notSpecified, c15 = notSpecified, c16 = notSpecified, c17 = notSpecified, c18 = notSpecified, c19 = notSpecified, c20 = notSpecified, c21 = notSpecified, c22 = notSpecified, c23 = notSpecified, c24 = notSpecified, c25 = notSpecified, c26 = notSpecified, c27 = notSpecified, c28 = notSpecified, c29 = notSpecified, c30 = notSpecified, c31 = notSpecified, c32 = notSpecified, c33 = notSpecified, c34 = notSpecified, c35 = notSpecified, c36 = notSpecified, c37 = notSpecified, c38 = notSpecified, c39 = notSpecified, c40 = notSpecified]) => throw new UnimplementedError('@PropsMixin instances do not implement call');
}
