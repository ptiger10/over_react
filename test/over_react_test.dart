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

// Currently dart_dev only runs tests on dart files that end with _test.
// So this file's name had to change to match.
// It can be changed back when that issue is taken care of.
// https://github.com/Workiva/dart_dev/issues/74
@TestOn('browser')
library ui_core_test;

import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:test/test.dart';

import 'over_react/component/abstract_transition_test.dart' as abstract_transition_test;
import 'over_react/component/dom_components_test.dart' as dom_components_test;
import 'over_react/component/prop_mixins_test.dart' as prop_mixins_test;
import 'over_react/component/resize_sensor_test.dart' as resize_sensor_test;
import 'over_react/component_declaration/component_base_test.dart' as component_base_test;
import 'over_react/component_declaration/component_type_checking_test.dart' as component_type_checking_test;
import 'over_react/component_declaration/transformer_helpers_test.dart' as transformer_helpers_test;
import 'over_react/component_declaration/transformer_integration_tests/abstract_accessor_integration_test.dart' as abstract_accessor_integration_test;
import 'over_react/component_declaration/transformer_integration_tests/accessor_mixin_integration_test.dart' as accessor_mixin_integration_test;
import 'over_react/component_declaration/transformer_integration_tests/component_integration_test.dart' as component_integration_test;
import 'over_react/component_declaration/transformer_integration_tests/namespaced_accessor_integration_test.dart' as namespaced_accessor_integration_test;
import 'over_react/component_declaration/transformer_integration_tests/stateful_component_integration_test.dart' as stateful_component_integration_test;
import 'over_react/util/class_names_test.dart' as class_names_test;
import 'over_react/util/constants_base_test.dart' as constants_base_test;
import 'over_react/util/css_value_util_test.dart' as css_value_util_test;
import 'over_react/util/dom_util_test.dart' as dom_util_test;
import 'over_react/util/event_helpers_test.dart' as event_helpers_test;
import 'over_react/util/guid_util_test.dart' as guid_util_test;
import 'over_react/util/handler_chain_util_test.dart' as handler_chain_util_test;
import 'over_react/util/map_util_test.dart' as map_util_test;
import 'over_react/util/pretty_print_test.dart' as pretty_print_test;
import 'over_react/util/prop_error_test.dart' as prop_error_test;
import 'over_react/util/react_wrappers_test.dart' as react_wrappers_test;
import 'over_react/util/rem_util_test.dart' as rem_util_test;
import 'over_react/util/string_util_test.dart' as string_util_test;
import 'over_react/util/test_mode_test.dart' as test_mode_test;

main() {
  setClientConfiguration();

  enableTestMode();

  abstract_transition_test.main();
  dom_components_test.main();
  prop_mixins_test.main();
  resize_sensor_test.main();
  component_base_test.main();
  component_type_checking_test.main();
  transformer_helpers_test.main();
  abstract_accessor_integration_test.main();
  accessor_mixin_integration_test.main();
  component_integration_test.main();
  namespaced_accessor_integration_test.main();
  stateful_component_integration_test.main();
  class_names_test.main();
  constants_base_test.main();
  css_value_util_test.main();
  dom_util_test.main();
  event_helpers_test.main();
  guid_util_test.main();
  handler_chain_util_test.main();
  map_util_test.main();
  pretty_print_test.main();
  prop_error_test.main();
  react_wrappers_test.main();
  rem_util_test.main();
  string_util_test.main();
  test_mode_test.main();
}
