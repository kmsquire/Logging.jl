using Logging

println("Setting level=DEBUG")
@Logging.configure(level=DEBUG)
# Work exactly like the logging functions, 
# WITH function call overhead

function macro_log_test()
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @err("error message")
    @critical("critical message")
end

macro_log_test()

println()
println("Setting level=WARNING")
@Logging.configure(level=WARNING)

macro_log_test()
