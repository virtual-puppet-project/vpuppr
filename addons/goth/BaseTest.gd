class_name BaseTest
extends Reference

const TEST_PREFIX: String = "test"

var goth: GOTH

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func run_tests() -> void:
	var test_methods: Array = []
	var methods: Array = get_method_list()
	
	for method in methods:
		var method_name: String = method["name"]
		if method_name.left(4).to_lower() == TEST_PREFIX:
			test_methods.append(method_name)
	
	goth.log_message("Running %s tests" % test_methods.size())
	for method in test_methods:
		goth.log_message("\n%s" % method)
		call(method)
		goth.log_message("Done")
