module Test.Internal.DebugLogs exposing (DebugLogs(..), Mode(..), empty, encode, getDebugLogsBeforeFirstTestRun, isEmpty, modeCollect, modePaused, modeUnbuffered, noDebugLogsForPassingFuzzTests, rerunFailureToCollectDebugLogs, runTestWithDurationAndCollectDebugLogs)

import Elm.Kernel.DebugLogs
import Json.Encode
import Task exposing (Task)


type DebugLogs
    = DebugLogs


type Mode
    = Mode


modeUnbuffered : Mode
modeUnbuffered =
    Elm.Kernel.DebugLogs.modeUnbuffered


modePaused : Mode
modePaused =
    Elm.Kernel.DebugLogs.modePaused


modeCollect : Mode
modeCollect =
    Elm.Kernel.DebugLogs.modeCollect


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


isEmpty : DebugLogs -> Bool
isEmpty =
    Elm.Kernel.DebugLogs.isEmpty


encode : DebugLogs -> Json.Encode.Value
encode =
    Elm.Kernel.DebugLogs.encode
