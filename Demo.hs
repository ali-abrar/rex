{-# LANGUAGE TemplateHaskell, QuasiQuotes, ViewPatterns #-}

module Demo where

import Text.Regex.PCRE.Rex

import qualified Data.ByteString.Char8 as B
import Data.Maybe (catMaybes, isJust)

main =
  do demonstrate "math"       math       "1 + 3"
     demonstrate "math"       math       "3 * 2 + 100"
     demonstrate "math"       math       "20 / 3 + 100 * 2"
     demonstrate "peano"      peano      "S Z"
     demonstrate "peano"      peano      "S S S S Z"
     demonstrate "peano"      peano      "S   S   Z"
     demonstrate "parsePair"  parsePair  "<-1, 3>"
     demonstrate "parsePair"  parsePair  "<-4,3b0>"
     demonstrate "parsePair"  parsePair  "< a,  -30 >"
     demonstrate "parsePair"  parsePair  "< a,  other>"
     demonstrate "parsePair'" parsePair' "<-1, 3>"
     demonstrate "parseDate"  parseDate  "1993.8.10"
     demonstrate "parseDate"  parseDate  "1993.08.10"
     demonstrate "parseDate"  parseDate  "2003.02.28"
     demonstrate "parseDate"  parseDate  "2004.02.28"
     demonstrate "parseDate"  parseDate  "2003.02.27"
     demonstrate "disjunct"   disjunct   "a"
     demonstrate "disjunct"   disjunct   "ab"
     demonstrate "disjunct"   disjunct   "abc"
     print $ "btest: " ++ show btest

demonstrate n f input = putStrLn $ n ++ " \"" ++ input ++ "\" == " ++ show (f input)

math x = mathl x 0

mathl [] x = x
mathl [rex|^  \s*(?{ read -> y }\d+)\s*(?{ s }.*)$|] x = mathl s y
mathl [rex|^\+\s*(?{ read -> y }\d+)\s*(?{ s }.*)$|] x = mathl s $ x + y
mathl [rex|^ -\s*(?{ read -> y }\d+)\s*(?{ s }.*)$|] x = mathl s $ x - y
mathl [rex|^\*\s*(?{ read -> y }\d+)\s*(?{ s }.*)$|] x = mathl s $ x * y
mathl [rex|^ /\s*(?{ read -> y }\d+)\s*(?{ s }.*)$|] x = mathl s $ x / y
mathl str x = error str

peano :: String -> Maybe Int
peano = [rex|^(?{ length . filter (=='S') } \s* (?:S\s+)*Z)\s*$|]

parsePair :: String -> Maybe (String, String)
parsePair = [rex|^<\s* (?{ }[^\s,>]+) \s*,\s* (?{ }[^\s,>]+) \s*>$|]

parsePair' :: String -> Maybe (Int, Int)
parsePair' = [rex|^<\s* (?{ }[^\s,>]+) \s*,\s* (?{ }[^\s,>]+) \s*>$|]
  where
    rexView = read

-- From http://www.regular-expressions.info/dates.html
parseDate :: String -> Maybe (Int, Int, Int)
parseDate [rex|^(?{ read -> y }(?:19|20)\d\d)[- /.]
                (?{ read -> m }0[1-9]|1[012])[- /.]
                (?{ read -> d }0[1-9]|[12][0-9]|3[01])$|]
  |  (d > 30 && (m `elem` [4, 6, 9, 11]))
  || (m == 2 &&
       (d ==29 && not (mod y 4 == 0 && (mod y 100 /= 0 || mod y 400 == 0)))
    || (d > 29)) = Nothing
  | otherwise = Just (y, m, d)
parseDate _ = Nothing

onNull a f [] = a
onNull _ f xs = f xs

nonNull = onNull Nothing

disjunct [rex| ^(?:(?{nonNull $ Just . head -> a} .)
             | (?{nonNull $ Just . head -> b} ..)
             | (?{nonNull $ Just . last -> c} ...))$|] =
  head $ catMaybes [a, b, c]

btest = [brex|(?{}hello)|] (B.pack "hello") == Just (B.pack "hello")
