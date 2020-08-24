workspace(name = "rules_dokka")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

## Dokka Dependencies

load("//dokka:dependencies.bzl", "rules_dokka_dependencies")

rules_dokka_dependencies()

## Dokka Toolchains

load("//dokka:toolchains.bzl", "rules_dokka_toolchains")

rules_dokka_toolchains()
