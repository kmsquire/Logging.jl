Logging.jl: Basic logging for Julia
===================================

This module provides basic logging facilities for Julia.  It was inspired somewhat by logging in Python.

Install with `Pkg.add("Logging")` at the Julia prompt.

Usage
-----

If `log_test.jl` contains

```julia
using Logging

function log_test()
    debug("debug message")
    info("info message")
    warn("warning message")
    err("error message")
    critical("critical message")
end

println("Setting level=DEBUG")
Logging.configure(level=DEBUG)
log_test()

println()
println("Setting level=INFO")
Logging.configure(level=INFO)
log_test()

println()
println("Setting level=WARNING")
Logging.configure(level=WARNING)
log_test()

println()
println("Setting level=ERROR")
Logging.configure(level=ERROR)
log_test()

println()
println("Setting level=CRITICAL")
Logging.configure(level=CRITICAL)
log_test()
```

Running this gives 

```
julia> include("log_test.jl")
Setting level=DEBUG
LogLevel(DEBUG):root:debug message
LogLevel(INFO):root:info message
LogLevel(WARNING):root:warning message
LogLevel(ERROR):root:error message
LogLevel(CRITICAL):root:critical message

Setting level=INFO
LogLevel(INFO):root:info message
LogLevel(WARNING):root:warning message
LogLevel(ERROR):root:error message
LogLevel(CRITICAL):root:critical message

Setting level=WARNING
LogLevel(WARNING):root:warning message
LogLevel(ERROR):root:error message
LogLevel(CRITICAL):root:critical message

Setting level=ERROR
LogLevel(ERROR):root:error message
LogLevel(CRITICAL):root:critical message

Setting level=CRITICAL
LogLevel(CRITICAL):root:critical message
```

At the Julia prompt, the messages will display in color (debug=cyan,
info=blue, warning=purple, error=red, critical=red).