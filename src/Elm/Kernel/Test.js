/*

import Result exposing (Err, Ok)

*/


var _Test_runThunk = F2(function(thunk, a)
{
  try {
    // Attempt to run the thunk as normal.
    return __Result_Ok(thunk(a));
  } catch (err) {
    // If it throws, return an error instead of crashing.
    return __Result_Err(err.toString());
  }
});
