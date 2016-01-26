module TestHierarchy

using Base.Test
using Logging

# configre root logger
Logging.configure(level=DEBUG)
root = Logging._root


loggerA = Logger("loggerA")

# test hierarchy
@test root.parent == root
@test loggerA.parent == root

end