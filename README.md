# bazel_rules_dokka

Bazel rules for [Dokka](https://github.com/Kotlin/dokka) (documentation engine for Kotlin)

## Features

- Easy docs generation
- Default javadoc support
- Extension point for generating other doc types

## Usage

### `WORKSPACE` configuration

```starlalrk
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_DOKKA_VERSION = "..."
RULES_DOKKA_SHA = "..."

http_archive(
    name = "rules_dokka",
    sha256 = RULES_DOKKA_SHA,
    strip_prefix = "bazel_rules_dokka-{v}".format(v = RULES_DOKKA_VERSION),
    url = "https://github.com/Bencodes/bazel_rules_dokka/archive/v{v}.tar.gz".format(v = RULES_DOKKA_VERSION),
)

load("@rules_dokka//dokka:dependencies.bzl", "rules_dokka_dependencies")
rules_dokka_dependencies()

load("@rules_dokka//dokka:toolchains.bzl", "rules_dokka_toolchains")
rules_dokka_toolchains()
```

### `BUILD` configuration

```starlark
load("@rules_dokka//dokka:defs.bzl", "dokka")

dokka(
    name = "sample_dokka_docs",
    srcs = glob(["src/main/kotlin/**/*.kt"]),
)
```

### Supported `dokka-cli` arguments

See the Dokka [docs](https://github.com/Kotlin/dokka#using-the-command-line) for more information.

```starlark
dokka(
    name = "dokka_javadoc_test",
    srcs = [ ... ],
    moduleName = "name goes here",
    moduleDisplayName = "display name goes here",
    offlineMode = False,
    failOnWarning = False,
    noStdlibLink = False,
    noJdkLink = False,
    jdkVersion = "1.8",
    includeNonPublic = False,
    skipEmptyPackages = False,
    skipDeprecated = False,
    reportUndocumented = False,
    plugins = [
        ...
    ],
)
```

## Building

`$ bazel build //sample:sample_dokka_docs`

## Advanced

### Customizing the Dokka version

Call `rules_dokka_toolchains` with the `dokka_version` provided:

```starlark
rules_dokka_toolchains(dokka_version = "1.4.0-rc")
```

### Plugins

Download the Dokka Jeykell maven plugins by adding the following to your `WORKSPACE`. Don't forget to include the transitive dependencies!

```starlark
DOKKA_VERSION = "1.4.0-rc"

maven_install(
    name = "sample_deps",
    artifacts = [
        maven.artifact("org.jetbrains.dokka", "jekyll-plugin", DOKKA_VERSION),
        ...
    ],
)
```

Override the `plugins` attribute in your `BUILD` file with your own Dokka plugin and provide the classpath jars:

```starlark
dokka(
    name = "sample_dokka_docs",
    srcs = glob(["src/main/kotlin/**/*.kt"]),
    plugins = [
        "@sample_deps//:org_jetbrains_dokka_jekyll_plugin",
        ...
    ],
)
```
