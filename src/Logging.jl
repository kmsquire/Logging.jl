module Logging

using Match

export debug, info, warn, err, critical, log,
       Logger,
       LogLevel, DEBUG, INFO, WARNING, ERROR, CRITICAL

include("enum.jl")

@enum LogLevel DEBUG INFO WARNING ERROR CRITICAL

type Logger
    name::String
    level::LogLevel
    output::IO
end

const _root = Logger("root", WARNING, STDERR)
Logger(;args...) = configure(Logger(WARNING, STDERR), args...)

for (fn,lvl,clr) in ((:debug,    DEBUG,    :cyan),
                     (:info,     INFO,     :blue),
                     (:warn,     WARNING,  :magenta),
                     (:err,    ERROR,    :red),
                     (:critical, CRITICAL, :red))

    @eval function $fn(msg::String, logger = _root)
        if $lvl >= logger.level
            Base.print_with_color($clr, logger.output, $lvl, ":", logger.name, ":", msg)
        end
    end
end

function configure(logger=_root; args...)
    for (tag, val) in args
        @match tag begin
            :io       => logger.output = val::IO
            :filename => logger.output = open(val, "w")
            :level    => logger.level  = val::LogLevel
            unk       => Base.error("Logging: unknown configure argument \"$unk\"")
        end
    end

    logger
end


end # module
