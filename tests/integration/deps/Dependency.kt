package com.example.dependency

/** A compiled dependency made available to Dokka through its analysis classpath. */
open class Dependency {
    /** A member inherited by the documented source. */
    fun inheritedValue(): String = "dependency"
}
