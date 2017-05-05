# Ensure that Logging.jl works when loaded with `import` rather than `using`
# since `import` does not bring constants like `DEBUG` into scope:
module InnerModule

import Logging
@Logging.configure(level=DEBUG)

using Compat
using Base.Test

function test_non_global_interpolation(y)
    @info("y = $y")
end

test_non_global_interpolation(5)

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

test_log_macro_common([(:@debug, true), (:@info, true), (:@warn, true),
    (:@err, true), (:@critical, true)])

@Logging.configure(level=INFO)
test_log_macro_common([(:@debug, false), (:@info, true), (:@warn, true),
    (:@err, true), (:@critical, true)])

@Logging.configure(level=WARNING)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, true),
    (:@err, true), (:@critical, true)])

@Logging.configure(level=ERROR)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@err, true), (:@critical, true)])

@Logging.configure(level=CRITICAL)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@err, false), (:@critical, true)])

@Logging.configure(level=OFF)
test_log_macro_common([(:@debug, false), (:@info, false), (:@warn, false),
    (:@err, false), (:@critical, false)])

end
