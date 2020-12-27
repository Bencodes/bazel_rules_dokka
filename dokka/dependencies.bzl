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

    RULES_JVM_EXTERNAL = "3.3"
    RULES_JVM_EXTERNAL_SHA = "2a547d8d5e99703de8de54b6188ff0ed470b3bfc88e346972d1c8865e2688391"

    maybe(
        repo_rule = http_archive,
        name = "rules_jvm_external",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/{}.tar.gz".format(RULES_JVM_EXTERNAL),
        strip_prefix = "rules_jvm_external-{}".format(RULES_JVM_EXTERNAL),
        sha256 = RULES_JVM_EXTERNAL_SHA,
    )
