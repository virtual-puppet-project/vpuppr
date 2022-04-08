# Extensions <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->

- [Summary](#summary)
- [Extension Manager](#extension-manager)
- [Extension](#extension)
- [Extension Context](#extension-context)
- [Extension Resource](#extension-resource)

## Summary

Extensions are all managed by an `ExtensionManager` singleton. An extension is scoped
by its containing folder and can contain zero to many resources. This is represented
by the `Extension` class which can contain `ExtensionResource`s. The `Extension` will
also contain exactly 1 `ExtensionContext`.

## Extension Manager

A singleton that andles initial parsing and loading of all extensions located in
the `resources/extensions/` directory.

Parsing is done by reading in `config.ini` files which defines all the `Runner`,
`Model`, `Tracker`, `GUI`, and `Plugin` resources contained in the `Extension`. An
appropriate `Extension` class is created for each folder.

The extension's name is defined in the `config.ini` file. This means that, even
though duplicate folders are generally impossible, extensions can still overwrite
other extensions if given the same name.

The manager provides several helper functions for accessing extensions.

Most importantly, extensions should access their own resources through the
`ExtensionManager` or the `Extension` class, as extensions cannot use the standard
Godot `res://` syntax. This is because extensions are loaded at runtime and are
not indexed in Godot's virtual filesystem.

## Extension

Contains information about all the resources contained in the extension's
directory. This class also holds the `ExtensionContext`, which allows for
extension resource files like `.gd` scripts to be accessed.

All resources are presorted based on their type.
1. Runners
2. Puppets
3. Trackers
4. Guis
5. Plugins

These sorted resources are all stored in a `resources` dictionary.

An `add_resource` function is exposed but should not be used outside of the
`ExtensionManager`, as this is used for registering resources listed in the
`config.ini` file.

## Extension Context

A helper class that stores the context (root directory) of the extension. This holds
helper functions for loading in resources based off of the context.

## Extension Resource

A struct-style class that holds information from a section in the `config.ini` file.
