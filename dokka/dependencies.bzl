"""
Dependencies required by Dokka
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_dokka_dependencies():
    # Kotlin
    RULES_KOTLIN_VERSION = "legacy-1.3.0"
    RULES_KOTLIN_SHA = "2ba27f0fa8305a28bc1b9b3a3f4e6b91064b3c0021365fa9344ba3af88657e1b"

    maybe(
        repo_rule = http_archive,
        name = "io_bazel_rules_kotlin",
        url = "https://github.com/bazelbuild/rules_kotlin/archive/{}.tar.gz".format(RULES_KOTLIN_VERSION),
        strip_prefix = "rules_kotlin-{}".format(RULES_KOTLIN_VERSION),
        sha256 = RULES_KOTLIN_SHA,
    )

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
