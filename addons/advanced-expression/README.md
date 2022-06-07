# Advanced Expression GD
Functions like Godot's built-in `Expression` class with the flexability of an actual script.

See the `tests/` directory for more examples.

## Example
```GDScript
var ae = preload("res://addons/advanced-expression/advanced_expression.gd")

# Add variables
# Currently, variables must be preinitialized with a value since,
# in the author's opinion, variables should avoid being null when possible
ae.add_variable("counter").add(0)

# Add function with a parameter
ae.add_function("increment") \
	.add_param("input: int") \
	.add("return input + 1")

# Add runner code that will be run on execute
# Follows the same semantics as regular functions
ae.add() \
	.add_param("starting_value") \
	.add("counter = starting_value") \
	.add("for i in 5:") \
	.tab() \
	.add("counter = increment(counter)") \
	.add("return counter")

# Everything must be compiled before executing
if ae.compile() != OK:
	push_error("Failed to compile")

# Parameters must be passed as an array
# These are passed to the runner function
assert(ae.execute([1]) == 6)
```

