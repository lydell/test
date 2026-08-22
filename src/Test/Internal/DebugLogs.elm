module Test.Internal.DebugLogs exposing (DebugLogs(..), Mode(..), empty, encode, fromString, getDebugLogsBeforeFirstTestRun, isEmpty, modeCollect, modeConsoleLog, modeIgnore, noDebugLogsForPassingFuzzTests, rerunFailureToCollectDebugLogs, runTestWithDurationAndCollectDebugLogs)

import Elm.Kernel.DebugLogs
import Json.Encode
import Task exposing (Task)


type DebugLogs
    = DebugLogs


type Mode
    = Mode


modeConsoleLog : Mode
modeConsoleLog =
    Elm.Kernel.DebugLogs.modeConsoleLog


modeCollect : Mode
modeCollect =
    Elm.Kernel.DebugLogs.modeCollect


modeIgnore : Mode
modeIgnore =
    Elm.Kernel.DebugLogs.modeIgnore


getDebugLogsBeforeFirstTestRun : Task x DebugLogs
getDebugLogsBeforeFirstTestRun =
    Elm.Kernel.DebugLogs.getDebugLogsBeforeFirstTestRun


runTestWithDurationAndCollectDebugLogs : Mode -> (() -> a) -> (a -> Float -> DebugLogs -> Bool -> b) -> Task x b
runTestWithDurationAndCollectDebugLogs =
    Elm.Kernel.DebugLogs.runTestWithDurationAndCollectDebugLogs


rerunFailureToCollectDebugLogs : (() -> a) -> DebugLogs
rerunFailureToCollectDebugLogs =
    Elm.Kernel.DebugLogs.rerunFailureToCollectDebugLogs


empty : DebugLogs
empty =
    Elm.Kernel.DebugLogs.empty


noDebugLogsForPassingFuzzTests : DebugLogs
noDebugLogsForPassingFuzzTests =
    Elm.Kernel.DebugLogs.singleton "For passing fuzz tests, Debug.log is not shown, since showing logs from lots of runs is pretty confusing. Tip: Use Debug.todo to fail a test from anywhere if you want some logs to appear."


fromString : String -> String -> DebugLogs
fromString =
    Elm.Kernel.DebugLogs.empty fromString


isEmpty : DebugLogs -> Bool
isEmpty =
    Elm.Kernel.DebugLogs.isEmpty


encode : DebugLogs -> Json.Encode.Value
encode =
    Elm.Kernel.DebugLogs.encode
