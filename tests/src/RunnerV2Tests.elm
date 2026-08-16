module RunnerV2Tests exposing (all)

import Array
import Expect
import Helpers exposing (expectPass)
import Random
import Test exposing (..)
import Test.Runner.Failure
import Test.RunnerV2 as Runner exposing (Tests, UnitTestExpectation(..))


all : Test
all =
    describe "Test.RunnerV2.toTests"
        [ describe "test length"
            [ test "an only inside another only should ignore the non-only siblings" <|
                \_ ->
                    let
                        suite =
                            describe "three tests"
                                [ test "passes" expectPass
                                , Test.only <|
                                    describe "two tests"
                                        [ test "fails" testImpl
                                        , Test.only (test "is an only" testImpl)
                                        ]
                                ]
                    in
                    toTests suite
                        |> Expect.equal
                            { seenSkip = False
                            , seenOnly = True
                            , unitTestsLabels = [ [ "three tests", "two tests", "is an only" ] ]
                            , fuzzTestsLabels = []
                            }
            , test "should keep all only tests spread among siblings" <|
                \_ ->
                    let
                        suite =
                            describe "root"
                                [ test "A" expectPass
                                , describe "B"
                                    [ Test.only (test "1" testImpl)
                                    ]
                                , Test.only <|
                                    describe "C"
                                        [ test "1" testImpl
                                        , Test.only (test "2" testImpl)
                                        , describe "3"
                                            [ test "X" testImpl
                                            , Test.only (test "Y" testImpl)
                                            , test "Z" testImpl
                                            ]
                                        ]
                                , describe "D"
                                    [ Test.only (test "1" testImpl)
                                    ]
                                ]
                    in
                    toTests suite
                        |> Expect.equal
                            { seenSkip = False
                            , seenOnly = True
                            , unitTestsLabels =
                                [ [ "root", "B", "1" ]
                                , [ "root", "C", "2" ]
                                , [ "root", "C", "3", "Y" ]
                                , [ "root", "D", "1" ]
                                ]
                            , fuzzTestsLabels = []
                            }
            , test "a skip inside an only takes effect" <|
                \_ ->
                    let
                        suite =
                            describe "three tests"
                                [ test "passes" expectPass
                                , Test.only <|
                                    describe "two tests"
                                        [ test "fails" testImpl
                                        , Test.skip (test "is skipped" testImpl)
                                        ]
                                ]
                    in
                    toTests suite
                        |> Expect.equal
                            { seenSkip = True
                            , seenOnly = True
                            , unitTestsLabels = [ [ "three tests", "two tests", "fails" ] ]
                            , fuzzTestsLabels = []
                            }
            , test "an only inside a skip has no effect" <|
                \_ ->
                    let
                        suite =
                            describe "three tests"
                                [ test "passes" expectPass
                                , Test.skip <|
                                    describe "two tests"
                                        [ test "fails" testImpl
                                        , Test.only (test "is skipped" testImpl)
                                        ]
                                ]
                    in
                    toTests suite
                        |> Expect.equal
                            { seenSkip = True
                            , seenOnly = False
                            , unitTestsLabels = [ [ "three tests", "passes" ] ]
                            , fuzzTestsLabels = []
                            }
            , test "a skip inside another skip has no effect" <|
                \_ ->
                    let
                        suite =
                            describe "three tests"
                                [ test "passes" expectPass
                                , Test.skip <|
                                    describe "two tests"
                                        [ test "fails" testImpl
                                        , Test.skip (test "is skipped" testImpl)
                                        ]
                                ]
                    in
                    toTests suite
                        |> Expect.equal
                            { seenSkip = True
                            , seenOnly = False
                            , unitTestsLabels = [ [ "three tests", "passes" ] ]
                            , fuzzTestsLabels = []
                            }
            , test "when all tests are skipped, we get empty arrays of tests" <|
                \_ ->
                    toTests (Test.skip <| test "passes" expectPass)
                        |> Expect.equal
                            { seenSkip = True
                            , seenOnly = False
                            , unitTestsLabels = []
                            , fuzzTestsLabels = []
                            }
            , test "a test that does not use only or skip is marked as having seen neither of those" <|
                \_ ->
                    toTests (test "passes" expectPass)
                        |> Expect.equal
                            { seenSkip = False
                            , seenOnly = False
                            , unitTestsLabels = [ [ "passes" ] ]
                            , fuzzTestsLabels = []
                            }
            ]
        , describe "tagging tests"
            [ test "runners can tag tests with an identifier of choice" <|
                \() ->
                    let
                        suite =
                            concat
                                [ Runner.tagTest "tag1" (test "standalone test" testImpl)
                                , Runner.tagTest "tag2"
                                    (describe "describe"
                                        [ test "nested" testImpl
                                        ]
                                    )
                                , Runner.tagTest "tag3"
                                    (concat
                                        [ test "concatenated" testImpl
                                        ]
                                    )
                                ]
                    in
                    Runner.toTests suite
                        |> Runner.getUnitTests
                        |> Array.toList
                        |> List.map
                            (\unitTest ->
                                ( Runner.getUnitTestLabels unitTest |> List.reverse
                                , Runner.getUnitTestTag unitTest
                                )
                            )
                        |> Expect.equal
                            [ ( [ "standalone test" ], "tag1" )
                            , ( [ "describe", "nested" ], "tag2" )
                            , ( [ "concatenated" ], "tag3" )
                            ]
            ]
        , describe "catching exceptions"
            [ test "when a test raises an exception, it is turned into a failure" <|
                \() ->
                    let
                        tests =
                            Runner.toTests (test "crashes" <| \() -> Debug.todo "crash")
                    in
                    case Runner.getUnitTests tests |> Array.toList of
                        [ unitTest ] ->
                            case Runner.runUnitTest unitTest of
                                UnitTestPass ->
                                    Expect.fail "Expected test to fail, but it passed"

                                UnitTestFail data ->
                                    data
                                        |> Expect.all
                                            [ Runner.getUnitTestFailDescription
                                                >> Expect.equal "This test failed because it threw an exception: \"Error: TODO in module `RunnerV2Tests` on line 189\n\ncrash\""
                                            , Runner.getUnitTestFailReason
                                                >> Expect.equal Test.Runner.Failure.Custom
                                            ]

                        unitTests ->
                            Expect.fail ("Expected tests to have one unit test, but had " ++ String.fromInt (List.length unitTests))
            ]
        ]


toTests :
    Test
    ->
        { seenSkip : Bool
        , seenOnly : Bool
        , unitTestsLabels : List (List String)
        , fuzzTestsLabels : List (List String)
        }
toTests test =
    let
        tests =
            Runner.toTests test
    in
    { seenSkip = Runner.getSeenSkip tests
    , seenOnly = Runner.getSeenOnly tests
    , unitTestsLabels =
        Runner.getUnitTests tests
            |> Array.toList
            |> List.map (Runner.getUnitTestLabels >> List.reverse)
    , fuzzTestsLabels =
        Runner.getFuzzTests tests
            |> Array.toList
            |> List.map (Runner.getFuzzTestLabels >> List.reverse)
    }


passing : Test
passing =
    test "A passing test" expectPass


{-| Dummy test implementation.
-}
testImpl : () -> Expect.Expectation
testImpl () =
    Expect.pass
