{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import           Control.Monad        (void)
import qualified Data.Text.IO         as T
import           System.Exit          (ExitCode (ExitSuccess))
import           System.FilePath.Glob (compile, globDir1)
import           System.Process       (readProcessWithExitCode)
import           Test.HUnit           (Assertion, Test (..), assertEqual,
                                       assertFailure, runTestTT)
import           Typst.Parse          (parseTypst)

-- Testing utils:

-- | Assert that the given value is a Right
assertRight :: Show a => Either a b -> Assertion
assertRight (Right _)  =  pure ()
assertRight (Left err) = assertFailure (show err)

-- | Run a single test case given the filename
testParseFile :: FilePath -> IO Test
testParseFile p = do
    txt <- T.readFile p
    pure $ TestLabel p $ TestCase $ assertRight $ parseTypst p txt

-- | Get the path to all .typ files in a given directory
findTypFiles :: FilePath -> IO [FilePath]
findTypFiles = globDir1 (compile "**/*.typ")

-- | Run a single test case using the Rust Typst compiler to assert that its
-- a valid document and only a bug in typst-hs that we have found
checkTypst :: FilePath -> Assertion
checkTypst file = do
    let args = ["compile", file, "/dev/null", "-f", "pdf"]
    -- note that we use /dev/null so it will only work on linux
    (code, _, _) <- readProcessWithExitCode "typst" args "" -- stdin
    assertEqual file ExitSuccess code

-- Actual tests:

-- | All .typ files in the packages repo
packages :: IO [FilePath]
packages = findTypFiles "./packages/packages"

-- | All .typ files in the counter-examples repo
counterExamples :: IO [FilePath]
counterExamples = findTypFiles "./test/counter-examples"

-- | Collects all the tests from the given @IO [FilePath]@s
parseTests :: IO [FilePath] -> IO Test
parseTests = (TestList <$>) . (>>= mapM testParseFile)

labelTests :: String -> IO [FilePath] -> IO Test
labelTests label files = TestLabel label <$> parseTests files

-- | Ensure our cherry-picked counter-examples actually work
-- with the Rust Typst compiler
sanityCheck :: IO Test
sanityCheck = do
    files <- counterExamples
    let cases = TestCase . checkTypst <$> files
    return . TestLabel "Sanity check" . TestList $ cases

main :: IO ()
main =
    let tests = TestList <$> sequence [
         -- labelTests "Package parse tests" packages,
         labelTests "Counter-examples parse tests" counterExamples,
         sanityCheck] in
    tests >>= void . runTestTT
