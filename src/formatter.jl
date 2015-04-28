const CONVERSION_REGEXP = r"%(((-?\d+)?(.\d+)?)(c|C|F|l|L|m|M|n|p|r|t|x|X|%|d({.+})*))"
const DEFAULT_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"
const BACKTRACE_CONVERSIONS = Set(Any['l', 'L', 'M', 'F'])

const SHORT_NAMES = ["DEBUG", "INFO", "WARN", "ERROR", "FATAL"]

function getbacktrace()
    btout = @compat Tuple{String,String,Int}[]
    for b in backtrace()
        code = ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Cint), b, true)
        #println(code)
        if length(code) == 5 && !code[4]
            push!(btout, (string(code[1]),string(code[2]),code[3]))
        end
    end
    return btout
end

function formatPattern(logger::Logger, level::LogLevel, msg...)
    btskip = 4
    logstring = Uint8[]
    matched = eachmatch(CONVERSION_REGEXP, logger.pattern) # match conversions params

    # Check if backtrace is needed
    needbacktrace = false
    for m in matched
        needbacktrace = m.captures[5][1] in BACKTRACE_CONVERSIONS
        needbacktrace && break
    end
    bt = needbacktrace ? getbacktrace()[btskip] : nothing

    # process conversion params
    s = 1
    for m in matched
        append!(logstring, logger.pattern[s:(m.offset-1)].data)

        # maximum width
        sym_maxw = m.captures[4] != nothing ? try @compat parse(Int, m.captures[4][2:end]); catch 0 end : 0
        # minimum width
        sym_minw = m.captures[3] != nothing ? try @compat parse(Int, m.captures[3]); catch 0 end : 0
        # formating symbol
        sym = m.captures[5][1]

        # process formating symbols
        if sym == 'm' # message
            for mp in msg
                append!(logstring, string(mp).data)
            end
        elseif sym == 'n' # newline
            @windows_only push!(logstring, 0x0d)
            push!(logstring, 0x0a)
        elseif sym == '%' # %
            push!(logstring, 0x25)
        else
            output = if sym == 'c' # category name (or logger name)
                category = logger.name
                leaf = logger
                while leaf != leaf.parent
                    leaf = leaf.parent
                    category = "$(leaf.name).$category"
                end
                category
            elseif sym == 'C' # module
                string(current_module())
            elseif sym == 'd' # date
                dformat = m.captures[end]
                tformat = dformat != nothing ? dformat[2:end-1] : DEFAULT_TIMESTAMP_FORMAT
                Libc.strftime(tformat,time())
            elseif sym == 'F' # file
                bt != nothing ? basename(bt[2]) : "NA"
            elseif sym == 'l' # module(func:line)
                bt != nothing ? "$(current_module())($(bt[1]):$(bt[3]))" : "NA"
            elseif sym == 'L' # line
                bt != nothing ? string(bt[3]) : "NA"
            elseif sym == 'M' # function
                bt != nothing ? string(bt[1]) : "NA"
            elseif sym == 'p' # level
                SHORT_NAMES[convert(Int, level)+1]
            elseif sym == 'r' # time elapsed (milliseconds)
                string(@compat round(Int, (time_ns()-INITIALIZED_AT)/10e6))
            elseif sym == 't' # thread or PID
                string(getpid())
            else
                ""
            end

            # adjust output
            lout = length(output)
            if lout > sym_maxw && sym_maxw != 0
                output = output[(lout-sym_maxw+1):end]
                lout = sym_maxw
            end
            if lout < abs(sym_minw) && sym_minw != 0
                output = sym_minw > 0 ? lpad(output, sym_minw, ' ') : rpad(output, -sym_minw, ' ')
            end
            append!(logstring, output.data)
        end
        s = m.offset+length(m.match)
    end
    if s < length(logger.pattern)
        append!(logstring, logger.pattern[s:end].data)
    end
    return bytestring(logstring)
end