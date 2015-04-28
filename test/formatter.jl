module TestFormater
    using Logging
    using Base.Test
    using Compat

    # configre root logger
    Logging.configure(level=DEBUG, format=Logging.BASIC_CONVERSION_PATTERN)

    # setup test data
    logger = Logging._root
    loggerName   = logger.name
    testMessage1 = "TEST1"
    testMessage2 = "TEST2"
    testLevel    = DEBUG
    testTFormat  = "%Y-%m-%d"
    newline = @windows? "\r\n" : "\n"

    # BASIC_CONVERSION_PATTERN   = "%r %p %c: %m%n"
    msg = split(Logging.formatPattern(logger, testLevel, testMessage1), ' ')
    @test @compat parse(Int, msg[1]) > 0
    @test msg[2] == string(testLevel)
    @test msg[3] == "$loggerName:"
    @test msg[4] == "$testMessage1$newline"

    # multiple parameters
    msg = split(Logging.formatPattern(logger, testLevel, testMessage1, testMessage2), ' ')
    @test msg[4] == "$testMessage1$testMessage2$newline"

    # all patterns
    Logging.configure(logger, format="%c %C %d{$testTFormat} %F %l %L %M %p %r %t %% %m %n")
    msg = split(Logging.formatPattern(logger, testLevel, testMessage1), ' ')
    @test msg[1] == "$loggerName"
    @test msg[2] == string(current_module())
    @test msg[3] == strftime(testTFormat,time())
    @test msg[8] == string(testLevel)
    @test @compat parse(Int, msg[9]) > 0
    @test msg[10] == string(getpid())
    @test msg[11] == "%"
    @test msg[12] == testMessage1
    @test msg[13] == newline

    # logger hierarchy
    Logging.configure(logger, format="%c")
    msg = Logging.formatPattern(logger, testLevel, testMessage1)
    @test msg == logger.name

    nameL1 = "level1"
    loggerL1 = Logger(nameL1, format = logger.pattern) # TODO remove pattern setup
    msg = Logging.formatPattern(loggerL1, testLevel, testMessage1)
    @test msg == "$(logger.name).$nameL1"

    nameL2 = "level2"
    loggerL2 = Logger(nameL2, parent = loggerL1)
    msg = Logging.formatPattern(loggerL2, testLevel, testMessage1)
    loggerL2Name = "$(logger.name).$nameL1.$nameL2"
    @test msg == loggerL2Name

    # format modifiers
    Logging.configure(loggerL2, format= "%50c#%-50c#%.5c#%10.5c#%-10.5c#%20.10c")
    msg = split(Logging.formatPattern(loggerL2, testLevel, testMessage1), '#')
    trimed = loggerL2Name[(length(loggerL2Name)-4):end]
    @test msg[1] == lpad(loggerL2Name, 50, ' ')
    @test msg[2] == rpad(loggerL2Name, 50, ' ')
    @test msg[3] == trimed
    @test msg[4] == lpad(trimed, 10, ' ')
    @test msg[5] == rpad(trimed, 10, ' ')

    Logging.configure(logger, format= "%-10.15c")
    Logging.configure(loggerL2, format= "%-10.15c")
    @test Logging.formatPattern(logger, testLevel, testMessage1) == rpad(loggerName, 10, ' ')
    @test Logging.formatPattern(loggerL2, testLevel, testMessage1) == loggerL2Name[(length(loggerL2Name)-14):end]
end