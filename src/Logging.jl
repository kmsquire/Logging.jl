module Logging

import Base: show

export debug, info, warn, err, critical, log,
       @debug, @info, @warn, @err, @error, @critical,
       Logger,
       LogLevel, DEBUG, INFO, WARNING, ERROR, CRITICAL, OFF

include("enum.jl")

@enum LogLevel DEBUG INFO WARNING ERROR CRITICAL OFF

type Logger
    name::String
    level::LogLevel
    output::IO
    parent::Logger

    Logger(name::String, level::LogLevel, output::IO, parent::Logger) = new(name, level, output, parent)
    Logger(name::String, level::LogLevel, output::IO) = (x = new(); x.name = name; x.level=level; x.output=output; x.parent=x)
end

show(io::IO, logger::Logger) = print(io, "Logger(", join([logger.name, 
                                                          logger.level, 
                                                          logger.output,
                                                          logger.parent.name], ","), ")")

const _root = Logger("root", WARNING, STDERR)
Logger(name::String;args...) = configure(Logger(name, WARNING, STDERR, _root); args...)
Logger() = Logger("logger")

for (fn,lvl,clr) in ((:debug,    DEBUG,    :cyan),
                     (:info,     INFO,     :blue),
                     (:warn,     WARNING,  :magenta),
                     (:err,      ERROR,    :red),
                     (:critical, CRITICAL, :red))

    @eval function $fn(logger::Logger, msg...)
        if $lvl >= logger.level
            logstring = string(strftime("%d-%b %H:%M:%S",time()),":",$lvl, ":",logger.name,":", msg...,"\n")
            if isa(logger.output, Base.TTY)
                Base.print_with_color($(Expr(:quote, clr)), logger.output, logstring )
            else
                print(logger.output, logstring)
                flush(logger.output)
            end
        end
    end

    @eval $fn(msg...) = $fn(_root, msg...)

end

function configure(logger=_root; args...)
    for (tag, val) in args
        if tag == :parent
            logger.parent = parent = val::Logger
            logger.level = parent.level
            logger.output = parent.output
        end
    end
    
    for (tag, val) in args
        tag == :io       ? (logger.output = val::IO) :
        tag == :filename ? (logger.output = open(val, "a")) :
        tag == :level    ? (logger.level  = val::LogLevel) :
        tag == :parent   ?  nothing :  # handled above
                           (Base.error("Logging: unknown configure argument \"$unk\""))
    end

    logger
end

# Would love to generate these macros like the functions above, but it got too complicated

macro debug(msg...)
    if Logging.DEBUG < Logging._root.level
        :nothing
    else
        :(Logging.debug($(esc(msg))...))
    end
end

macro info(msg...)
    if Logging.INFO < Logging._root.level
        :nothing
    else
        :(Logging.info($(esc(msg))...))
    end
end

macro warn(msg...)
    if Logging.WARNING < Logging._root.level
        :nothing
    else
        :(Logging.warn($(esc(msg))...))
    end
end

macro err(msg...)
    if Logging.ERROR < Logging._root.level
        :nothing
    else
        :(Logging.err($(esc(msg))...))
    end
end

macro error(msg...)
    if Logging.ERROR < Logging._root.level
        :nothing
    else
        :(Logging.err($(esc(msg))...))
    end
end

macro critical(msg...)
    if Logging.CRITICAL < Logging._root.level
        :nothing
    else
        :(Logging.critical($(esc(msg))...))
    end
end


end # module
