module Logging

import Base: show, info, warn

export debug, info, warn, err, critical, log,
       @debug, @info, @warn, @err, @error, @critical, @log,
       Logger,
       LogLevel, DEBUG, INFO, WARNING, ERROR, CRITICAL, OFF,
       LogFacility,
       SysLog

@enum LogLevel OFF=-1 CRITICAL=2 ERROR WARNING INFO=6 DEBUG

function Base.convert(::Type{LogLevel}, x::AbstractString)
    Dict("OFF"=>OFF,
         "CRITICAL"=>CRITICAL,
         "ERROR"=>ERROR,
         "WARNING"=>WARNING,
         "INFO"=>INFO,
         "DEBUG"=>DEBUG)[x]
end

@enum LogFacility LOG_KERN LOG_USER LOG_MAIL LOG_DAEMON LOG_AUTH LOG_SYSLOG LOG_LPR LOG_NEWS LOG_UUCP LOG_CRON LOG_AUTHPRIV LOG_LOCAL0=16 LOG_LOCAL1 LOG_LOCAL2 LOG_LOCAL3 LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7

type SysLog
    socket::UDPSocket
    ip::IPv4
    port::UInt16
    facility::LogFacility
    machine::AbstractString
    user::AbstractString
    maxlength::UInt16

    SysLog(host::AbstractString,
           port::Int,
           facility::LogFacility=LOG_USER,
           machine::AbstractString=gethostname(),
           user::AbstractString=Base.source_path()==nothing ? "" : basename(Base.source_path()),
           maxlength::Int=1024) = new(
        UDPSocket(),
        getaddrinfo(host),
        UInt16(port),
        facility,
        machine,
        user,
        UInt16(maxlength)
    )
end

LogOutput = Union{IO,SysLog}

type Logger
    name::AbstractString
    level::LogLevel
    output::Array{LogOutput,1}
    parent::Logger

    Logger(name::AbstractString, level::LogLevel, output::IO, parent::Logger) = new(name, level, [output], parent)
    Logger(name::AbstractString, level::LogLevel, output::IO) = (x = new(); x.name = name; x.level=level; x.output=[output]; x.parent=x)
    Logger{T<:LogOutput}(name::AbstractString, level::LogLevel, output::Array{T,1}, parent::Logger) = new(name, level, output, parent)
    Logger{T<:LogOutput}(name::AbstractString, level::LogLevel, output::Array{T,1}) = (x = new(); x.name = name; x.level=level; x.output=output; x.parent=x)
end

show(io::IO, logger::Logger) = print(io, "Logger(", join(Any[logger.name,
                                                             logger.level,
                                                             logger.output,
                                                             logger.parent.name], ","), ")")

const _root = Logger("root", WARNING, STDERR)
Logger(name::AbstractString;args...) = configure(Logger(name, WARNING, STDERR, _root); args...)
Logger() = Logger("logger")

write_log(syslog::SysLog, color::Symbol, msg::AbstractString) = send(syslog.socket, syslog.ip, syslog.port, length(msg) > syslog.maxlength ? msg[1:syslog.maxlength] : msg)
write_log{T<:IO}(output::T, color::Symbol, msg::AbstractString) = (print(output, msg); flush(output))
write_log(output::Base.TTY, color::Symbol, msg::AbstractString) = Base.print_with_color(color, output, msg)

function log(syslog::SysLog, level::LogLevel, color::Symbol, logger_name::AbstractString, msg...)
    # syslog needs a timestamp in the form: YYYY-MM-DDTHH:MM:SS-TZ:TZ
    t = time()
    timestamp = string(Libc.strftime("%Y-%m-%dT%H:%M:%S",t), Libc.strftime("%z",t)[1:end-2], ":", Libc.strftime("%z",t)[end-1:end])
    logstring = string("<", (UInt16(syslog.facility) << 3) + UInt16(level), ">1 ", timestamp, " ", syslog.machine, " ", syslog.user, " - - - ", level, ":", logger_name,":", msg...)
    write_log(syslog, color, logstring)
end

function log{T<:IO}(output::T, level::LogLevel, color::Symbol, logger_name::AbstractString, msg...)
    logstring = string(Libc.strftime("%d-%b %H:%M:%S",time()),":",level, ":",logger_name,":", msg...,"\n")
    write_log(output, color, logstring)
end

for (fn,lvl,clr) in ((:debug,    DEBUG,    :cyan),
                     (:info,     INFO,     :blue),
                     (:warn,     WARNING,  :magenta),
                     (:err,      ERROR,    :red),
                     (:critical, CRITICAL, :red))

    @eval function $fn(logger::Logger, msg...)
        if $lvl <= logger.level
            for output in logger.output
                log(output, $lvl, $(Expr(:quote, clr)), logger.name, msg...)
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
        tag == :io            ? typeof(val) <: AbstractArray ? (logger.output = val) :
                                                               (logger.output = [val::LogOutput]) :
        tag == :output        ? typeof(val) <: AbstractArray ? (logger.output = val) :
                                                               (logger.output = [val::LogOutput]) :
        tag == :filename      ? (logger.output = [open(val, "a")]) :
        tag == :level         ? (logger.level  = val::LogLevel) :
        tag == :override_info ? nothing :  # handled below
        tag == :parent        ? nothing :  # handled above
                                (Base.error("Logging: unknown configure argument \"$tag\""))
    end

    logger
end

override_info(;args...) = (:override_info, true) in args

macro configure(args...)
    _args = gensym()
    quote
        logger = Logging.configure($(args...))
        if Logging.override_info($(args...))
            function Base.info(msg::AbstractString...)
                Logging.info(Logging._root, msg...)
            end
        end
        include(joinpath(Pkg.dir("Logging"), "src", "logging_macros.jl"))
        logger
    end
end

end # module
