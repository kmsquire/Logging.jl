module TestHierarchy

using Base.Test
using Logging

# configure root logger
Logging.configure(level=DEBUG)
root = Logging._root


loggerA = Logger("loggerA")
loggerB = Logger("loggerB", WARNING, [STDOUT,STDERR])

# test hierarchy
@test root.parent == root
@test loggerA.parent == root
@test loggerB.parent == loggerB

end
