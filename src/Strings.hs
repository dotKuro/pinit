module Strings
where

projectName :: String
projectName = "pinit"

configFileName :: String
configFileName = "config.dhall"

noDefaultConfigInInstallDirectoryWarning :: FilePath -> String
noDefaultConfigInInstallDirectoryWarning installPath = "WARNING: Installation Directory " ++ installPath ++ " detected, but it does not contain the default configuration file."

noDefaultConfigDetectedError :: String
noDefaultConfigDetectedError =  "ERROR: No default configuration file detected."