module Test.Expectation exposing
    ( Expectation(..)
    , FailData
    , FuzzTestExpectation(..)
    , fail
    , fuzzExpectationToExpectation
    )

import Test.Distribution exposing (DistributionReport(..))
import Test.Runner.Failure exposing (Reason)


type Expectation
    = -- `Pass` is not supposed to contain anything, but to avoid a breaking change
      -- we have to be able to store a `DistributionReport` as well.
      Pass DistributionReport
    | Fail BreakingChangeWorkaround


{-| This is supposed to _only_ contain `FailData`, but to avoid a breaking change
we have to be able to store data from `FuzzTestFail` as well.
-}
type alias BreakingChangeWorkaround =
    { failData : FailData
    , given : Maybe String
    , distributionReport : DistributionReport
    }


type alias FailData =
    { description : String
    , reason : Reason
    }


type FuzzTestExpectation
    = FuzzTestPass { distributionReport : DistributionReport }
    | FuzzTestFail
        { given : Maybe String
        , description : String
        , reason : Reason
        , distributionReport : DistributionReport
        }


fail : { description : String, reason : Reason } -> Expectation
fail { description, reason } =
    Fail
        { failData =
            { description = description
            , reason = reason
            }
        , given = Nothing
        , distributionReport = NoDistribution
        }


{-| Due to backwards compatibility, we are forced to do this type conversion,
without losing data – see `BreakingChangeWorkaround`.
-}
fuzzExpectationToExpectation : FuzzTestExpectation -> Expectation
fuzzExpectationToExpectation fuzzTestExpectation =
    case fuzzTestExpectation of
        FuzzTestPass { distributionReport } ->
            Pass distributionReport

        FuzzTestFail record ->
            Fail
                { failData =
                    { description = record.description
                    , reason = record.reason
                    }
                , given = record.given
                , distributionReport = record.distributionReport
                }
