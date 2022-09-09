class_name Metadata
extends BaseConfig

var default_model_path := ""
var default_search_path := ""

var use_transparent_background := true
var use_fxaa := false
## Maps back 1:1 with Viewport::MSAA
var msaa_value: int = 0

var model_configs := {} # Config name: String -> Path: String

var model_defaults := {} # Model name: String -> Config name: String

var skip_splash := false

var python_path := ""
