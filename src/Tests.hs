{-# LANGUAGE FlexibleInstances    #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
--------------------------------------------------------------------------------
-- |
-- Module      :  HarmTrace.Base.Chord.Tests
-- Copyright   :  (c) 2013--2014 W. Bas de Haas and Jose Pedro Magalhaes,
--                Multiphonyx Holding BV
-- License     :  LGPL-3
--
-- Maintainer  :  bas@chordify.net, dreixel@chordify.net 
-- Stability   :  experimental
-- Portability :  non-portable
--
-- Summary: Defines some property tests for testing the HarmTrace.Base package
--------------------------------------------------------------------------------
module Main where

import HarmTrace.Base.Chord
import HarmTrace.Base.Parse   ( parseDataSafe, pChord )
import HarmTrace.Base.Time

import Test.QuickCheck
import Test.QuickCheck.Batch

import Data.List              ( sort )

import System.Exit            ( exitFailure, exitSuccess )

instance Arbitrary DiatonicNatural where
  arbitrary = elements . enumFrom $ C

instance Arbitrary IntNat where
  arbitrary = elements . enumFrom $ I1
  
instance Arbitrary Accidental where
  arbitrary = elements [Nat,Sh,Fl,SS,FF]


instance Arbitrary Root where
  arbitrary = elements . map pcToRoot $ [0..11]
  
instance Arbitrary Interval where
  arbitrary = choose (0,21) >>= return . icToInterval  
  
-- instance Arbitrary a => Arbitrary (Note a) where
  -- arbitrary = do nat <- arbitrary
                 -- acc <- arbitrary
                 -- return (Note acc nat)

               
instance Arbitrary Shorthand where
  arbitrary = elements . enumFrom $ Maj
  
instance Arbitrary Addition where
  arbitrary = oneof [ arbitrary >>= return . Add
                    , arbitrary >>= return . NoAdd ]

instance Arbitrary a => Arbitrary (Chord a) where
  arbitrary = do r   <- arbitrary
                 sh  <- elements [Maj, Min, Aug, Dim, Maj7, Min7, Sev, Dim7, HDim7, Aug7, MinMaj7]
                 -- sh  <- arbitrary
                 -- add <- arbitrary >>= listOf . return . Add 
                 
                 b   <- arbitrary
                 return (Chord r sh [] b ) -- (Note Nat I1))
                 
instance Arbitrary a => Arbitrary (Timed a) where
  arbitrary = do x  <- arbitrary
                 s  <- elements [2 .. 5]
                 ts <- vector s -- guarantee that this list has a minimum of 2 items
                 return . Timed x . sort $ ts
               
instance Arbitrary a => Arbitrary [Timed a] where
  arbitrary = do xs <- arbitrary
                 undefined
                 
instance Arbitrary BeatTime where
  arbitrary = do choose (0.0, 100.0) >>= return . Time

                 
pcProp :: Root -> Bool
pcProp r = (toPitchClass r) == toPitchClass (pcToRoot (toPitchClass r))

pcSetProp :: Chord Root -> Bool
pcSetProp c = c == toChord (chordRoot c) (toIntSet c) (Just $ chordBass c)

intervalProp :: Interval -> Bool
intervalProp i = i == icToInterval (toIntervalClss i)

intervalProp2 :: Int -> Bool
intervalProp2 i = i == toIntervalClss (icToInterval i)

enHarEqProp :: Root -> Bool
enHarEqProp a = a &== a

parseProp :: Chord Root -> Bool
parseProp c = parseDataSafe pChord (show c) == c

mergeTimedTest :: [Timed (Chord Root)] -> Bool
mergeTimedTest cs = expandTimed (mergeTimed cs) == cs

--------------------------------------------------------------------------------
-- Execute the tests
--------------------------------------------------------------------------------

main :: IO ()
main = do let opts = TestOptions 100    -- nr of tests to run
                                 0      -- no time limit
                                 True   -- debug?
              myTest s p = runTests ("Testing HarmTrace-Base: "++ s ++" ... ") 
                                    opts . map run $ p
          myTest "roots"        [ pcProp, enHarEqProp ]
          myTest "chords"       [ pcSetProp, parseProp ]
          myTest "intervals I"  [ intervalProp ]
          myTest "intervals II" [ intervalProp2 ]
          -- myTest "mergeTimed I" [ mergeTimed ] 
          
          