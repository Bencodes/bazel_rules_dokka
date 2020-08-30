load("@rules_dokka//dokka:defs.bzl", "dokka")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

dokka(
    name = "dokka_javadoc_test",
    srcs = glob(["src/main/kotlin/**/*.kt"]),
    plugins = ["//dokka:dokka_javadoc"],
)

build_test(
    name = "does_build",
    targets = [
        ":dokka_javadoc_test",
    ],
)
