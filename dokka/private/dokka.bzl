"""Implementation of the `dokka` rule."""

load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load(":config.bzl", "validate_documented_visibilities")
load(":providers.bzl", "DokkaConfigInfo", "DokkaInfo")

_DOKKA_TOOLCHAIN_TYPE = Label("//dokka:toolchain_type")

def _module_name(ctx):
    return ctx.attr.module_name or ctx.label.name

def _module_path(ctx):
    return ctx.attr.module_path or ctx.label.package or ctx.label.name

def _compile_jars(dependencies):
    return depset(
        transitive = [
            dependency[JavaInfo].transitive_compile_time_jars
            for dependency in dependencies
        ],
    )

def _configuration(
        ctx,
        settings,
        output,
        plugin_jars,
        classpath,
        delay_template_substitution = False):
    module_name = _module_name(ctx)
    source_set = {
        "analysisPlatform": settings.analysis_platform,
        "classpath": [file.path for file in classpath.to_list()],
        "displayName": settings.source_set_display_name,
        "documentedVisibilities": settings.documented_visibilities,
        "includes": [file.path for file in ctx.files.includes],
        "jdkVersion": settings.jdk_version,
        "noJdkLink": settings.no_jdk_link,
        "noStdlibLink": settings.no_stdlib_link,
        "reportUndocumented": settings.report_undocumented,
        "samples": [file.path for file in ctx.files.samples],
        "skipDeprecated": settings.skip_deprecated,
        "skipEmptyPackages": settings.skip_empty_packages,
        "sourceRoots": [file.path for file in ctx.files.srcs],
        "sourceSetID": {
            "scopeId": module_name,
            "sourceSetName": settings.source_set_name,
        },
        "suppressAnnotatedWith": settings.suppress_annotated_with,
        "suppressedFiles": [file.path for file in ctx.files.suppressed_files],
    }
    if settings.api_version:
        source_set["apiVersion"] = settings.api_version
    if settings.language_version:
        source_set["languageVersion"] = settings.language_version

    configuration = {
        "delayTemplateSubstitution": delay_template_substitution,
        "failOnWarning": settings.fail_on_warning,
        "moduleName": module_name,
        "offlineMode": settings.offline_mode,
        "outputDir": output.path,
        "pluginsClasspath": [
            file.path
            for file in sorted(plugin_jars.to_list(), key = lambda file: file.path)
        ],
        "pluginsConfiguration": [
            {
                "fqPluginName": plugin,
                "serializationFormat": "JSON",
                "values": settings.plugins_configuration[plugin],
            }
            for plugin in sorted(settings.plugins_configuration.keys())
        ],
        "sourceSets": [source_set],
        "suppressInheritedMembers": settings.suppress_inherited_members,
        "suppressObviousFunctions": settings.suppress_obvious_functions,
    }
    if ctx.attr.module_version:
        configuration["moduleVersion"] = ctx.attr.module_version
    return configuration

def _register_dokka_action(
        ctx,
        configuration,
        documentation,
        configuration_content,
        classpath,
        plugin_jars,
        mnemonic,
        progress_message):
    ctx.actions.write(
        output = configuration,
        content = json.encode(configuration_content),
    )

    inputs = depset(
        direct = (
            [configuration] +
            ctx.files.includes +
            ctx.files.samples +
            ctx.files.srcs +
            ctx.files.suppressed_files
        ),
        transitive = [classpath, plugin_jars],
    )
    arguments = ctx.actions.args()
    arguments.add(configuration)

    ctx.actions.run(
        arguments = [arguments],
        executable = ctx.toolchains[_DOKKA_TOOLCHAIN_TYPE].dokka.generator,
        inputs = inputs,
        mnemonic = mnemonic,
        outputs = [documentation],
        progress_message = progress_message,
        toolchain = _DOKKA_TOOLCHAIN_TYPE,
    )

