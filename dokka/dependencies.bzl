"""
Dependencies required by Dokka
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_dokka_dependencies():
    """Fetches the dependencies for rules_dokka

    Fetches dependencies for the `rules_dokka` WORKSPACE.
    """

    # JVM External

    RULES_JVM_EXTERNAL = "4.2"
    RULES_JVM_EXTERNAL_SHA = "cd1a77b7b02e8e008439ca76fd34f5b07aecb8c752961f9640dea15e9e5ba1ca"

    maybe(
        repo_rule = http_archive,
        name = "rules_jvm_external",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/{}.tar.gz".format(RULES_JVM_EXTERNAL),
        strip_prefix = "rules_jvm_external-{}".format(RULES_JVM_EXTERNAL),
        sha256 = RULES_JVM_EXTERNAL_SHA,
    )
