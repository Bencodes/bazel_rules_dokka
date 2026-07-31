"""Dokka toolchain implementation."""

load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary")
load(":providers.bzl", "DokkaConfigInfo", "DokkaToolchainInfo")

_GENERATOR_RUNNER_SOURCE = Label("//dokka/private:DokkaGeneratorRunner.kt")

def _runtime_jars(targets):
    return depset(
        transitive = [
            target[JavaInfo].transitive_runtime_jars
            for target in targets
        ],
    )

def _dokka_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        dokka = DokkaToolchainInfo(
            default_config = ctx.attr.default_config[DokkaConfigInfo],
            generator = ctx.attr.generator[DefaultInfo].files_to_run,
            multi_module_plugins = _runtime_jars(ctx.attr.multi_module_plugins),
            plugins = {
                "gfm": _runtime_jars(ctx.attr.gfm_plugins),
                "html": _runtime_jars(ctx.attr.html_plugins),
                "javadoc": _runtime_jars(ctx.attr.javadoc_plugins),
            },
        ),
    )]

_dokka_toolchain = rule(
    implementation = _dokka_toolchain_impl,
    attrs = {
        "default_config": attr.label(
            doc = "Default `dokka_config` used by targets without an override.",
            mandatory = True,
            providers = [DokkaConfigInfo],
        ),
        "generator": attr.label(
            cfg = "exec",
            doc = "Version-matched executable Dokka generator target.",
            executable = True,
            mandatory = True,
        ),
        "gfm_plugins": attr.label_list(
            cfg = "exec",
            doc = "Runtime jars needed for GFM output.",
            providers = [JavaInfo],
        ),
        "html_plugins": attr.label_list(
            cfg = "exec",
            doc = "Runtime jars needed for HTML output.",
            providers = [JavaInfo],
        ),
        "javadoc_plugins": attr.label_list(
            cfg = "exec",
            doc = "Runtime jars needed for Javadoc output.",
            providers = [JavaInfo],
        ),
        "multi_module_plugins": attr.label_list(
            cfg = "exec",
            doc = "Runtime jars needed for native multi-module HTML output.",
            providers = [JavaInfo],
        ),
    },
)

def dokka_generator(name, dokka_cli, jackson_databind, visibility = None):
    """Builds a version-matched in-process Dokka generator.

    Args:
        name: Name of the executable generator target.
        dokka_cli: Java target for the selected Dokka CLI artifact.
        jackson_databind: Java target for Jackson databind.
        visibility: Visibility of the generator target.
    """
    kt_jvm_binary(
        name = name,
        srcs = [_GENERATOR_RUNNER_SOURCE],
        main_class = "rules.dokka.DokkaGeneratorRunner",
        deps = [
            dokka_cli,
            jackson_databind,
        ],
        visibility = visibility,
    )

def dokka_toolchain(
        name,
        default_config,
        generator,
        html_plugins,
        gfm_plugins = [],
        javadoc_plugins = [],
        multi_module_plugins = [],
        exec_compatible_with = [],
        target_compatible_with = [],
        target_settings = [],
        visibility = None):
    """Defines a Dokka toolchain.

    A toolchain registered by a root module takes precedence over the bundled
    default, allowing consumers to select another Dokka release hermetically.

    Args:
        name: Name of the public `toolchain` target.
        default_config: `dokka_config` used by targets without an override.
        generator: Version-matched executable target for running Dokka.
        html_plugins: Java targets forming the HTML plugin classpath.
        gfm_plugins: Java targets forming the GFM plugin classpath.
        javadoc_plugins: Java targets forming the Javadoc plugin classpath.
        multi_module_plugins: Java targets forming the multi-module plugin classpath.
        exec_compatible_with: Execution platform constraints.
        target_compatible_with: Target platform constraints.
        target_settings: Config settings that must match this toolchain.
        visibility: Visibility of the public `toolchain` target.
    """
    implementation_name = name + "_implementation"
    _dokka_toolchain(
        name = implementation_name,
        default_config = default_config,
        generator = generator,
        gfm_plugins = gfm_plugins,
        html_plugins = html_plugins,
        javadoc_plugins = javadoc_plugins,
        multi_module_plugins = multi_module_plugins,
        visibility = ["//visibility:private"],
    )
    native.toolchain(
        name = name,
        exec_compatible_with = exec_compatible_with,
        target_compatible_with = target_compatible_with,
        target_settings = target_settings,
        toolchain = ":" + implementation_name,
        toolchain_type = Label("//dokka:toolchain_type"),
        visibility = visibility,
    )
