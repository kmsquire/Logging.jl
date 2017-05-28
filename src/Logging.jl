__precompile__()

module Logging

using Compat: @static
import Base: show

export Logger,
       LogLevel, DEBUG, INFO, WARNING, ERROR, CRITICAL, OFF,
       LogFacility,
       SysLog

function __init__()
    # Fix up _root output (issue #44)
    # _root is a global Logger which is included in the precompiled image
    # It's output goes to STDERR, but the actual STDERR object contained
    # in the precompiled image is different than the one available at runtime,
    # so we fix it by pointing to the correct one at runtime.
    _root.output[1] = STDERR
end

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

Base.show(io::IO, logger::Logger) = print(io, "Logger(", join(Any[logger.name,
                                                                  logger.level,
                                                                  logger.output,
                                                                  logger.parent.name], ","), ")")

const _root = Logger("root", WARNING, STDERR)
Logger(name::AbstractString;args...) = _configure(Logger(name, WARNING, STDERR, _root); args...)
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
                     (:error,    ERROR,    :red),
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

@deprecate err Logging.error

function _configure(logger=_root; args...)
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
                                (throw(ArgumentError("Logging: unknown configure argument \"$tag\"")))
    end

    logger
end

"""
Module which contains versions of the logging functions which
print a deprecation warning when used.

This is useful for transitioning users to either call the qualified
function names (e.g., `Logging.info`, `Logging.warn`, etc.) or explicitly
import the functions.
"""
module _Deprecated

import Logging

deprecation_printed = false

for fn in (:debug, :info, :warn, :error, :critical)
    @eval function $fn(args...)
        global deprecation_printed
        if !deprecation_printed
            Base.warn("""
                In the future, `using Logging` will not import the following
                logging functions:

                    debug
                    info
                    warn
                    error
                    critical

                You can either use these functions by qualifying them
                (e.g., `Logging.debug(...)`, `Logging.warn(...)`, etc.),
                or by explicitly importing them:

                    using Logging
                    import Logging: debug, info, warn, error, critical

                """)
            deprecation_printed = true
        end

        Logging.$fn(args...)
    end
end

end # module _Deprecated

function _imported_with_using()
    return all(isdefined.(names(Logging)))
end

function _logging_funcs_imported()
    # isdefined "reifies" any object that is defined, making it impossible
    # it to override it via import.  Therefore, we don't check
    # `info`, `warn`, and `error`, since these functions exist in
    # Base and won't be overridden if we check them here.
    return all(isdefined.([:debug, #=:info, :warn, :error,=# :critical]))
end

function _macro_loaded(macroname)
    expr = macroexpand(:($(macroname)("hi")))
    return expr.head != :error
end

function _macros_loaded()
    return all(_macro_loaded.([:@debug, :@info, :@warn, :@error, :@critical]))
end

_src_dir = dirname(@__FILE__)

# Keyword arguments x=1 passed to macros are parsed as Expr(:(=), :x, 1) but
# must be passed as Expr(:(kw), :x, 1) in Julia v0.6. 
@static if VERSION < v"0.6-"
    fix_kwarg(x) = x
else
    fix_kwarg(x::Symbol) = x
    fix_kwarg(e::Expr) = e.head == :(=) ? Expr(:(kw), e.args...) : e
end

macro configure(args...)
    quote
        logger = Logging.configure($([fix_kwarg(a) for a in args]...))

        if Logging._imported_with_using() && !Logging._logging_funcs_imported()
            # We assume that the user has not manually
            # imported the Logging functions, and we import
            # versions of these which print a deprecation warning
            try
                import Logging._Deprecated: info, warn, debug, error, critical
            catch
                Base.warn("Please call Logging.@configure from the top level (module) scope.")
            end
        end

        if Logging.override_info($([fix_kwarg(a) for a in args]...))
            function Base.info(msg::AbstractString...)
                Logging.info(Logging._root, msg...)
            end
        end

        if !Logging._macros_loaded()
            include(joinpath(Logging._src_dir, "logging_macros.jl"))
        end
        logger
    end
end

function configure(args...; kwargs...)
    Base.warn("""
        The functional form of Logging.configure(...) is no longer supported.
        Instead, call

            Logging.@configure(...)

        """)
end

end # module
