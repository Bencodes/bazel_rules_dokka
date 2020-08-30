workspace(name = "rules_dokka")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

## Dokka Dependencies

load("//dokka:dependencies.bzl", "rules_dokka_dependencies")

rules_dokka_dependencies()

## Dokka Toolchains

load("//dokka:toolchains.bzl", "rules_dokka_toolchains")

rules_dokka_toolchains()

## Dokka Testing

SKILIB_VERSION = "1.0.2"

SKYLIB_SHA = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44"

http_archive(
    name = "bazel_skylib",
    sha256 = SKYLIB_SHA,
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{v}/bazel-skylib-{v}.tar.gz".format(v = SKILIB_VERSION),
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
