# Development Guidelines

Development guidelines to be followed while developing vpuppr.

## **tl;dr Follow the existing code style whenever possible.**

## Table of Contents

- [General](#general)
- [vpuppr](#vpuppr)
    - [Code Style](#code-style)
    - [Formatting](#formatting)
    - [Naming and Code Conventions](#naming-and-code-conventions)
    - [Code Comments](#code-comments)
    - [File Layout](#file-layout)
    - [General GDScript Recommendations](#general-gdscript-recommendations)
- [libvpuppr](#libvpuppr)
    - [File Layout](#file-layout-1)
    - [General Rust Recommendations](#general-rust-recommendations)

# General

When pulling in dependencies, take note of the dependency's license. All external licenses should be
included under the `/licenses` directory.
- **Non-open source licenses are not allowed. Any code from a project without a license/non-open source license will be rejected/removed.**
- **GPL Licenses are not allowed. Any code from a project with a GPL license will be rejected/removed.**

Do not include a license/copyright notice in any files. A license is available in the repository root
should a license be required.

# vpuppr

If something is not mentioned here, then follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

If something deviates from the official style guide, it will highlighted be in **bold text**.

## Formatting

Tabs vs spaces:
- Use tabs instead of spaces for indentation
- Tabs should be 4 spaces-wide

Indentation:
- Use 1 tab for indentation where appropriate
- Use 2 tabs when a line is a continuation of the line above it
    - **Dictionaries, arrays, and enums should almost always use 1 tab for indentation**

Blank lines:
- **A maximum of 1 blank line should be used to separate code**
- A blank line should be used to separate logical sections in code

Line length:
- Keep line length around 100 characters wide

One statement per line:
- Statements should always be on different lines
- Ternary statements are allowed
- **Nested ternary statements are not allowed**
    - Example
    ```gdscript
    valid = true if (true if true else false) else false
    ```

Multiline statements:
- Long conditional statements should be formatted over multiple lines
- Long arithmetic statements should be formatted over multiple lines

Unnecessary parenthesis:
- Avoid unnecessary parenthesis
- Unnecessary parenthesis _may be used_ if it improves readability or reduces logical errors

Boolean operators:
- Use `and`, `or`, and `not` instead of `&&`, `||`, and `!`

Comment spacing:
- Add 1 space after starting a comment or doc comment
    - Example:
    ```gdscript
    # This is a comment
    ## This is a doc comment
    ```
- Commented-out code is exempt from this rule

Quotes:
- **Always prefer double quotes**

## Naming and Code Conventions

Case types:
- `snake_case`
- `PascalCase`
- `camelCase`
- `kebab-case`
- `SCREAMING_CASE`, `CAPS_CASE`, or `CONSTANT_CASE`

**NOTE: When an acronym is present, do not capitalize each letter of the acronym.**
- Examples:
    - `JsonHandler`
    - `Puppet3d`

**NOTE: Type inference is not allowed for `int` and `float`. The type must statically defined.**

Files: `snake_case`
- Examples:
    - `my_file.gd`
    - `my_scene.tscn`

Folders: `kebab-case`
- Examples:
    - `screens`
    - `file-selector`

Classes: `PascalCase`
- **Do not include a `class_name` unless the class is used in many places in the program**
- Examples:
    - `MyCoolClass`
    - `JsonHandler`

Node names:
- Examples:
    - `MyNode`
    - `VrmPuppet`

Variables: `snake_case`
- Prefer using private variables
- Use 1 underscore `_` to denote a private variable
- Always use static typing
    - Type inference is okay when the value is obvious
- Always denote the value of a variable
- **Annotations go above the variable name**
- Examples:
    - `var my_data := {}`
    - `var _my_node: Node = null`
    - `var my_string := "text"`
    - `var my_number: float = 1.0`
    ```gdscript
    @onready
    var my_line_edit := %SomeLineEdit
    ```

Constants: `SCREAMING_CASE`
- Always use static typing
- Always use static typing
    - Type inference is okay when the value is obvious
- Examples:
    - `const MY_NUMBER: int = 1`

Enums: `PascalCase`
- Enum values are `SCREAMING_CASE`
- Always assign the first value of an enum, do not assign other values unless absolutely necessary
- Example:
```gdscript
enum MyEnum {
    FIRST_VALUE = 0,
    SECOND,
    OTHER
}
```

Signals: `snake_case`
- Always use past tense when naming signals
- Always add parantheses to the signal definition
- Always use static typing if possible
- Examples:
    - `data_received()`
    - `finished_loading(data: Dictionary)`

Functions: `snake_case`
- Prefer using private functions
- Use 1 underscore `_` to denote a private function
- Always use static typing if possible
- Examples:
    - `func my_function(input: String, other: int = 0) -> void:`
    - `func _private() -> Variant:`

## Code Comments

**All comments should be treated as code.**

Section headers:
- The only section headers allowed are:
    - `Builtin functions`
    - `Private functions`
    - `Public functions`
- These are provided in a script template

Normal comments:
- `TODO` and `FIXME` comments are allowed
- Can be used to explain code that looks illogical
- Always immediately above OR on the same line of whatever the comment is explaining
- **Other code comments should be avoided since they are a maintenance burden**

Documentation comments (doc comment):
- Any classes should have a class-level doc comment
- Class-level public members (variables, constants, enums, signals, functions) should have doc comments
    - Private members are recommended to have a doc comment
- Line breaks are heavily recommended for readability
    - Only 1 line break per line
    - **A trailing line break is not allowed**
    - Example:
    ```gdscript
    ## This is a doc comment. [br]
    ## [br]
    ## This is a further description of something.
    ```

## File Layout

**vpuppr's file layout differs from GDScript's recommended layout.**

```
# Explicit tool annotations should be avoided

01. class_name <name>
02. extends <class>

03. ## Docstring

04. Inner classes

# These should be grouped together if they are logically related
05. variables, constants, enums, signals

06. Builtin methods # Like _ready, _process, etc
07. Private methods
08. Public methods
```

## General GDScript Recommendations

- Prefer `$My/NodeName` or `%NodeName` over `get_node("My/NodeName")`
- Prefer `preload("file/path")` over `load("file/path")`
    - Using `load` is acceptable when loading things at runtime
- Put as much logic in `_init` and `_ready` as possible since these functions will
usually only run once
- Prefer local variables over class-level variables
- Keep files next to where they are used
    - If a file is only being used for 1 screen, that file should exist next to that screen
    - Example:
    ```
    /screens/home/home.tscn
    /screens/home/runner_item.tscn
    ```
- Avoid OS-specific logic
    - If OS-specific logic is needed, an equivalent should also be provided for other OSs

# libvpuppr

Use the style used by the [Rust Book](https://doc.rust-lang.org/book/) and the style automatically
enforced by `rustfmt`. The default `rustfmt` binary is used.

## File Layout

The important distinction here is that consts and statics are _always_ defined at the top of the file,
not defined next to where they are used.

```
01. Module-level doc comment

02. mod

03. use

04. consts and static variables

05. structs, enums, fn, etc
```

## General Rust Recommendations

- Keep all code in 1 file unless it makes sense to make a separate module
- Avoid pulling in too many external dependencies
- Avoid OS-specific dependencies
    - If something OS-specific is needed, an equivalent should also be provided for other OSs
