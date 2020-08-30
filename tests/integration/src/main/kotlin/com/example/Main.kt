package com.example

fun main(args: Array<String>) {
}

class Foo {
    /**
    * Foo function
    */
    fun foo(): Unit { }
    
    /**
    * Private function
    */
    private fun isFoo() = false

    companion object {

        /**
        * Provides an instance of foo
        */
        fun bar() = Foo()
    }
}