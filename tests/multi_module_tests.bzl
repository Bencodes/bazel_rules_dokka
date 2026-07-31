"""Execution tests for multi-module Dokka publications."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//dokka:defs.bzl", "dokka_multi_module")

def multi_module_test_suite(name):
    """Defines tests for multi-module generated documentation.

    Args:
        name: Base name and tag for the generated tests.
    """
    dokka_multi_module(
        name = name + "_docs",
        modules = [
            "//tests/fixtures/generated_docs:api_docs",
            "//tests/fixtures/generated_docs:data_docs",
        ],
        title = "Project API Reference",
    )

    dokka_multi_module(
        name = name + "_configured_docs",
        config = "//tests/fixtures/generated_docs:publication_config",
        modules = [
            "//tests/fixtures/generated_docs:api_docs",
            "//tests/fixtures/generated_docs:data_docs",
        ],
        title = "Configured Project API Reference",
    )

    dokka_multi_module(
        name = name + "_derived_defaults_docs",
        modules = ["//tests/fixtures/derived_defaults:docs"],
        title = "Derived Module Defaults",
    )

    sh_test(
        name = name + "_generated_docs",
        srcs = ["multi_module_docs_test.sh"],
        args = ["$(rlocationpath :" + name + "_docs)"],
        data = [":" + name + "_docs"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        tags = [name],
    )

    sh_test(
        name = name + "_configured_publication",
        srcs = ["configured_publication_docs_test.sh"],
        args = ["$(rlocationpath :" + name + "_configured_docs)"],
        data = [":" + name + "_configured_docs"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        tags = [name],
    )

    sh_test(
        name = name + "_derived_module_defaults",
        srcs = ["derived_module_defaults_test.sh"],
        args = ["$(rlocationpath :" + name + "_derived_defaults_docs)"],
        data = [":" + name + "_derived_defaults_docs"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        tags = [name],
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
