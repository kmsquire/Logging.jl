using Logging
using Base.Test
using Compat

function test_log_macro_common(flags)
    for (macroname, isshown) in flags
        ex = Expr(:macrocall, Symbol(macroname), "test message")
        if isshown
            @test ex |> macroexpand != :nothing
        else
            @test ex |> macroexpand == :nothing
        end
    end
end

module TestDebug
using Logging
import ..test_log_macro_common
Logging.@configure(level=DEBUG)
test_log_macro_common([(:@debug, true), (:@info, true), (:@warn, true),
    (:@error, true), (:@critical, true)])
end

module TestInfo
using Logging
import ..test_log_macro_common
Logging.@configure(level=INFO)
test_log_macro_common([(:@debug, false), (:@info, true), (:@warn, true),
    (:@error, true), (:@critical, true)])
end

module TestWarning
using Logging
import ..test_log_macro_common
Logging.@configure(level=WARNING)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, true),
    (:@error, true), (:@critical, true)])
end

module TestError
using Logging
import ..test_log_macro_common
Logging.@configure(level=ERROR)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@error, true), (:@critical, true)])
end

module TestCritical
using Logging
import ..test_log_macro_common
Logging.@configure(level=CRITICAL)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@error, false), (:@critical, true)])
end

module TestOff
using Logging
import ..test_log_macro_common
Logging.@configure(level=OFF)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@error, false), (:@critical, false)])
end
