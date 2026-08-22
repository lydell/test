/*

import Elm.Kernel.Debug exposing (toString)
import Elm.Kernel.Json exposing (wrap)
import Elm.Kernel.Scheduler exposing (binding, succeed)

*/

var _DebugLogs_modeUnbuffered = __1_UNBUFFERED;
var _DebugLogs_modePaused = __1_PAUSED;
var _DebugLogs_modeCollect = __1_COLLECT;

var _DebugLogs_logs = [];
var _DebugLogs_used = false;
var _DebugLogs_mode = globalThis.__elmTestUnbufferedInitLogs ? __1_UNBUFFERED : __1_COLLECT;

var _DebugLogs_logsBeforeFirstTestRun = undefined;

var _DebugLogs_getDebugLogsBeforeFirstTestRun = __Scheduler_binding(
  function(callback)
  {
    if (_DebugLogs_logsBeforeFirstTestRun === undefined) {
      _DebugLogs_logsBeforeFirstTestRun = _DebugLogs_logs;
      _DebugLogs_logs = [];
      _DebugLogs_used = false;
    }
    callback(__Scheduler_succeed(_DebugLogs_logsBeforeFirstTestRun));
  });

var _Test_runTestWithDurationAndCollectDebugLogs = F3(function(preTestRunAction, thunk, mapper)
{
  return __Scheduler_binding(function(callback)
  {
    if (_DebugLogs_logsBeforeFirstTestRun === undefined) {
      _DebugLogs_logsBeforeFirstTestRun = _DebugLogs_logs;
    }
    _DebugLogs_logs = [];
    _DebugLogs_used = false;
    _DebugLogs_mode = preTestRunAction;
    var start = performance.now();
    var value = thunk(__Utils_Tuple0);
    var duration = performance.now() - start;
    callback(__Scheduler_succeed(A4(mapper, value, duration, _DebugLogs_logs, _DebugLogs_used)));
  });
});

function _Test_rerunFailureToCollectDebugLogs(rerunFailure)
{
  _DebugLogs_logs = [];
  _DebugLogs_used = false;
  _DebugLogs_mode = __1_COLLECT;
  rerunFailure(__Utils_Tuple0);
  return _DebugLogs_logs;
}

var _DebugLogs_empty = [];

function _DebugLogs_singleton(message)
{
  return [message];
}

function _DebugLogs_isEmpty(logs)
{
  return logs.length === 0;
}

function _DebugLogs_encode(logs)
{
  return __Json_wrap(logs);
}

var _Debug_log = F2(function(tag, value)
{
  _DebugLogs_used = true;
  switch (_DebugLogs_mode) {
    case __1_UNBUFFERED:
      console.error(tag + ': ' + __Debug_toString(value));
      break;
    case __1_COLLECT:
      _DebugLogs_logs.push(tag + ': ' + __Debug_toString(value));
      break;
    default:
      // __1_PAUSED: Do nothing.
  }
  return value;
});
