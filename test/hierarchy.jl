module TestHierarchy
    using Base.Test
    using Logging

    # configre root logger
    output = IOBuffer()
    Logging.configure(level=DEBUG, io = output)
    root = Logging._root

    loggerA = "levelA"
    level1A = Logger(loggerA)

    loggerB = "levelB"
    level1B = Logger(loggerB, level = INFO)

    logger2 = "level2"
    level2 = Logger(logger2, parent=level1B)

    # test hierarchy
    @test root.parent == root
    @test level1A.parent == root
    @test level1A.parent == root
    @test level2.parent == level1B

    # test properties
    @test level1A.level == root.level
    @test level1B.level == INFO
    @test level2.level == level1B.level

end