def _dokka_impl(ctx):
    toolchain = ctx.toolchains[_DOKKA_TOOLCHAIN_TYPE].dokka
    config = (
        ctx.attr.config[DokkaConfigInfo]
        if ctx.attr.config
        else toolchain.default_config
    )
    settings = config.settings
    validate_documented_visibilities(settings.documented_visibilities)

    format_plugins = toolchain.plugins[ctx.attr.format]
    if not format_plugins.to_list():
        fail(
            "The selected Dokka toolchain does not provide plugins for format '{}'.".format(
                ctx.attr.format,
            ),
        )

    plugin_jars = depset(transitive = [format_plugins, config.plugin_jars])
    classpath = _compile_jars(ctx.attr.deps)

    documentation = ctx.actions.declare_directory(ctx.label.name)
    configuration = ctx.actions.declare_file(ctx.label.name + ".dokka.json")
    _register_dokka_action(
        ctx = ctx,
        configuration = configuration,
        documentation = documentation,
        configuration_content = _configuration(
            ctx,
            settings,
            documentation,
            plugin_jars,
            classpath,
        ),
        classpath = classpath,
        plugin_jars = plugin_jars,
        mnemonic = "Dokka",
        progress_message = "Generating Dokka documentation for %{label}",
    )

    partial_configuration = None
    partial_documentation = None
    if ctx.attr.format == "html":
        partial_documentation = ctx.actions.declare_directory(
            ctx.label.name + ".dokka-partial",
        )
        partial_configuration = ctx.actions.declare_file(
            ctx.label.name + ".dokka-partial.json",
        )
        _register_dokka_action(
            ctx = ctx,
            configuration = partial_configuration,
            documentation = partial_documentation,
            configuration_content = _configuration(
                ctx,
                settings,
                partial_documentation,
                plugin_jars,
                classpath,
                delay_template_substitution = True,
            ),
            classpath = classpath,
            plugin_jars = plugin_jars,
            mnemonic = "DokkaPartial",
            progress_message = "Generating partial Dokka documentation for %{label}",
        )

    return [
        DefaultInfo(files = depset([documentation])),
        DokkaInfo(
            format = ctx.attr.format,
            includes = depset(ctx.files.includes),
            module_name = _module_name(ctx),
            module_path = _module_path(ctx),
            partial_documentation = partial_documentation,
        ),
        OutputGroupInfo(
            configuration = depset([configuration]),
            partial_configuration = depset(
                [partial_configuration] if partial_configuration else [],
            ),
        ),
    ]

_DOKKA_ATTRS = {
    "config": attr.label(
        doc = "Optional `dokka_config` overriding the toolchain default.",
        providers = [DokkaConfigInfo],
    ),
    "deps": attr.label_list(
        doc = "JVM dependencies added to Dokka's analysis classpath.",
        providers = [JavaInfo],
    ),
    "format": attr.string(
        default = "html",
        doc = "Documentation output format.",
        values = ["gfm", "html", "javadoc"],
    ),
    "includes": attr.label_list(
        allow_files = [".md"],
        doc = "Markdown files with module or package documentation.",
    ),
    "module_name": attr.string(
        doc = "Optional displayed module name. Defaults to the target name.",
    ),
    "module_path": attr.string(
        doc = (
            "Optional path for this module in aggregate documentation. " +
            "Defaults to the target's Bazel package path, or its name in the root package."
        ),
    ),
    "module_version": attr.string(
        doc = "Displayed module version.",
    ),
    "samples": attr.label_list(
        allow_files = [".java", ".kt", ".kts"],
        doc = "Sources containing functions referenced by @sample tags.",
    ),
    "srcs": attr.label_list(
        allow_empty = False,
        allow_files = [".java", ".kt", ".kts"],
        doc = "Kotlin or Java sources to document.",
        mandatory = True,
    ),
    "suppressed_files": attr.label_list(
        allow_files = [".java", ".kt", ".kts"],
        doc = "Source files excluded from generated documentation.",
    ),
}

dokka = rule(
    implementation = _dokka_impl,
    attrs = _DOKKA_ATTRS,
    doc = "Generates API documentation with Dokka.",
    toolchains = [_DOKKA_TOOLCHAIN_TYPE],
)
