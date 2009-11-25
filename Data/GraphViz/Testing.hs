{- |
   Module      : Data.GraphViz.Testing
   Description : Test-suite for graphviz.
   Copyright   : (c) Ivan Lazar Miljenovic
   License     : 3-Clause BSD-style
   Maintainer  : Ivan.Miljenovic@gmail.com

   This defines a test-suite for the graphviz library.
-}
module Data.GraphViz.Testing where

import Test.QuickCheck

import Data.GraphViz.Testing.Instances()
-- This module cannot be re-exported from Instances, as it causes
-- Overlapping Instances.
import Data.GraphViz.Testing.Instances.FGL()
import Data.GraphViz.Testing.Properties

import Data.GraphViz.Attributes(Attributes)
import Data.GraphViz.Types(DotGraph)
-- Can't use PatriciaTree because a Show instance is needed.
import Data.Graph.Inductive.Tree(Gr)

import System.Exit(ExitCode(..), exitWith)
import System.IO(hPutStrLn, stderr)

-- -----------------------------------------------------------------------------

runDefaultTests :: IO ()
runDefaultTests = do putStrLn msg
                     blankLn
                     runTests defaultTests
                     spacerLn
                     putStrLn successMsg
  where
    msg = "This is the test suite for the graphviz library.\n\
           \If any of these tests fail, please inform the maintainer,\n\
           \including full output of this test suite."

    successMsg = "All tests were successful!"


-- -----------------------------------------------------------------------------
-- Defining a Test structure and how to run tests.

-- | Defines the test structure being used.
data Test = Test { name :: String
                 , desc :: String
                 , test :: IO Result -- ^ QuickCheck test.
                 }

-- | Run all of the provided tests.
runTests :: [Test] -> IO ()
runTests = mapM_ runTest

-- | Run the provided test.
runTest     :: Test -> IO ()
runTest tst = do spacerLn
                 putStrLn title
                 blankLn
                 putStrLn $ desc tst
                 blankLn
                 r <- test tst
                 blankLn
                 case r of
                   Success{} -> putStrLn successMsg
                   GaveUp{}  -> putStrLn gaveUpMsg
                   _         -> die failMsg
                 blankLn
  where
    nm = '"' : name tst ++ "\""
    title = "Running test: " ++ nm ++ "."
    successMsg = "All tests for " ++ nm ++ " were successful!"
    gaveUpMsg = "Too many sample inputs for " ++ nm ++ " were rejected;\n\
                 \tentatively marking this as successful."
    failMsg = "The tests for " ++ nm ++ " failed!\n\
               \Not attempting any further tests."

spacerLn :: IO ()
spacerLn = putStrLn (replicate 70 '=') >> blankLn

blankLn :: IO ()
blankLn = putStrLn ""

die     :: String -> IO a
die msg = do hPutStrLn stderr msg
             exitWith (ExitFailure 1)

-- -----------------------------------------------------------------------------
-- Defining the tests to use.

-- | The tests to run by default.
defaultTests :: [Test]
defaultTests = [ test_printParseID_Attributes
               , test_printParseID
               , test_preProcessingID
                 -- Can't run this test, since we don't generate valid
                 -- DotGraphs to pass to Graphviz!
                 -- , test_parsePrettyID
               , test_dotizeAugment
               ]

-- | Test that 'Attributes' can be printed and then parsed back.
test_printParseID_Attributes :: Test
test_printParseID_Attributes
  = Test { name = "Printing and parsing of Attributes"
         , desc = dsc
         , test = quickCheckWithResult args prop
         }
    where
      prop :: Attributes -> Property
      prop = prop_printParseListID

      args = stdArgs { maxSuccess = numGen }
      numGen = 10000
      defGen = maxSuccess stdArgs

      dsc = "The most common source of errors in printing and parsing are for\n\
            \Attributes.  As such, these are stress-tested before we run the\n\
            \rest of the tests, generating " ++ show numGen ++ " lists of\n\
            \Attributes rather than the default " ++ show defGen ++ " tests."

test_printParseID :: Test
test_printParseID
  = Test { name = "Printing and Parsing DotGraphs"
         , desc = dsc
         , test = quickCheckResult prop
         }
    where
      prop :: DotGraph Int -> Bool
      prop = prop_printParseID

      dsc = "The graphviz library should be able to parse back in its own\n\
             \generated Dot code.  This test aims to determine the validity\n\
             \of this for the overall \"DotGraph Int\" values."

test_preProcessingID :: Test
test_preProcessingID
  = Test { name = "Pre-processing Dot code"
         , desc = dsc
         , test = quickCheckResult prop
         }
    where
      prop :: DotGraph Int -> Bool
      prop = prop_preProcessingID

      dsc = "When parsing Dot code, some pre-processing is done to remove items\n\
             \such as comments and to join together multi-line strings.  This\n\
             \test verifies that this pre-processing doesn't affect actual\n\
             \Dot code by running the pre-processor on generated Dot code."

test_parsePrettyID :: Test
test_parsePrettyID
  = Test { name = "Parsing pretty-printed code"
         , desc = dsc
         , test = quickCheckResult prop
         }
    where
      prop :: DotGraph Int -> Bool
      prop = prop_parsePrettyID

      dsc = "By default, the graphviz library doesn't produce readable Dot\n\
             \code to ensure that lines aren't truncated, etc.  This test\n\
             \ensures that the pretty-printing functions produce Dot code\n\
             \that is still parseable (which should also help ensure that\n\
             \ \"Real-World\" Dot code is also parseable)."

test_dotizeAugment :: Test
test_dotizeAugment
  = Test { name = "Augmenting FGL Graphs"
         , desc = dsc
         , test = quickCheckResult prop
         }
    where
      prop :: Gr Char Double -> Bool
      prop = prop_dotizeAugment

      dsc = "The various Graph to Graph functions in Data.GraphViz should\n\
             \only _augment_ the graph labels and not change the graphs\n\
             \themselves.  This test compares the original graphs to these\n\
             \augmented graphs and verifies that they are the same."