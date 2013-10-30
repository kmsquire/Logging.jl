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

function configure(logger=_root; args...)
    for (tag, val) in args
        @match tag begin
            :io       => logger.output = val::IO
            :filename => logger.output = open(val, "a")
            :level    => logger.level  = val::LogLevel
            unk       => Base.error("Logging: unknown configure argument \"$unk\"")
        end
    end

    logger
end

Logger(name::String;args...) = configure(Logger(name, WARNING, STDERR); args...)

const _root = Logger("root")

for (fn,lvl,clr) in ((:debug,    DEBUG,    :cyan),
                     (:info,     INFO,     :blue),
                     (:warn,     WARNING,  :magenta),
                     (:err,      ERROR,    :red),
                     (:critical, CRITICAL, :red))

    @eval function $fn(msg::String, logger = _root)
        if $lvl >= logger.level
             logstring = string(strftime("%d-%b %H:%M:%S",time()),":",$lvl, ":",logger.name,":", msg,"\n")
             if isa(logger.output, Base.TTY)
            	Base.print_with_color($(Expr(:quote, clr)), logger.output, logstring )
             else
                print(logger.output, logstring)
             end
        end
    end
end


end # module
