
importall Logging

# So that macro tests work
# Otherwise, log_test2 uses the default log level of WARNING
@Logging.configure(level=DEBUG)

function log_test()
    println("\nTesting function calls:\n")
    debug("debug message")
    info("info message")
    warn("warning message")
    err("error message")
    critical("critical message")
end

function log_test2()
    println("\nTesting macros:\n")
    @debug("debug message")
    @info("info message")
    @warn("warning message")
    @err("error message")
    @critical("critical message")
end

println("\nSetting level=DEBUG")
Logging.configure(level=DEBUG)
log_test()
log_test2()

println()
println("\nSetting level=INFO")
Logging.configure(level=INFO)
log_test()
log_test2()

println()
println("\nSetting level=WARNING")
Logging.configure(level=WARNING)
log_test()
log_test2()

println()
println("\nSetting level=ERROR")
Logging.configure(level=ERROR)
log_test()
log_test2()

println()
println("\nSetting level=CRITICAL")
Logging.configure(level=CRITICAL)
log_test()
log_test2()

