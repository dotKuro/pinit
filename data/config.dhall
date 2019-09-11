-- all configuration that can be done globally
let Config = {
  -- the author that will be used by default when creating a project
  author : Optional Text
  -- the license that will be used by default when creating a project
  , license : Optional Text
} in
-- configuration specific for adding or editing templates
let Template = {
  -- name of the new template / template to be edited
  name: Text
  -- path of the new template (leave this empty if just overwriting the config of an existing template)
  , path : Optional Text
  -- config of this template that will overwrite the global config 
  -- (use defaultConfig // {key = val} to only overwrite specific values)
  , configOverride : Optional Config
} in
let defaultTemplate = {
  name =  "sample"
  , path = None Text
  , configOverride = None Config
}
-- the default global configuration
-- (all values to none)
let defaultConfig = {
    author = None Text
    , license = None Text
  } in
-- the default configuration including templates
-- (all values to none)
let default = {
    globalConfig = defaultConfig
    , templates = [] : List Template
  }
-- overwrite your values here
in default
{- EXAMPLE
in default // {
  globalConfig = defaultConfig // { author = some "John Doe"}
  , templates = [
    defaultTemplate // { 
      name = "haskell"
      , license = some "MIT"
    }
  ]
}

This example overwrites the default global author to John Doe and spefices the MIT license
as default lisence for haskell projects. 

Note that "some" is required for optional values. 
-}