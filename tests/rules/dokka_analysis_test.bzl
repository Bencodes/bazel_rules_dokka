"""Analysis tests for the Dokka rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dokka:defs.bzl", "DokkaInfo")

def _actions_with_mnemonic(env, mnemonic):
    return [
        action
        for action in analysistest.target_actions(env)
        if action.mnemonic == mnemonic
    ]

def _contains_fragment(values, fragment):
    return any([fragment in value for value in values])

def _write_action_for_output(env, basename):
    actions = [
        action
        for action in _actions_with_mnemonic(env, "FileWrite")
        if basename in [output.basename for output in action.outputs.to_list()]
    ]
    asserts.equals(env, 1, len(actions))
    return actions[0] if actions else None

def _dokka_configuration_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.true(env, DokkaInfo in target)
    info = target[DokkaInfo]
    asserts.equals(env, "gfm", info.format)
    asserts.equals(env, "fixture-module", info.module_name)
    asserts.equals(env, "tests/rules", info.module_path)
    asserts.equals(env, None, info.partial_documentation)

    documentation_files = target[DefaultInfo].files.to_list()
    asserts.equals(env, 1, len(documentation_files))
    documentation = documentation_files[0]
    asserts.true(env, documentation.is_directory)
    asserts.equals(env, "analysis_fixture", documentation.basename)

    configuration_file = None
    write_actions = _actions_with_mnemonic(env, "FileWrite")
    asserts.equals(env, 1, len(write_actions))
    if write_actions:
        configuration_file = write_actions[0].outputs.to_list()[0]
        asserts.equals(env, "analysis_fixture.dokka.json", configuration_file.basename)
        configuration = json.decode(write_actions[0].content)
        asserts.equals(env, False, configuration["delayTemplateSubstitution"])
        asserts.equals(env, "fixture-module", configuration["moduleName"])
        asserts.equals(env, "1.2.3", configuration["moduleVersion"])
        asserts.equals(env, False, configuration["offlineMode"])
        asserts.equals(env, True, configuration["failOnWarning"])
        asserts.equals(env, False, configuration["suppressObviousFunctions"])
        asserts.equals(env, True, configuration["suppressInheritedMembers"])
        asserts.equals(
            env,
            [{
                "fqPluginName": "org.jetbrains.dokka.base.DokkaBase",
                "serializationFormat": "JSON",
                "values": "{\"footerMessage\":\"rules_dokka\"}",
            }],
            configuration["pluginsConfiguration"],
        )
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "gfm-plugin"),
        )
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "libcustom_plugin.jar"),
        )
        asserts.false(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "javadoc-plugin"),
        )

        source_set = configuration["sourceSets"][0]
        asserts.equals(env, "jvm", source_set["analysisPlatform"])
        asserts.equals(env, "Fixture JVM", source_set["displayName"])
        asserts.equals(
            env,
            {
                "scopeId": "fixture-module",
                "sourceSetName": "fixtureMain",
            },
            source_set["sourceSetID"],
        )
        asserts.equals(env, ["PUBLIC", "INTERNAL"], source_set["documentedVisibilities"])
        asserts.equals(env, True, source_set["reportUndocumented"])
        asserts.equals(env, True, source_set["skipEmptyPackages"])
        asserts.equals(env, False, source_set["skipDeprecated"])
        asserts.equals(env, 17, source_set["jdkVersion"])
        asserts.equals(env, "2.1", source_set["languageVersion"])
        asserts.equals(env, "2.1", source_set["apiVersion"])
        asserts.equals(env, True, source_set["noStdlibLink"])
        asserts.equals(env, True, source_set["noJdkLink"])
        asserts.equals(env, ["com.example.InternalApi"], source_set["suppressAnnotatedWith"])
        asserts.true(env, _contains_fragment(source_set["sourceRoots"], "Fixture.kt"))
        asserts.true(env, _contains_fragment(source_set["includes"], "module.md"))
        asserts.true(env, _contains_fragment(source_set["samples"], "Sample.kt"))
        asserts.true(env, _contains_fragment(source_set["suppressedFiles"], "Suppressed.kt"))
        asserts.true(env, _contains_fragment(source_set["classpath"], "libdependency"))

    dokka_actions = _actions_with_mnemonic(env, "Dokka")
    asserts.equals(env, 1, len(dokka_actions))
    if dokka_actions and configuration_file:
        action = dokka_actions[0]
        asserts.equals(env, configuration_file.path, action.argv[-1])
        asserts.equals(env, [documentation.path], [
            output.path
            for output in action.outputs.to_list()
        ])
        input_basenames = [file.basename for file in action.inputs.to_list()]
        for expected_input in [
            "Fixture.kt",
            "Sample.kt",
            "Suppressed.kt",
            "analysis_fixture.dokka.json",
            "libcustom_plugin.jar",
            "module.md",
        ]:
            asserts.true(env, expected_input in input_basenames)
        asserts.true(env, _contains_fragment(input_basenames, "libdependency"))

    return analysistest.end(env)

def _dokka_defaults_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    info = target[DokkaInfo]
    write_actions = _actions_with_mnemonic(env, "FileWrite")
    asserts.equals(env, 2, len(write_actions))

    normal_write = _write_action_for_output(env, "defaults_fixture.dokka.json")
    if normal_write:
        configuration = json.decode(normal_write.content)
        asserts.equals(env, False, configuration["delayTemplateSubstitution"])
        asserts.equals(env, "defaults_fixture", configuration["moduleName"])
        asserts.equals(env, True, configuration["offlineMode"])
        asserts.equals(env, False, configuration["failOnWarning"])
        asserts.equals(env, True, configuration["suppressObviousFunctions"])
        asserts.equals(env, False, configuration["suppressInheritedMembers"])
        asserts.false(env, "moduleVersion" in configuration)
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "dokka-base"),
        )
        asserts.false(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "gfm-plugin"),
        )
        asserts.false(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "javadoc-plugin"),
        )

        source_set = configuration["sourceSets"][0]
        asserts.equals(env, ["PUBLIC"], source_set["documentedVisibilities"])
        asserts.equals(env, False, source_set["reportUndocumented"])
        asserts.equals(env, False, source_set["skipEmptyPackages"])
        asserts.equals(env, False, source_set["skipDeprecated"])
        asserts.false(env, "languageVersion" in source_set)
        asserts.false(env, "apiVersion" in source_set)

    partial_write = _write_action_for_output(
        env,
        "defaults_fixture.dokka-partial.json",
    )
    if partial_write:
        partial_configuration = json.decode(partial_write.content)
        asserts.equals(env, True, partial_configuration["delayTemplateSubstitution"])
        asserts.true(
            env,
            partial_configuration["outputDir"].endswith("defaults_fixture.dokka-partial"),
        )

    asserts.equals(env, "html", info.format)
    asserts.equals(env, "defaults_fixture", info.module_name)
    asserts.equals(env, "tests/rules", info.module_path)
    asserts.true(env, info.partial_documentation.is_directory)
    asserts.equals(
        env,
        "defaults_fixture.dokka-partial",
        info.partial_documentation.basename,
    )

    partial_actions = _actions_with_mnemonic(env, "DokkaPartial")
    asserts.equals(env, 1, len(partial_actions))
    if partial_actions and partial_write:
        asserts.equals(
            env,
            partial_write.outputs.to_list()[0].path,
            partial_actions[0].argv[-1],
        )
        asserts.equals(env, [info.partial_documentation.path], [
            output.path
            for output in partial_actions[0].outputs.to_list()
        ])

    return analysistest.end(env)

def _dokka_multi_module_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    documentation_files = target[DefaultInfo].files.to_list()
    asserts.equals(env, 1, len(documentation_files))
    documentation = documentation_files[0]
    asserts.true(env, documentation.is_directory)
    asserts.equals(env, "multi_module_fixture", documentation.basename)

    configuration_file = None
    write_actions = _actions_with_mnemonic(env, "FileWrite")
    asserts.equals(env, 1, len(write_actions))
    if write_actions:
        configuration_file = write_actions[0].outputs.to_list()[0]
        asserts.equals(
            env,
            "multi_module_fixture.dokka.json",
            configuration_file.basename,
        )
        configuration = json.decode(write_actions[0].content)
        asserts.equals(env, "Project API Reference", configuration["moduleName"])
        asserts.equals(env, "rules_dokka_multi_module", configuration["runnerMode"])
        asserts.equals(env, False, configuration["delayTemplateSubstitution"])
        asserts.equals(env, True, configuration["finalizeCoroutines"])
        asserts.equals(env, True, configuration["failOnWarning"])
        asserts.equals(env, False, configuration["offlineMode"])
        asserts.equals(env, False, configuration["suppressObviousFunctions"])
        asserts.equals(env, True, configuration["suppressInheritedMembers"])
        asserts.equals(env, [], configuration["sourceSets"])
        asserts.equals(
            env,
            [{
                "fqPluginName": "org.jetbrains.dokka.base.DokkaBase",
                "serializationFormat": "JSON",
                "values": "{\"footerMessage\":\"shared config\"}",
            }],
            configuration["pluginsConfiguration"],
        )
        asserts.true(
            env,
            _contains_fragment(configuration["includes"], "module.md"),
        )
        for plugin in [
            "all-modules-page-plugin",
            "analysis-markdown",
            "dokka-base",
            "templating-plugin",
        ]:
            asserts.true(
                env,
                _contains_fragment(configuration["pluginsClasspath"], plugin),
            )
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "libcustom_plugin.jar"),
        )

        modules = configuration["modules"]
        asserts.equals(env, 2, len(modules))
        asserts.equals(env, "API", modules[0]["name"])
        asserts.equals(env, "api", modules[0]["relativePathToOutputDirectory"])
        asserts.true(
            env,
            modules[0]["sourceOutputDirectory"].endswith(
                "module_api_fixture.dokka-partial",
            ),
        )
        asserts.true(
            env,
            _contains_fragment(modules[0]["includes"], "module.md"),
        )
        asserts.equals(env, "docs", modules[1]["name"])
        asserts.equals(
            env,
            "tests/rules/nested",
            modules[1]["relativePathToOutputDirectory"],
        )
        asserts.equals(env, [], modules[1]["includes"])

    actions = _actions_with_mnemonic(env, "DokkaMultiModule")
    asserts.equals(env, 1, len(actions))
    if actions and configuration_file:
        action = actions[0]
        asserts.equals(env, configuration_file.path, action.argv[-1])
        asserts.equals(env, [documentation.path], [
            output.path
            for output in action.outputs.to_list()
        ])
        input_basenames = [file.basename for file in action.inputs.to_list()]
        asserts.true(
            env,
            _contains_fragment(input_basenames, "all-modules-page-plugin"),
        )
        for expected_input in [
            "module.md",
            "module_api_fixture.dokka-partial",
            "docs.dokka-partial",
        ]:
            asserts.true(env, expected_input in input_basenames)

    return analysistest.end(env)

def _dokka_reusable_config_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    write_actions = _actions_with_mnemonic(env, "FileWrite")
    asserts.equals(env, 1, len(write_actions))
    if write_actions:
        configuration = json.decode(write_actions[0].content)
        asserts.equals(env, "configured-module", configuration["moduleName"])
        asserts.equals(env, "4.5.6", configuration["moduleVersion"])
        asserts.equals(env, False, configuration["offlineMode"])
        asserts.equals(env, True, configuration["failOnWarning"])
        asserts.equals(env, False, configuration["suppressObviousFunctions"])
        asserts.equals(env, True, configuration["suppressInheritedMembers"])
        asserts.equals(
            env,
            [{
                "fqPluginName": "org.jetbrains.dokka.base.DokkaBase",
                "serializationFormat": "JSON",
                "values": "{\"footerMessage\":\"shared config\"}",
            }],
            configuration["pluginsConfiguration"],
        )
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "javadoc-plugin"),
        )
        asserts.true(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "libcustom_plugin.jar"),
        )
        asserts.false(
            env,
            _contains_fragment(configuration["pluginsClasspath"], "gfm-plugin"),
        )

        source_set = configuration["sourceSets"][0]
        asserts.equals(env, "Configured JVM", source_set["displayName"])
        asserts.equals(
            env,
            {
                "scopeId": "configured-module",
                "sourceSetName": "configuredMain",
            },
            source_set["sourceSetID"],
        )
        asserts.equals(env, ["PUBLIC", "PROTECTED"], source_set["documentedVisibilities"])
        asserts.equals(env, True, source_set["reportUndocumented"])
        asserts.equals(env, False, source_set["skipEmptyPackages"])
        asserts.equals(env, True, source_set["skipDeprecated"])
        asserts.equals(env, 17, source_set["jdkVersion"])
        asserts.equals(env, "2.0", source_set["languageVersion"])
        asserts.equals(env, "2.0", source_set["apiVersion"])
        asserts.equals(env, True, source_set["noStdlibLink"])
        asserts.equals(env, True, source_set["noJdkLink"])
        asserts.equals(env, ["com.example.ExperimentalApi"], source_set["suppressAnnotatedWith"])
        asserts.true(env, _contains_fragment(source_set["includes"], "module.md"))

    dokka_actions = _actions_with_mnemonic(env, "Dokka")
    asserts.equals(env, 1, len(dokka_actions))
    if dokka_actions:
        input_basenames = [file.basename for file in dokka_actions[0].inputs.to_list()]
        asserts.true(env, "libcustom_plugin.jar" in input_basenames)

    asserts.equals(env, "javadoc", target[DokkaInfo].format)
    return analysistest.end(env)

def _invalid_visibility_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "documented_visibilities contains invalid values")
    return analysistest.end(env)

def _duplicate_module_path_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "both resolve to module path 'api'")
    return analysistest.end(env)

def _duplicate_module_name_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "both resolve to module name 'docs'")
    return analysistest.end(env)

def _invalid_module_path_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "has invalid module_path '../invalid'")
    return analysistest.end(env)

def _non_html_module_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "only accepts HTML `dokka` targets")
    return analysistest.end(env)

_dokka_configuration_test = analysistest.make(_dokka_configuration_test_impl)
_dokka_defaults_test = analysistest.make(_dokka_defaults_test_impl)
_dokka_multi_module_test = analysistest.make(_dokka_multi_module_test_impl)
_dokka_reusable_config_test = analysistest.make(_dokka_reusable_config_test_impl)
_invalid_config_test = analysistest.make(
    _invalid_visibility_test_impl,
    expect_failure = True,
)
_duplicate_module_path_test = analysistest.make(
    _duplicate_module_path_test_impl,
    expect_failure = True,
)
_duplicate_module_name_test = analysistest.make(
    _duplicate_module_name_test_impl,
    expect_failure = True,
)
_invalid_module_path_test = analysistest.make(
    _invalid_module_path_test_impl,
    expect_failure = True,
)
_non_html_module_test = analysistest.make(
    _non_html_module_test_impl,
    expect_failure = True,
)

def dokka_analysis_test_suite(name):
    """Defines the Dokka analysis test suite.

    Args:
        name: Name of the generated test suite.
    """
    _dokka_configuration_test(
        name = name + "_configuration",
        target_under_test = ":analysis_fixture",
    )
    _dokka_defaults_test(
        name = name + "_defaults",
        target_under_test = ":defaults_fixture",
    )
    _dokka_multi_module_test(
        name = name + "_multi_module",
        target_under_test = ":multi_module_fixture",
    )
    _dokka_reusable_config_test(
        name = name + "_reusable_config",
        target_under_test = ":configured_fixture",
    )
    _invalid_config_test(
        name = name + "_invalid_config",
        target_under_test = ":invalid_config_fixture",
    )
    _duplicate_module_path_test(
        name = name + "_duplicate_module_path",
        target_under_test = ":duplicate_aggregate_fixture",
    )
    _duplicate_module_name_test(
        name = name + "_duplicate_module_name",
        target_under_test = ":duplicate_module_name_aggregate_fixture",
    )
    _invalid_module_path_test(
        name = name + "_invalid_module_path",
        target_under_test = ":invalid_path_aggregate_fixture",
    )
    _non_html_module_test(
        name = name + "_non_html_module",
        target_under_test = ":non_html_aggregate_fixture",
    )
    native.test_suite(
        name = name,
        tests = [
            ":" + name + "_configuration",
            ":" + name + "_defaults",
            ":" + name + "_duplicate_module_name",
            ":" + name + "_duplicate_module_path",
            ":" + name + "_invalid_config",
            ":" + name + "_invalid_module_path",
            ":" + name + "_multi_module",
            ":" + name + "_non_html_module",
            ":" + name + "_reusable_config",
        ],
    )
