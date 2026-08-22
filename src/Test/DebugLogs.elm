module Test.DebugLogs exposing (DebugLogs, empty, encode, fromString, getDebugLogsBeforeFirstTestRun, isEmpty)

{-| This is an "experts only" module that is used by test runners.
It deals with captured debug logs, so they can be displayed nicely
together with the test they came from.

@docs DebugLogs, empty, encode, fromString, getDebugLogsBeforeFirstTestRun, isEmpty

-}

import Json.Encode
import Task exposing (Task)
import Test.Internal.DebugLogs


{-| TODO
-}
type alias DebugLogs =
    Test.Internal.DebugLogs.DebugLogs


{-| TODO
-}
empty : DebugLogs
empty =
    Test.Internal.DebugLogs.empty


{-| TODO
-}
fromString : String -> String -> DebugLogs
fromString =
    Test.Internal.DebugLogs.fromString


{-| TODO
-}
isEmpty : DebugLogs -> Bool
isEmpty =
    Test.Internal.DebugLogs.isEmpty


{-| TODO
-}
encode : DebugLogs -> Json.Encode.Value
encode =
    Test.Internal.DebugLogs.encode


{-| It’s possible to write code like this:

    defaultShape =
        makeShape 3
            |> Debug.log "shape"

    myTest =
        test "my test" <|
            \() ->
                defaultShape.sides
                    |> Expect.equal 3

In this case, `defaultShape` will be evaluated before the test is run!
This is due to Elm being an eager language and what the generated JavaScript looks like.

This means that when a test runner starts running its Elm code, there might already
be a few debug logs made. This task lets you retrieve them.

If you set `globalThis.elmTestPrintDebugLogsBeforeFirstTestToConsole` to a truthy
value, these debug logs will be printed to the console, and the returned `DebugLogs`
here will be empty. Runners might want to do this when using the
[runUnitTestWithUnbufferedLogs](Test.RunnerV2#runUnitTestWithUnbufferedLogs) and
[runFuzzTestWithUnbufferedLogs](Test.RunnerV2#runFuzzTestWithUnbufferedLogs) functions,
to consistently print all debug logs to the console.

-}
getDebugLogsBeforeFirstTestRun : Task x DebugLogs
getDebugLogsBeforeFirstTestRun =
    Test.Internal.DebugLogs.getDebugLogsBeforeFirstTestRun
