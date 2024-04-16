{-# LANGUAGE DeriveFunctor, FlexibleInstances #-}
module Data.Sequent where

import qualified Data.Collection as C
import           Data.Formula

data Sign = L | R
data Pair a = S { left, right :: a } deriving (Show, Functor)
type Sequent = Pair C.Collection

-- | \(O(1)\). Empty sequent.
empty :: (Formula -> C.Category) -> (Formula -> C.Category) -> Sequent
empty schL schR = S (C.empty schL) (C.empty schR)

-- | \(O(1)\). Sequent with one right formula.
singletonR :: (Formula -> C.Category) -> (Formula -> C.Category) -> Formula -> Sequent
singletonR schL schR f = add R f $ empty schL schR

-- | \(O(1)\). Retrieve the formula with smallest category.
view :: Sequent -> Maybe (Sign, Formula, Sequent)
view s = case (C.view $ left s, C.view $ right s) of
  (Just (i, a, l), Just (j, b, r))
    | i == j -> Just (L, a, s { left = l }) -- left bias for now
    | i < j  -> Just (L, a, s { left = l })
    | j < i  -> Just (R, b, s { right = r })
  (Just (_, a, l), _) -> Just (L, a, s { left = l })
  (_, Just (_, b, r)) -> Just (R, b, s { right = r })
  _ -> Nothing

-- | \(O(1)\). Add a formula according to the category.
add :: Sign -> Formula -> Sequent -> Sequent
add L f s = s { left = C.add f (left s) }
add R f s = s { right = C.add f (right s) }

-- | \(O(1)\). Replace the Collection.
setR :: Formula -> Sequent -> Sequent
setR f s = s { right = C.add f (C.empty $ C.sch $ right s) }

-- | \(O(1)\). Delete the right formulas.
delR :: Sequent -> Sequent
delR = setR Bot

-- | \(O(1)\). Check if the succedent is empty.
nullR :: Sequent -> Bool
nullR = null . C.items . right

-- | \(O(n)\). Add a formula with maximum category.
lock :: Sign -> Formula -> Sequent -> Sequent
lock L f s = s { left = C.lock f (left s) }
lock R f s = s { right = C.lock f (right s) }

-- | \(O(n)\). Unlock all formulas.
unlock :: Sequent -> Sequent
unlock = fmap C.unlock

-- | \(O(n)\). Substitute sequent.
subst :: Bool -> Int -> Formula -> Sequent -> Sequent
subst t p f = fmap $ C.map $ unitSubsti t (p, f)

-- | \(O(n)\). Conversion to formula.
toFormula :: Sequent -> Formula
toFormula s = simply $ foldr (:&) Top (C.items $ left s) :> foldr (:|) Bot (C.items $ right s)