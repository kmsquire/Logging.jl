using Logging

println()
println("Testing moreinfo")

@Logging.configure(level=Logging.INFO)
@info("This should appear with date, time and logger name")

@Logging.configure(level=Logging.INFO, moreinfo=false)
@info("This should appear without date, time and logger name")

@Logging.configure(level=Logging.INFO, moreinfo=true)
@info("This should appear with date, time and logger name")
