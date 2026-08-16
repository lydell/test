module Test.RunnerV2 exposing
    ( toTests, Tests, getUnitTests, getFuzzTests, getSeenSkip, getSeenOnly
    , UnitTest, getUnitTestTag, getUnitTestLabels, runUnitTest
    , UnitTestExpectation(..), UnitTestFailData, getUnitTestFailDescription, getUnitTestFailReason
    , FuzzTest, getFuzzTestTag, getFuzzTestLabels, getFuzzTestRuns, runFuzzTest
    , FuzzTestExpectation(..), FuzzTestPassData, FuzzTestFailData, getFuzzTestPassDistributionReport, getFuzzTestFailDescription, getFuzzTestFailReason, getFuzzTestFailDistributionReport, getFuzzTestFailGiven, getFuzzTestFailFuzzerInts, rerunFuzzTestFailure
    , tagTest
    )

{-| This is an "experts only" module that exposes functions needed to run tests.
A typical user will use an existing runner library for Node or the browser,
which is implemented using this interface. A list of these runners
can be found in the `README`.

This module supersedes the deprecated [Test.Runner](./Runner) module.


## Consume tests

@docs toTests, Tests, getUnitTests, getFuzzTests, getSeenSkip, getSeenOnly


## Unit Tests

@docs UnitTest, getUnitTestTag, getUnitTestLabels, runUnitTest
@docs UnitTestExpectation, UnitTestFailData, getUnitTestFailDescription, getUnitTestFailReason


## Fuzz Tests

@docs FuzzTest, getFuzzTestTag, getFuzzTestLabels, getFuzzTestRuns, runFuzzTest
@docs FuzzTestExpectation, FuzzTestPassData, FuzzTestFailData, getFuzzTestPassDistributionReport, getFuzzTestFailDescription, getFuzzTestFailReason, getFuzzTestFailDistributionReport, getFuzzTestFailGiven, getFuzzTestFailFuzzerInts, rerunFuzzTestFailure


## Tag Tests

@docs tagTest

-}

import Array exposing (Array)
import Random
import RandomRun exposing (RandomRun)
import Test exposing (Test)
import Test.Distribution exposing (DistributionReport(..))
import Test.Expectation exposing (Expectation(..))
import Test.Internal as Internal
import Test.Runner.Failure exposing (Reason(..))


{-| The `Test` type (from `Test.test`, `Test.fuzz` etc.) is nested.
This type represents has flat arrays of tests and some metadata.

`Tests` is opaque for future extensibility. It contains the following:

  - `unitTests`: `Array UnitTest`
  - `fuzzTests`: `Array FuzzTest`
  - `seenSkip`: `Bool`
  - `seenOnly`: `Bool`

Use the various `get` functions to access each field.

The lists of unit tests and fuzz tests only include tests that should be run,
after taking `skip` and `only` into account. The `seenSkip` and `seenOnly`
fields tell if any `skip` and/or `only` reduced the number of tests returned.
A runner could fail the test run if `skip` or `only` was used.

-}
type Tests
    = Tests TestsData


type alias TestsData =
    { unitTests : Array UnitTest
    , fuzzTests : Array FuzzTest
    , seenSkip : Bool
    , seenOnly : Bool
    }


{-| Get unit tests.
-}
getUnitTests : Tests -> Array UnitTest
getUnitTests (Tests testsData) =
    testsData.unitTests


{-| Get fuzz tests.
-}
getFuzzTests : Tests -> Array FuzzTest
getFuzzTests (Tests testsData) =
    testsData.fuzzTests


{-| Get whether `skip` was used.
-}
getSeenSkip : Tests -> Bool
getSeenSkip (Tests testsData) =
    testsData.seenSkip


{-| Get whether `only` was used.
-}
getSeenOnly : Tests -> Bool
getSeenOnly (Tests testsData) =
    testsData.seenOnly


{-| A unit test.

`UnitTest` is opaque for future extensibility. It contains the following:

  - `tag`: `String`. The tag is set via `tagTest` and used by runners to cache test results.
  - `labels`: `List String`. The list starts with the test name, and then contains each `describe` up the hierarchy.
  - `thunk`: `() -> UnitTestExpectation`. This is the function to call to run the test.

Use the various `get` functions to access each field, as well as `runUnitTest` to run it.

-}
type UnitTest
    = UnitTest
        { tag : String
        , labels : List String
        , thunk : () -> UnitTestExpectation
        }


{-| Get the tag of the test.
-}
getUnitTestTag : UnitTest -> String
getUnitTestTag (UnitTest data) =
    data.tag


{-| Get the labels of the test.
-}
getUnitTestLabels : UnitTest -> List String
getUnitTestLabels (UnitTest data) =
    data.labels


{-| Run the unit test.
-}
runUnitTest : UnitTest -> UnitTestExpectation
runUnitTest (UnitTest data) =
    data.thunk ()


