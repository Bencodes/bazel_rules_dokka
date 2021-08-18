"""
Toolchains required by Dokka
"""

load("@rules_jvm_external//:defs.bzl", "maven_install")
load("@rules_jvm_external//:specs.bzl", "maven")

def rules_dokka_toolchains(dokka_version = "1.4.0"):
    maven_install(
        name = "rules_dokka_dependencies",
        artifacts = [
            maven.artifact("org.jetbrains.dokka", "dokka-cli", dokka_version),
            maven.artifact("org.jetbrains.dokka", "dokka-analysis", dokka_version),
            maven.artifact("org.jetbrains.dokka", "dokka-base", dokka_version),
            maven.artifact("org.jetbrains.dokka", "gfm-plugin", dokka_version),
            maven.artifact("org.jetbrains.dokka", "javadoc-plugin", dokka_version),
            maven.artifact("org.jetbrains.kotlin", "kotlin-stdlib-jdk8", dokka_version),
            maven.artifact("org.jetbrains.kotlin", "kotlin-stdlib", dokka_version),
            maven.artifact("org.jetbrains.kotlin", "kotlin-reflect", dokka_version),
            maven.artifact("org.jetbrains.kotlinx", "kotlinx-coroutines-core", "1.3.8-1.4.0-rc"),
            maven.artifact("org.jetbrains.kotlinx", "kotlinx-html-jvm", "0.7.1-1.4-M3"),
        ],
        repositories = [
            "https://jcenter.bintray.com/",
        ],
    )
