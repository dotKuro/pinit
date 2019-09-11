{-# LANGUAGE DeriveGeneric     #-}
module Pinit
where

import Control.Monad (unless)
import Data.Maybe (fromJust, isNothing)
import Data.Text (pack, Text)
import Dhall (auto, input, Generic, Interpret, Natural)
import System.Directory (
    copyFile
  , createDirectoryIfMissing
  , doesDirectoryExist
  , doesFileExist
  , getXdgDirectory
  , getXdgDirectoryList
  , XdgDirectory(..)
  , XdgDirectoryList(..)
  )
import System.Environment (getArgs)
import System.Exit (ExitCode(..), exitWith)
import System.FilePath ((</>))
import System.IO(hPrint, stderr)

import Strings (
    configFileName
  , noDefaultConfigInInstallDirectoryWarning
  , noDefaultConfigDetectedError
  , projectName
  )

data InputConfig = InputConfig { globalConfig :: Config,  templates :: [Template] } deriving (Generic, Show)
instance Interpret InputConfig

data Template = Template { name :: Text, path :: Maybe Text, configOverride :: Maybe Config } deriving (Generic, Show)
instance Interpret Template

data Config = Config { author :: Maybe Text, license :: Maybe Text } deriving (Generic, Show)
instance Interpret Config

-- | Return the path of the directory for user specific configuration for this application.
getConfigDirPath :: IO FilePath
getConfigDirPath = getXdgDirectory XdgConfig projectName 

-- | Return the path of the user's configuration file for this application.
getConfigFilePath :: IO FilePath
getConfigFilePath = do
  configDirPath <- getConfigDirPath
  return $ configDirPath </> configFileName

-- | Return all paths of system wide data directories for applications in a list. 
getSystemDataDirPaths :: IO [FilePath]
getSystemDataDirPaths = getXdgDirectoryList XdgDataDirs

-- | Return the path of the system wide data directory for this application if it exists.
-- | Check every available system data path for the application directory and return the first hit.
getProgramDataDirPath :: IO (Maybe FilePath)
getProgramDataDirPath = do
  systemDataDirPaths <- getSystemDataDirPaths
  return Nothing
  where
    getProgramDataDirPathFromSystemDataDirPaths :: [FilePath] -> IO (Maybe FilePath)
    getProgramDataDirPathFromSystemDataDirPaths (path:paths) = do
      dataFolderExistsInPath <- doesDirectoryExist $ path </> projectName
      if dataFolderExistsInPath 
        then return $ Just $ path </> projectName
        else getProgramDataDirPathFromSystemDataDirPaths paths
    getProgramDataDirPathFromSystemDataDirPaths [] =
      return Nothing

-- | Return the path of the default configuration file installed on the system if it exists.
-- | Return Nothing when either no program data dir was detected or the detected data dir
-- | does not contain the configuration file.
-- | Print a warning if a data diretory with out a configuration was detected.
getDefaultConfigFilePath :: IO (Maybe FilePath)
getDefaultConfigFilePath = do
  programDataDirPath <- getProgramDataDirPath
  if isNothing programDataDirPath
    then return Nothing
    else do
      defaultConfigExists <- doesFileExist $ fromJust programDataDirPath </> configFileName
      if defaultConfigExists
        then return $ Just $ fromJust programDataDirPath </> configFileName
      else do
        hPrint stderr $ noDefaultConfigInInstallDirectoryWarning $ fromJust programDataDirPath
        return Nothing

-- | Copy the default configuration file installed on the system to the user specific
-- | configuration directory. Create any needed directories in the process.
-- | Exit the programm with a exit code 1 if the process fails.
-- | Print error message along side the exith failure.
createConfigIfNotExist :: IO ()
createConfigIfNotExist = do
  configFilePath <- getConfigFilePath
  configExist <- doesFileExist configFilePath
  unless configExist $ do
    configDirPath <- getConfigDirPath
    createDirectoryIfMissing True configDirPath
    defaultConfigFilePath <- getDefaultConfigFilePath
    if isNothing defaultConfigFilePath
      then do
        hPrint stderr noDefaultConfigDetectedError
        exitWith $ ExitFailure 1
      else 
        copyFile (fromJust defaultConfigFilePath) configFilePath

pinit :: IO ()
pinit = do
  createConfigIfNotExist
  configFilePath <- getConfigFilePath
  inputConf <- input auto $ pack configFilePath :: IO InputConfig
  print inputConf