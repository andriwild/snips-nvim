{-# LANGUAGE TemplateHaskell #-}
module Plugin.Random
    ( nextRandom
    , setNextRandom
    , randomNumbers
    ) where

import Neovim
import System.Random (newStdGen, randoms)
import UnliftIO.STM  (TVar, atomically, readTVar, modifyTVar, newTVarIO)
import Plugin.Environment.SnipsEnvironment (SnipsNvim, SnipsEnv (randomState))

-- | This type alias encodes the type of your plugin's environment, namely
-- '(TVar [Int16)' in this case.
--

-- | This is the start up code. It initializes the random number generator and
-- returns a convenient list of random numbers. It returns the environment and
-- is executed in the startup code, so this is the only place where you can't
-- use the type alias defined above.
--
-- Neovim isn't so good with big numbers, so limit to 16 bits.
randomNumbers :: Neovim startupEnv (TVar [Int16])
randomNumbers = do
    g <- liftIO newStdGen -- Create a new seed for a pseudo random number generator
    newTVarIO (randoms g) -- Put an infinite list of random numbers into a TVar

-- | Get the next random number and update the state of the list.
nextRandom :: SnipsNvim Int16
nextRandom = do
    tVarWithRandomNumbers <- asks randomState
    atomically $ do
        -- pick the head of our list of random numbers
        r <- head <$> readTVar tVarWithRandomNumbers

        -- Since we do not want to return the same number all over the place
        -- remove the head of our list of random numbers
        modifyTVar tVarWithRandomNumbers tail

        return r


-- | You probably don't want this in a random number generator, but this shows
-- hoy you can edit the state of a stateful plugin.
setNextRandom :: Int16 -> SnipsNvim ()
setNextRandom n = do
    env <- ask
    tVarWithRandomNumbers <- asks randomState
    -- cons n to the front of the infinite list
    atomically $ modifyTVar tVarWithRandomNumbers (n:)
