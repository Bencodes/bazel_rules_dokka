"""Public API for rules_dokka."""

load("//dokka/private:config.bzl", _dokka_config = "dokka_config")
load("//dokka/private:dokka.bzl", _dokka = "dokka")
load("//dokka/private:multi_module.bzl", _dokka_multi_module = "dokka_multi_module")
load(
    "//dokka/private:providers.bzl",
    _DokkaConfigInfo = "DokkaConfigInfo",
    _DokkaInfo = "DokkaInfo",
)
load(
    "//dokka/private:toolchain.bzl",
    _dokka_generator = "dokka_generator",
    _dokka_toolchain = "dokka_toolchain",
)

DokkaConfigInfo = _DokkaConfigInfo
DokkaInfo = _DokkaInfo
dokka_config = _dokka_config
dokka = _dokka
dokka_generator = _dokka_generator
dokka_multi_module = _dokka_multi_module
dokka_toolchain = _dokka_toolchain
