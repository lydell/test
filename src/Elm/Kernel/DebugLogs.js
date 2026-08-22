/*

import Elm.Kernel.Debug exposing (toString)
import Elm.Kernel.Json exposing (wrap)
import Elm.Kernel.Scheduler exposing (binding, succeed)

*/

var _DebugLogs_empty = [];
var _DebugLogs_logs = [];
var _DebugLogs_logsBeforeFirstTestRun = undefined;
var _DebugLogs_unbuffered = globalThis.__elmTestUnbufferedInitLogs;
var _DebugLogs_used = false;
var _DebugLogs_paused = false;

function _DebugLogs_setUnbuffered(unbuffered)
{
  _DebugLogs_unbuffered = unbuffered;
}

function _DebugLogs_setPaused(paused)
{
  _DebugLogs_paused = paused;
}

function _DebugLogs_clearLogs()
{
  if (_DebugLogs_logsBeforeFirstTestRun === undefined) {
    _DebugLogs_logsBeforeFirstTestRun = _DebugLogs_logs;
  }
  _DebugLogs_logs = [];
  _DebugLogs_used = false;
  _DebugLogs_unbuffered = false;
  _DebugLogs_paused = false;
}

function _DebugLogs_getLogs()
{
  return _DebugLogs_logs;
}

function _DebugLogs_getUsed()
{
  return _DebugLogs_used;
}

function _DebugLogs_isEmpty(logs)
{
  return logs.length === 0;
}

function _DebugLogs_encode(logs)
{
  return __Json_wrap(logs);
}

function _DebugLogs_getDebugLogsBeforeFirstTestRun()
{
  return __Scheduler_binding(function(callback)
  {
    if (_DebugLogs_logsBeforeFirstTestRun === undefined) {
      _DebugLogs_logsBeforeFirstTestRun = _DebugLogs_logs;
      _DebugLogs_logs = [];
    }
    callback(__Scheduler_succeed(_DebugLogs_logsBeforeFirstTestRun));
  });
}

var _Debug_log = F2(function(tag, value)
{
  _DebugLogs_used = true;
  if (_DebugLogs_unbuffered) {
    console.error(tag + ': ' + __Debug_toString(value));
  } else if (!_DebugLogs_paused) {
    _DebugLogs_logs.push(tag + ': ' + __Debug_toString(value));
  }
  return value;
});
