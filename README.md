Logging.jl: Basic logging for Julia
===================================

[![PkgEval: Julia v0.4](http://pkg.julialang.org/badges/Logging_0.4.svg)](http://pkg.julialang.org/?pkg=Logging) 
[![PkgEval: Julia v0.5](http://pkg.julialang.org/badges/Logging_0.5.svg)](http://pkg.julialang.org/?pkg=Logging)
[![PkgEval: Julia v0.6](http://pkg.julialang.org/badges/Logging_0.6.svg)](http://pkg.julialang.org/?pkg=Logging)

[![TravisCI: Linux, OSX](https://travis-ci.org/kmsquire/Logging.jl.svg?branch=master)](https://travis-ci.org/kmsquire/Logging.jl)
[![AppVeyorCI: Windows](https://ci.appveyor.com/api/projects/status/7cj5kaj8gcxmltho?svg=true)](https://ci.appveyor.com/project/kmsquire/logging-jl)

This module provides basic logging facilities for Julia.  It was inspired somewhat by logging in Python.

Install with `Pkg.add("Logging")` at the Julia prompt.

Usage
-----

If `log_test.jl` contains

```julia
using Logging
# default:
# Logging.configure(level=WARNING)

function log_test()
    Logging.debug("debug message")
    Logging.info("info message")
    Logging.warn("warning message")
    Logging.error("error message")
    Logging.critical("critical message")
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
30-Oct 22:09:20:DEBUG:root:debug message
30-Oct 22:09:20:INFO:root:info message
30-Oct 22:09:20:WARNING:root:warning message
30-Oct 22:09:20:ERROR:root:error message
30-Oct 22:09:20:CRITICAL:root:critical message

Setting level=INFO
30-Oct 22:09:20:INFO:root:info message
30-Oct 22:09:20:WARNING:root:warning message
30-Oct 22:09:20:ERROR:root:error message
30-Oct 22:09:20:CRITICAL:root:critical message

Setting level=WARNING
30-Oct 22:09:20:WARNING:root:warning message
30-Oct 22:09:20:ERROR:root:error message
30-Oct 22:09:20:CRITICAL:root:critical message

Setting level=ERROR
30-Oct 22:09:20:ERROR:root:error message
30-Oct 22:09:20:CRITICAL:root:critical message

Setting level=CRITICAL
30-Oct 22:09:20:CRITICAL:root:critical message
```

At the Julia prompt, the messages will display in color (debug=cyan,
info=blue, warning=purple, error=red, critical=red).

It is possible to change the stream the logger prints to. For example,
to print to a file:

```julia
julia> Logging.configure(output=open("logfile.log", "a"))
julia> log_test()
julia> readlines(open("logfile.log"))
3-element Array{Union(ASCIIString,UTF8String),1}:
 "24-mar 18:40:24:WARNING:root:warning message\n"
 "24-mar 18:40:24:ERROR:root:error message\n"
 "24-mar 18:40:24:CRITICAL:root:critical message\n"
```

Since it is common to log to files, there is a shortcut:

```julia
julia> Logging.configure(filename="logfile.log")
```

Logging Macros
--------------

For the functions above, there is always a small overhead for the
function call even when there is no log output. Logging.jl provides
macros which work like the functions above, but which remove this
overhead.

To use the macro versions, you MUST first configure them using
`@Logging.configure`.

```julia
using Logging
@Logging.configure(level=DEBUG)

function macro_log_test()
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @error("error message")
    @critical("critical message")
end

macro_log_test()
```

This gives:

```julia
30-Oct 22:28:51:DEBUG:root:debug message
30-Oct 22:28:51:INFO:root:info message
30-Oct 22:28:51:WARNING:root:warning message
30-Oct 22:28:51:ERROR:root:error message
30-Oct 22:28:51:CRITICAL:root:critical message
```

Later, we may decide to turn off logging entirely:

```julia
using Logging
@Logging.configure(level=OFF)

function macro_log_test()
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @error("error message")
    @critical("critical message")
end

macro_log_test()
```

This prevents any of the logging code from being generated.

Note that changing the log level later in the code will not have any
affect on previously evaluated functions, though it does affect future
evaluation:


```julia
using Logging
println("Setting level=OFF")
@Logging.configure(level=OFF)

function macro_log_test()
    # logging is OFF above!
    # these messages will never produce output
    # even if the log level is changed
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @error("error message")
    @critical("critical message")
end

macro_log_test()

println("Setting level=DEBUG")
Logging.configure(level=DEBUG)
macro_log_test()

@warn("This warning message will print.")
@debug("So will this debug message!")
```

produces:

```julia
Setting level=OFF
Setting level=DEBUG
30-Oct 23:26:16:WARNING:root:This warning message will print.
30-Oct 23:26:16:DEBUG:root:So will this debug message!
```

More advanced usage
-------------------

It is possible to create multiple loggers that each have their own log
levels and can write to different streams. A specific logger is used
by giving it as the first argument to the logger functions or macros.

```julia
julia> loggerA = Logger("loggerA");

julia> Logging.configure(loggerA, level=ERROR);

julia> Logging.configure(loggerA, filename="loggerA.log");

julia> loggerB = Logger("loggerB");

julia> Logging.configure(loggerB, level=DEBUG);

julia> critical(loggerA, "critical message from loggerA");

julia> readlines(open("loggerA.log"))
1-element Array{Union(ASCIIString,UTF8String),1}:
 "24-mar 18:48:23:CRITICAL:loggerA:critical message form loggerA\n"

julia> critical(loggerB, "critical message from loggerB");
24-mar 18:49:15:CRITICAL:loggerB:critical message from loggerB
```

A logger can be created with a parent logger. A logger with a parent inherits
the configuration of the parent.

```julia
julia> mum_logger = Logger("Mum");
julia> Logging.configure(mum_logger, level=INFO);
julia> son_logger = Logger("Son", parent=mum_logger);
julia> son_logger.level
INFO::Logging.LogLevel = 6
```
