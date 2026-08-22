/*

import Elm.Kernel.Scheduler exposing (binding, succeed)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Maybe exposing (Just, Nothing)
import Result exposing (Err, Ok)

*/

function _Test_runTimed(thunk)
{
  return __Scheduler_binding(function(callback)
  {
    var start = performance.now();
    var value = thunk(__Utils_Tuple0);
    var duration = performance.now() - start;
    callback(__Scheduler_succeed(__Utils_Tuple2(value, duration)));
  });
}

var _Test_runWithTryCatch = F2(function(thunk, a)
{
  try {
    // Attempt to run the thunk as normal.
    return __Result_Ok(thunk(a));
  } catch (err) {
    // If it throws, return an error instead of crashing.
    return __Result_Err(err.toString());
  }
});

var _Test_symbol = Symbol("_Test_symbol");

function _Test_tagTest(test)
{
  test[_Test_symbol] = true;
  return test;
}

function _Test_identifyTest(value)
{
  return value && value[_Test_symbol] ? __Maybe_Just(value) : __Maybe_Nothing;
}
