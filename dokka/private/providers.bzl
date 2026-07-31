"""Providers exposed by the Dokka rules."""

DokkaConfigInfo = provider(
    doc = "Resolved policy and plugin settings supplied by `dokka_config`.",
    fields = {
        "plugin_jars": "Runtime jars for additional Dokka plugins.",
        "settings": "Resolved reusable Dokka settings.",
    },
)

DokkaInfo = provider(
    doc = "Module metadata consumed by Dokka publication rules.",
    fields = {
        "format": "The selected output format.",
        "includes": "Module and package documentation files.",
        "module_name": "The displayed module name.",
        "module_path": "The resolved path used in multi-module output.",
        "partial_documentation": "The delayed-template documentation tree, or None.",
    },
)

DokkaToolchainInfo = provider(
    doc = "Default configuration, executable, and plugin classpaths used to run Dokka.",
    fields = {
        "default_config": "DokkaConfigInfo used when a target does not override it.",
        "generator": "FilesToRunProvider for the version-matched Dokka generator.",
        "multi_module_plugins": "Runtime jars needed for native HTML aggregation.",
        "plugins": "Dictionary mapping output formats to plugin jar depsets.",
    },
)