{-| A unit test. It’s similar to a unit test, but has more data, and running
it requires more arguments.

`FuzzTest` is opaque for future extensibility. It contains the following:

  - `tag`: `String`. The tag is set via `tagTest` and used by runners to cache test results.
  - `labels`: `List String`. The list starts with the test name, and then contains each `describe` up the hierarchy.
  - `runs`: `Maybe Int`. Contains the specified number of fuzz runs if `fuzzWith` was used.
  - `thunk`: `Random.Seed -> Int -> List Int -> FuzzTestExpectation`. This is the function to call to run the test.

Use the various `get` functions to access each field, as well as `runFuzzTest` to run it.

-}
type FuzzTest
    = FuzzTest
        { tag : String
        , labels : List String
        , runs : Maybe Int
        , thunk : Random.Seed -> Int -> List Int -> FuzzTestExpectation
        }


{-| Get the tag of the test.
-}
getFuzzTestTag : FuzzTest -> String
getFuzzTestTag (FuzzTest data) =
    data.tag


{-| Get the labels of the test.
-}
getFuzzTestLabels : FuzzTest -> List String
getFuzzTestLabels (FuzzTest data) =
    data.labels


{-| Get the the specified number of fuzz runs if `fuzzWith` was used.
-}
getFuzzTestRuns : FuzzTest -> Maybe Int
getFuzzTestRuns (FuzzTest data) =
    data.runs


{-| Run the fuzz test. It requires a few arguments:

  - The initial seed.
  - The number of fuzz runs.
  - A list of “fuzzer ints” from a previous run. If non-empty,
    the test will first be run with input based on those ints,
    which can quickly reproduce a previous failure. If that run
    succeeds (or the ints are no longer valid), the test continues
    with a regular random run.

-}
runFuzzTest : FuzzTest -> Random.Seed -> Int -> List Int -> FuzzTestExpectation
runFuzzTest (FuzzTest data) =
    data.thunk


{-| A unit test either passes, or fails with a description and reason.
-}
type UnitTestExpectation
    = UnitTestPass
    | UnitTestFail UnitTestFailData


{-| Information about a unit test failure.

`UnitTestFailData` is opaque for future extensibility. It contains the following:

  - `description`: `String`. The failure as described by the `Expect` module.
  - `reason`: `Reason`. See the `Reason` type.

Use the various `get` functions to access each field.

-}
type UnitTestFailData
    = UnitTestFailData
        { description : String
        , reason : Reason
        }


{-| Get the failure description.
-}
getUnitTestFailDescription : UnitTestFailData -> String
getUnitTestFailDescription (UnitTestFailData data) =
    data.description


{-| Get the failure reason.
-}
getUnitTestFailReason : UnitTestFailData -> Reason
getUnitTestFailReason (UnitTestFailData data) =
    data.reason


{-| A fuzz test either passes or fails. In both cases there can be a distribution report.
In case of failures, there is a description and reason just like for unit tests, but also
a few more fields:

  - `given` is the input to the test function that caused the failure, formatted with `Debug.toString`.
  - `fuzzerInts` is the internal fuzzer state that produced `given`. A runner can pass to the
    `thunk` of a `FuzzTest` to reproduce a previous failure.
  - `rerunFailure` is a function that runs the test function again with the input that
    caused the failure. Runners can use this to capture `Debug.log` calls of the failing run.

-}
type FuzzTestExpectation
    = FuzzTestPass FuzzTestPassData
    | FuzzTestFail FuzzTestFailData


{-| -}
type FuzzTestPassData
    = FuzzTestPassData { distributionReport : DistributionReport }


{-| -}
getFuzzTestPassDistributionReport : FuzzTestPassData -> DistributionReport
getFuzzTestPassDistributionReport (FuzzTestPassData data) =
    data.distributionReport


{-| Information about a fuzz test failure.

`FuzzTestFailData` is opaque for future extensibility. It contains the following:

  - `description`: `String`. The failure as described by the `Expect` module.
  - `reason`: `Reason`. See the `Reason` type.
  - `distributionReport`: `DistributionReport`. See the `DistributionReport` type.
  - `given`: `Maybe String`. This is the input to the test function that caused the failure, formatted with `Debug.toString`.
    A fuzz test can in unusual circumstances fail to even produce a `given` value, which is why it is `Maybe`.
  - `fuzzerInts`: `List Int`. This is the internal fuzzer state that produced `given`. A runner can pass to the
    `thunk` of a `FuzzTest` to reproduce a previous failure.
  - `rerunFailure` is a function that runs the test function again with the input that
    caused the failure. Runners can use this to capture `Debug.log` calls of the failing run.

Use the various `get` functions to access each field, as well as `rerunFuzzTestFailure` for running the failing run again.

-}
type FuzzTestFailData
    = FuzzTestFailData
        { description : String
        , reason : Reason
        , distributionReport : DistributionReport
        , given : Maybe String
        , fuzzerInts : List Int
        , rerunFailure : () -> ()
        }


{-| Get the failure description.
-}
getFuzzTestFailDescription : FuzzTestFailData -> String
getFuzzTestFailDescription (FuzzTestFailData data) =
    data.description


{-| Get the failure reason.
-}
getFuzzTestFailReason : FuzzTestFailData -> Reason
getFuzzTestFailReason (FuzzTestFailData data) =
    data.reason


