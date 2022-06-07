class_name Metadata
extends BaseConfig

var default_model_path := ""
var default_search_path := ""

var use_transparent_background := true
var use_fxaa := false
var msaa_value := false # TODO change this to be specific values

var model_configs := {} # Config name: String -> Path: String

var model_defaults := {} # Model name: String -> Config name: String

var python_path := ""
