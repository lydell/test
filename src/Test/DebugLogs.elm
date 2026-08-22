module Test.DebugLogs exposing (DebugLogs, empty, encode, getDebugLogsBeforeFirstTestRun, isEmpty)

{-| This is an "experts only" module that is used by test runners.
It deals with captured debug logs, so they can be displayed nicely
together with the test they came from.

@docs TODO

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
isEmpty : DebugLogs -> Bool
isEmpty =
    Test.Internal.DebugLogs.isEmpty


{-| TODO
-}
encode : DebugLogs -> Json.Encode.Value
encode =
    Test.Internal.DebugLogs.encode


{-| TODO
-}
empty : DebugLogs
empty =
    Test.Internal.DebugLogs.empty


{-| TODO

If you define `globalThis.__elmTestUnbufferedInitLogs` blah

-}
getDebugLogsBeforeFirstTestRun : Task x DebugLogs
getDebugLogsBeforeFirstTestRun =
    Test.Internal.DebugLogs.getDebugLogsBeforeFirstTestRun
