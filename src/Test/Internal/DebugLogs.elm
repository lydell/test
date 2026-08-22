module Test.Internal.DebugLogs exposing (DebugLogs(..), clearLogs, empty, encode, getDebugLogsBeforeFirstTestRun, getLogs, getUsed, isEmpty, noDebugLogsForPassingFuzzTests, setPaused, setUnbuffered)

import Elm.Kernel.DebugLogs
import Json.Encode
import Task exposing (Task)


type DebugLogs
    = DebugLogs


setUnbuffered : Bool -> ()
setUnbuffered =
    Elm.Kernel.DebugLogs.setUnbuffered


setPaused : Bool -> ()
setPaused =
    Elm.Kernel.DebugLogs.setPaused


clearLogs : () -> ()
clearLogs =
    Elm.Kernel.DebugLogs.clearLogs


getLogs : () -> DebugLogs
getLogs =
    Elm.Kernel.DebugLogs.getLogs


getUsed : () -> Bool
getUsed =
    Elm.Kernel.DebugLogs.getUsed


isEmpty : DebugLogs -> Bool
isEmpty =
    Elm.Kernel.DebugLogs.isEmpty


empty : DebugLogs
empty =
    Elm.Kernel.DebugLogs.empty


noDebugLogsForPassingFuzzTests : DebugLogs
noDebugLogsForPassingFuzzTests =
    -- TODO: Should not be empty.
    empty


encode : DebugLogs -> Json.Encode.Value
encode =
    Elm.Kernel.DebugLogs.encode


getDebugLogsBeforeFirstTestRun : Task x DebugLogs
getDebugLogsBeforeFirstTestRun =
    Elm.Kernel.DebugLogs.getDebugLogsBeforeFirstTestRun
