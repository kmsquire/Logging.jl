using Logging
println("Setting level=OFF")
@Logging.configure(level=OFF) 

function macro_log_test()
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @err("error message")
    @critical("critical message")
end

# No output
macro_log_test()

println()
println("Setting level=DEBUG")
@Logging.configure(level=DEBUG)
# No effect!
# All log levels were turned off and have zero overhead,
# but the level cannot be changed
macro_log_test()

# Note that the log level change will affect new 
# (not yet compiled) code:
@warn("This warning message will print.")
@debug("So will this debug message!")
