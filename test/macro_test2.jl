using Logging
println("Level set to WARNING")
Logging.configure(level=WARNING) # this is the default

function macro_log_test()
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @err("error message")
    @critical("critical message")
end

macro_log_test()

println()
println("Setting level=DEBUG")
Logging.configure(level=DEBUG)
# No effect!
# DEBUG and INFO log levels were turned off
# and have zero overhead.
macro_log_test()

println()
println("Setting level=OFF")
Logging.configure(level=OFF) 
# No output!
# DEBUG and INFO log levels still have zero overhead.
# WARNING, ERROR, and CRITICAL levels still call
# their respective functions, but with no output.
macro_log_test()

println()
println("Setting level=DEBUG")
Logging.configure(level=DEBUG)
# Same as above
macro_log_test()