{-| Get the distribution report.
-}
getFuzzTestFailDistributionReport : FuzzTestFailData -> DistributionReport
getFuzzTestFailDistributionReport (FuzzTestFailData data) =
    data.distributionReport


{-| Get the value that caused the test to fail.
-}
getFuzzTestFailGiven : FuzzTestFailData -> Maybe String
getFuzzTestFailGiven (FuzzTestFailData data) =
    data.given


{-| Get the internal fuzzer state that produced the test input that caused the failure.
-}
getFuzzTestFailFuzzerInts : FuzzTestFailData -> List Int
getFuzzTestFailFuzzerInts (FuzzTestFailData data) =
    data.fuzzerInts


{-| Rerun the test with the input that caused the failure.
-}
rerunFuzzTestFailure : FuzzTestFailData -> ()
rerunFuzzTestFailure (FuzzTestFailData data) =
    data.rerunFailure ()


{-| This lets runners tag tests with an identifier, which can be used to implement
caching of test results.
-}
tagTest : String -> Test -> Test
tagTest =
    Internal.ElmTestVariant__Tagged


{-| Turns a nested `Test` (from `Test.test`, `Test.fuzz` etc.)
into a flat structure that is easily consumable by runners.

Runners can collect all exposed `Test` values, join them up into
one single `Test` and then give it to this function. After that
they can start executing tests.

-}
toTests : Test -> Tests
toTests test =
    Tests (toTestsHelper "" [] test)


toTestsHelper : String -> List String -> Test -> TestsData
toTestsHelper tag labels test =
    case test of
        Internal.ElmTestVariant__UnitTest thunk ->
            { unitTests =
                Array.push
                    (UnitTest
                        { tag = tag
                        , labels = labels
                        , thunk = \() -> thunk () |> toUnitTestExpectation
                        }
                    )
                    Array.empty
            , fuzzTests = Array.empty
            , seenSkip = False
            , seenOnly = False
            }

        Internal.ElmTestVariant__FuzzTest maybeRuns thunk ->
            { unitTests = Array.empty
            , fuzzTests =
                Array.push
                    (FuzzTest
                        { tag = tag
                        , labels = labels
                        , thunk = \seed runs fuzzerInts -> thunk seed runs fuzzerInts |> toFuzzTestExpectation
                        , runs = maybeRuns
                        }
                    )
                    Array.empty
            , seenSkip = False
            , seenOnly = False
            }

        Internal.ElmTestVariant__Labeled label subTest ->
            toTestsHelper tag (label :: labels) subTest

        Internal.ElmTestVariant__Tagged newTag subTest ->
            toTestsHelper newTag labels subTest

        Internal.ElmTestVariant__Skipped subTest ->
            { unitTests = Array.empty
            , fuzzTests = Array.empty
            , seenSkip = True
            , seenOnly = False
            }

        Internal.ElmTestVariant__Only subTest ->
            let
                sub =
                    toTestsHelper tag labels subTest
            in
            { sub | seenOnly = True }

        Internal.ElmTestVariant__Batch subTests ->
            subTests
                |> List.foldl
                    (\subTest acc ->
                        let
                            sub =
                                toTestsHelper tag labels subTest

                            seenSkip =
                                acc.seenSkip || sub.seenSkip
                        in
                        case ( acc.seenOnly, sub.seenOnly ) of
                            ( False, False ) ->
                                { unitTests = Array.append acc.unitTests sub.unitTests
                                , fuzzTests = Array.append acc.fuzzTests sub.fuzzTests
                                , seenSkip = seenSkip
                                , seenOnly = False
                                }

                            ( True, False ) ->
                                { acc
                                    | seenSkip = seenSkip
                                    , seenOnly = True
                                }

                            ( False, True ) ->
                                { sub
                                    | seenSkip = seenSkip
                                    , seenOnly = True
                                }

                            ( True, True ) ->
                                { unitTests = Array.append acc.unitTests sub.unitTests
                                , fuzzTests = Array.append acc.fuzzTests sub.fuzzTests
                                , seenSkip = seenSkip
                                , seenOnly = True
                                }
                    )
                    { unitTests = Array.empty
                    , fuzzTests = Array.empty
                    , seenSkip = False
                    , seenOnly = False
                    }


toUnitTestExpectation : Expectation -> UnitTestExpectation
toUnitTestExpectation expectation =
    case expectation of
        Pass _ ->
            UnitTestPass

        Fail { failData } ->
            UnitTestFail (UnitTestFailData failData)


toFuzzTestExpectation : Test.Expectation.FuzzTestExpectation -> FuzzTestExpectation
toFuzzTestExpectation expectation =
    case expectation of
        Test.Expectation.FuzzTestPass data ->
            FuzzTestPass (FuzzTestPassData data)

        Test.Expectation.FuzzTestFail data ->
            FuzzTestFail
                (FuzzTestFailData
                    { description = data.description
                    , reason = data.reason
                    , distributionReport = data.distributionReport
                    , given = data.given
                    , fuzzerInts = RandomRun.toList data.randomRun
                    , rerunFailure = data.rerunFailure
                    }
                )
