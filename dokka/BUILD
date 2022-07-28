load("@rules_java//java:defs.bzl", "java_binary", "java_library")

java_binary(
    name = "dokka_cli",
    main_class = "org.jetbrains.dokka.MainKt",
    visibility = ["//visibility:public"],
    runtime_deps = [
        "@rules_dokka_dependencies//:org_jetbrains_dokka_dokka_analysis",
        "@rules_dokka_dependencies//:org_jetbrains_dokka_dokka_cli",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib",
    ],
)

java_library(
    name = "dokka_gfm",
    runtime_deps = [
        "@rules_dokka_dependencies//:org_jetbrains_dokka_dokka_base",
        "@rules_dokka_dependencies//:org_jetbrains_dokka_gfm_plugin",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_reflect",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib_jdk8",
        "@rules_dokka_dependencies//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
    ],
    visibility = ["//visibility:public"],
)

java_library(
    name = "dokka_html",
    runtime_deps = [
        "@rules_dokka_dependencies//:org_jetbrains_dokka_dokka_base",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_reflect",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib_jdk8",
        "@rules_dokka_dependencies//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@rules_dokka_dependencies//:org_jetbrains_kotlinx_kotlinx_html_jvm",
    ],
    visibility = ["//visibility:public"],
)

java_library(
    name = "dokka_javadoc",
    runtime_deps = [
        "@rules_dokka_dependencies//:com_soywiz_korlibs_korte_korte_jvm",
        "@rules_dokka_dependencies//:org_jetbrains_dokka_dokka_base",
        "@rules_dokka_dependencies//:org_jetbrains_dokka_javadoc_plugin",
        "@rules_dokka_dependencies//:org_jetbrains_dokka_kotlin_as_java_plugin",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_reflect",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib",
        "@rules_dokka_dependencies//:org_jetbrains_kotlin_kotlin_stdlib_jdk8",
        "@rules_dokka_dependencies//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@rules_dokka_dependencies//:org_jetbrains_kotlinx_kotlinx_html_jvm",
    ],
    visibility = ["//visibility:public"],
)
