# Debug Macros

for (mac,fn,lvl) in ((:debug,    :(Logging.debug),    Logging.DEBUG),
                     (:info,     :(Logging.info),     Logging.INFO),
                     (:warn,     :(Logging.warn),     Logging.WARNING),
                     (:err,      :(Logging.err),      Logging.ERROR),
                     (:error,    :(Logging.err),      Logging.ERROR),
                     (:critical, :(Logging.critical), Logging.CRITICAL))

    @eval macro $mac(msg...)
        if length(msg) > 0 && isa(msg[1], Logging.Logger)
            level = msg[1].level
        else
            level = Logging._root.level
        end

        if $lvl > level
            esc(:nothing)
        else
            Expr(:call, $fn, msg...)
        end
    end

end
