"""
Tests for the Dokka rules
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dokka:defs.bzl", "dokka")

def _dokka_actions_test(ctx):
    env = analysistest.begin(ctx)

    _test_dokka_actions(ctx, env)
    _test_dokka_args(ctx, env)
    _test_dokka_inputs(ctx, env)
    _test_dokka_outputs(ctx, env)

    return analysistest.end(env)

def _test_dokka_actions(ctx, env):
    # Assert against the actions
    actions = analysistest.target_actions(env)
    asserts.equals(env, 1, len(actions))

    # Assert the sources that got passed in
    src = ctx.build_file_path.replace("/BUILD", "")

def _test_dokka_args(ctx, env):
    # Assert the joined args
    # TODO: Asserting against the 'bazel-out/darwin-fastbuild/bin' path probably isn't great
    action = analysistest.target_actions(env)[0]
    args = action.argv
    asserts.equals(env, 9, len(args))
    asserts.equals(env, [
        "bazel-out/host/bin/dokka/dokka_cli",
        "-pluginsClasspath",
        "bazel-out/darwin-fastbuild/bin/dokka/libdokka_javadoc.jar",
        "-outputDir",
        "bazel-out/darwin-fastbuild/bin/tests/dokka_javadoc_test",
        "-offlineMode",
        "-failOnWarning",
        "-sourceSet",
        "-moduleName module_name -moduleDisplayName module_display_name -noStdlibLink -noJdkLink -jdkVersion 1.8 -includeNonPublic -skipEmptyPackages -skipDeprecated -src tests/Foo.kt;tests/Bar.kt;tests/Baz.kt",
    ], args)

def _test_dokka_inputs(ctx, env):
    # Assert that there are 7 inputs
    action = analysistest.target_actions(env)[0]
    inputs = action.inputs.to_list()
    asserts.equals(env, 7, len(inputs))

    # Assert that the inputs are all there
    asserts.equals(env, [
        "libdokka_javadoc.jar",
        "Foo.kt",
        "Bar.kt",
        "Baz.kt",
        "dokka_Sdokka_Ucli-runfiles",
        "dokka_cli.jar",
        "dokka_cli",
    ], [file.basename for file in inputs])

def _test_dokka_outputs(ctx, env):
    target_under_test = analysistest.target_under_test(env)

    # Assert that there is only one registered output
    action = analysistest.target_actions(env)[0]
    outputs = action.outputs.to_list()
    asserts.equals(env, 1, len(outputs))

    # Assert that the output is a directory and that it matches the target name
    output = outputs[0]
    asserts.equals(env, True, output.is_directory)
    asserts.equals(env, target_under_test.label.name, output.basename)

dokka_actions_test = analysistest.make(_dokka_actions_test)

def test_suite(name):
    dokka(
        name = "dokka_javadoc_test",
        srcs = ["Foo.kt", "Bar.kt", "Baz.kt"],
        moduleName = "module_name",
        moduleDisplayName = "module_display_name",
        offlineMode = True,
        failOnWarning = True,
        noStdlibLink = True,
        noJdkLink = True,
        jdkVersion = "1.8",
        includeNonPublic = True,
        skipEmptyPackages = True,
        skipDeprecated = True,
        reportUndocumented = True,
        plugins = [
            "//dokka:dokka_javadoc",
        ],
    )

    dokka_actions_test(
        name = "dokka_actions_test",
        target_under_test = ":dokka_javadoc_test",
    )

    native.test_suite(
        name = name,
        tests = [
            ":dokka_actions_test",
            "//tests/integration:does_build",
        ],
    )
