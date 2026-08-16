module Test.RunnerV2 exposing (toTests, Tests, UnitTest, FuzzTest, UnitTestExpectation(..), FuzzTestExpectation(..), tagTest)

{-| This is an "experts only" module that exposes functions needed to run tests.
A typical user will use an existing runner library for Node or the browser,
which is implemented using this interface. A list of these runners
can be found in the `README`.

This module supersedes the deprecated [Test.Runner](./Runner) module.


## Consume tests

@docs toTests, Tests, UnitTest, FuzzTest, UnitTestExpectation, FuzzTestExpectation, tagTest

-}

import Array exposing (Array)
import Random
import RandomRun exposing (RandomRun)
import Test exposing (Test)
import Test.Distribution exposing (DistributionReport(..))
import Test.Expectation exposing (Expectation(..))
import Test.Internal as Internal
import Test.Runner.Failure exposing (Reason(..))


{-| The `Test` type (from `Test.test`, `Test.fuzz` etc.) is opaque and nested.

This type represents an untangled `Test` value.

The lists of unit tests and fuzz tests only include tests that should be run,
after taking `skip` and `only` into account. The `seenSkip` and `seenOnly`
fields tell if any `skip` and/or `only` reduced the number of tests returned.
A runner could fail the test run if `skip` or `only` was used.

-}
type alias Tests =
    { unitTests : Array UnitTest
    , fuzzTests : Array FuzzTest
    , seenSkip : Bool
    , seenOnly : Bool
    }


{-| A unit test.

  - `tag` is set via `tagTest` and used by runners to cache test results.
  - `labels` starts with the test name, and then contains each `describe` up the hierarchy.
  - `thunk` is the function to call to run the test.

-}
type alias UnitTest =
    { tag : String
    , labels : List String
    , thunk : () -> UnitTestExpectation
    }


{-| A fuzz test. Like a unit test, with a few differences:

  - `thunk` takes some arguments, instead of just `()`:
      - The initial seed.
      - The number of fuzz runs.
      - A list of “fuzzer ints” from a previous run. If non-empty,
        the test will first be run with input based on those ints,
        which can quickly reproduce a previous failure. If that run
        succeeds (or the ints are no longer valid), the test continues
        with a regular random run.

  - `runs` contains the specified number of fuzz runs if `fuzzWith`
    was used.

-}
type alias FuzzTest =
    { tag : String
    , labels : List String
    , thunk : Random.Seed -> Int -> List Int -> FuzzTestExpectation
    , runs : Maybe Int
    }


{-| A unit test either passes, or fails with a description and reason.
-}
type UnitTestExpectation
    = UnitTestPass
    | UnitTestFail
        { description : String
        , reason : Reason
        }


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
    = FuzzTestPass { distributionReport : DistributionReport }
    | FuzzTestFail
        { given : Maybe String
        , fuzzerInts : List Int
        , description : String
        , reason : Reason
        , distributionReport : DistributionReport
        , rerunFailure : () -> ()
        }


{-| This lets runners tag tests with an identifier, which can be used to implement
caching of test results.
-}
tagTest : String -> Test -> Test
tagTest =
    Internal.ElmTestVariant__Tagged


{-| Turns an opaque and nested `Test` (from `Test.test`, `Test.fuzz` etc.)
into a flat structure that is easily consumable by runners.

Runners can collect all exposed `Test` values, join them up into
one single `Test` and then give it to this function. After that
they can start executing tests.

This replaces the deprecated [fromTest](#fromTest) function.

-}
toTests : Test -> Tests
toTests test =
    toTestsHelper "" [] test


toTestsHelper : String -> List String -> Test -> Tests
toTestsHelper tag labels test =
    case test of
        Internal.ElmTestVariant__UnitTest thunk ->
            { unitTests =
                Array.push
                    { tag = tag
                    , labels = labels
                    , thunk = \() -> thunk () |> toUnitTestExpectation
                    }
                    Array.empty
            , fuzzTests = Array.empty
            , seenSkip = False
            , seenOnly = False
            }

        Internal.ElmTestVariant__FuzzTest maybeRuns thunk ->
            { unitTests = Array.empty
            , fuzzTests =
                Array.push
                    { tag = tag
                    , labels = labels
                    , thunk = \seed runs fuzzerInts -> thunk seed runs fuzzerInts |> toFuzzTestExpectation
                    , runs = maybeRuns
                    }
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
            , seenOnly = hasOnly subTest
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


hasOnly : Test -> Bool
hasOnly test =
    case test of
        Internal.ElmTestVariant__UnitTest _ ->
            False

        Internal.ElmTestVariant__FuzzTest _ _ ->
            False

        Internal.ElmTestVariant__Labeled _ subTest ->
            hasOnly subTest

        Internal.ElmTestVariant__Tagged _ subTest ->
            hasOnly subTest

        Internal.ElmTestVariant__Skipped subTest ->
            hasOnly subTest

        Internal.ElmTestVariant__Only _ ->
            True

        Internal.ElmTestVariant__Batch subTests ->
            List.any hasOnly subTests


toUnitTestExpectation : Expectation -> UnitTestExpectation
toUnitTestExpectation expectation =
    case expectation of
        Pass _ ->
            UnitTestPass

        Fail { failData } ->
            UnitTestFail failData


toFuzzTestExpectation : Test.Expectation.FuzzTestExpectation -> FuzzTestExpectation
toFuzzTestExpectation expectation =
    case expectation of
        Test.Expectation.FuzzTestPass data ->
            FuzzTestPass data

        Test.Expectation.FuzzTestFail data ->
            FuzzTestFail
                { given = data.given
                , fuzzerInts = RandomRun.toList data.randomRun
                , description = data.description
                , reason = data.reason
                , distributionReport = data.distributionReport
                , rerunFailure = data.rerunFailure
                }
