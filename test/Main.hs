{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

-- | Test suite for ACE.

module Main where

import ACE.Combinators
import ACE.Parsers
import ACE.Tokenizer (tokenize)
import ACE.Types.Syntax
import ACE.Types.Tokens

import Control.Applicative
import Control.Monad
import Control.Monad.Identity
import Data.Bifunctor
import Data.Text (Text)
import Test.HUnit
import Test.Hspec
import Text.Parsec (Stream,ParsecT,runP,try,Parsec)

-- | Test suite entry point, returns exit failure if any test fails.
main :: IO ()
main = hspec spec

-- | Test suite.
spec :: Spec
spec = do
  describe "tokenizer" tokenizer
  describe "parser" parser

-- | Tests for the tokenizer.
tokenizer :: Spec
tokenizer =
  do it "empty string"
        (tokenize "" == Right [])
     it "word"
        (tokenize "word" == Right [Word (1,0) "word"])
     it "period"
        (tokenize "." == Right [Period (1,0)])
     it "comma"
        (tokenize "," == Right [Comma (1,0)])
     it "number"
        (tokenize "55" == Right [Number (1,0) 55])
     it "question mark"
        (tokenize "?" == Right [QuestionMark (1,0)])
     it "quotation"
        (tokenize "\"foo\"" == Right [QuotedString (1,0) "foo"])
     it "empty-quotation"
        (isLeft (tokenize "\"\""))
     it "words"
        (tokenize "foo bar" == Right [Word (1,0) "foo",Word (1,4) "bar"])
     it "genitive '"
        (tokenize "foo'" == Right [Word (1,0) "foo",Genitive (1,3) False])
     it "genitive 's"
        (tokenize "foo's" == Right [Word (1,0) "foo",Genitive (1,3) True])
     it "newline"
        (tokenize "foo\nbar" == Right [Word (1,0) "foo",Word (2,0) "bar"])

-- | Parser tests.
parser :: Spec
parser =
  do it "universalGlobalQuantor"
        (parsed universalGlobalQuantor "for every" == Right ForEveryEach)
     it "possessivePronoun"
        (parsed possessivePronoun "his" == Right HisHer)
     it "generalizedQuantor"
        (parsed generalizedQuantor "not more than" == Right NotMoreThan)
     it "distributiveMarker"
        (parsed distributiveMarker "each of" == Right EachOf)
     it "distributiveGlobalQuantor"
        (parsed distributiveGlobalQuantor "for each of" == Right ForEachOf)
     it "existentialGlobalQuestionQuantor"
        (parsed existentialGlobalQuestionQuantor "is there" ==
         Right (ExistentialGlobalQuestionQuantor Is))
     it "existentialGlobalQuantor"
        (parsed existentialGlobalQuantor "there is" ==
         Right (ExistentialGlobalQuantor Is))
     it "numberP"
        (parsed numberP "not more than 5" ==
         Right (NumberP (Just NotMoreThan) 5))
     it "numberP"
        (parsed numberP "5" == Right (NumberP Nothing 5))
     it "determiner"
        (parsed determiner "the" == Right The)
     it "determiner"
        (parsed determiner "not every" == Right NotEveryEach)
     it "adjectiveCoord"
        (parsed adjectiveCoord "<intrans-adj>" ==
         Right (AdjectiveCoord (IntransitiveAdjective "<intrans-adj>")
                               Nothing))
     it "adjectiveCoord"
        (parsed adjectiveCoord "<intrans-adj> and <intrans-adj>" ==
         Right (AdjectiveCoord (IntransitiveAdjective "<intrans-adj>")
                               (Just (AdjectiveCoord (IntransitiveAdjective "<intrans-adj>")
                                                     Nothing))))
     it "adverbCoord"
        (parsed adverbCoord "<adverb> and <adverb>" ==
         Right (AdverbCoord (Adverb "<adverb>")
                            (Just (AdverbCoord (Adverb "<adverb>")
                                               Nothing))))

-- | Is that left?
isLeft :: Either a b -> Bool
isLeft = either (const True) (const False)

-- | Get the parsed result after tokenizing.
parsed :: Parsec [Token] (ACEParser [Token] Identity) c -> Text -> Either String c
parsed p = tokenize >=> bimap show id . runP p config "<test>"
  where
    config =
      ACE { aceIntransitiveAdjective = string "<intrans-adj>"
          , aceNoun                  = string "<noun>"
          , acePreposition           = string "<prep>"
          , aceVariable              = string "<var>"
          , aceProperName            = string "<proper-name>"
          , aceAdverb                = string "<adverb>"
          , aceIntransitiveVerb      = string "<intrans-verb>"
          }
