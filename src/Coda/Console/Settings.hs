--------------------------------------------------------------------
-- |
-- Copyright :  (c) Edward Kmett 2017
--              (c) Edward Kmett and Dan Doel 2012-2013
-- License   :  BSD2
-- Maintainer:  Edward Kmett <ekmett@gmail.com>
-- Stability :  experimental
-- Portability: non-portable
--
--------------------------------------------------------------------

module Coda.Console.Completion
  ( settings
  ) where

import Control.Lens
import Data.Char
import Data.List
import Data.Set as Set
import Data.Set.Lens
import Data.Monoid
import Coda.Syntax.Keywords
import Coda.Console.Command
import Coda.Console.State
import System.Console.Haskeline

startingKeywordSet, keywordSet :: Set String
startingKeywordSet = setOf folded startingKeywords
                  <> setOf (folded.cmdName.to (':':)) commands
keywordSet         = setOf folded keywords

loading :: String -> Bool
loading zs = isPrefixOf ":l" xs && isPrefixOf xs ":load"
  where xs = takeWhile (not . isSpace) $ dropWhile isSpace zs

completed :: (String,String) -> IO (String, [Completion])
completed (ls, rs)
  | ' ' `notElem` ls = completeWith startingKeywordSet (ls, rs)
  | loading rls = completeFilename (ls, rs)
  | otherwise   = completeWith keywordSet (ls, rs)
  where rls = reverse ls

completeWith :: Set String -> CompletionFunc Console
completeWith kws = completeWord Nothing " ,()[]{}" $ \s -> do
  strs <- use consoleIds
  let strs = mempty :: Set String
  return $ (strs <> kws)^..folded.filtered (s `isPrefixOf`).to (\o -> Completion o o True)

-- | Haskeline Settings
settings :: Settings IO
settings = setComplete completed defaultSettings
  { historyFile = Just ".ermine_history"
  }
