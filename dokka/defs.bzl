def _dokka_impl(ctx):
    # Inputs and outputs for bazel
    inputs = []
    outputs = []

    # Create the arguments
    # TODO: This should probably just be passed into dokka via an args file that bazel can consume via the inputs
    arguments = ctx.actions.args()

    # Pass in the plugins
    plugin_paths = ["{}".format(plugin.path) for plugin in ctx.files.plugins]
    arguments.add_joined("-pluginsClasspath", plugin_paths, join_with = ";")
    inputs.extend(ctx.files.plugins)

    # Pass in the output path
    docs_directory_name = "{name}".format(name = ctx.label.name)
    docs_directory = ctx.actions.declare_directory(docs_directory_name, sibling = None)
    arguments.add("-outputDir", docs_directory.path)
    outputs.append(docs_directory)

    # Pass in the sources
    # Note: Dokka CLI accepts nested source set arguments. Ex: -sourceSet `-foo foo -bar bar`
    src_args = []
    src_args.append("-moduleName {}".format(ctx.label.name))
    src_args.append("-src {}".format(";".join([src.path for src in ctx.files.srcs])))
    arguments.add("-sourceSet", " ".join([arg for arg in src_args]))
    inputs.extend(ctx.files.srcs)

    # Run the action that generates the dokka docs
    ctx.actions.run(
        mnemonic = "dokka",
        executable = ctx.executable._executable,
        inputs = inputs,
        outputs = outputs,
        progress_message = "Generating docs",
        arguments = [
            arguments,
        ],
    )

    return [
        DefaultInfo(
            files = depset(outputs),
            runfiles = ctx.runfiles(files = ctx.files.plugins),
        ),
    ]

dokka = rule(
    implementation = _dokka_impl,
    attrs = {
        "_executable": attr.label(
            default = Label("//dokka:dokka_cli"),
            executable = True,
            cfg = "host",
            providers = [JavaInfo],
        ),
        "moduleName": attr.label(
            default = None,
            doc = "Module name used as a part of source set ID when declaring dependent source sets",
        ),
        "moduleDisplayName": attr.label(
            default = None,
            doc = "Displayed module name",
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".kt", ".kts"],
            allow_empty = False,
            doc = "Kotlin source files to generate docs for",
        ),
        "noStdlibLink": attr.bool(
            default = False,
            doc = "Disable linking to online kotlin-stdlib documentation",
        ),
        "noJdkLink": attr.bool(
            default = False,
            doc = "Disable linking to online JDK documentation",
        ),
        "jdkVersion": attr.label(
            default = None,
            doc = "Version of JDK to use for linking to JDK JavaDoc",
        ),
        "includeNonPublic": attr.bool(
            default = False,
            doc = "Include protected and private code",
        ),
        "skipEmptyPackages": attr.bool(
            default = True,
            doc = "Do not create index pages for empty packages",
        ),
        "plugins": attr.label_list(
            allow_empty = False,
            providers = [JavaInfo],
            default = ["//dokka:dokka_javadoc"],
            doc = "Sources for the plugin",
        ),
    },
)
