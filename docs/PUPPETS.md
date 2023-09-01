# Puppets

## Table of Contents

- [GLB Puppet](#glb-puppet)
- [VRM Puppet](#vrm-puppet)
- [PNG Puppet](#png-puppet)
- [Catappr Puppet](#catappr-puppet)

## GLB Puppet

A rigged `glb` model. No assumptions are made about the model beyond the model having a skeleton
with vertices mapped as needed.

The head bone with be assumed to be named `head`.

## VRM Puppet

A `vrm` model. The model is assumed to follow the [vrm specification](https://github.com/vrm-c/vrm-specification).

The model can either follow the base vrm specification or it can use [PerfectSync](https://hinzka.hatenablog.com/entry/2021/12/21/222635) blend shapes.

NOTE: `vrm` is an extension to `glb`, so all `vrm` models can be loaded as [GLB Puppets](#glb-puppet).

## PNG Puppet

A puppet made up of `png` images.

A PNG Puppet can:

- Cycle through images
- Bounce
- Modulate colors

A PNG Puppet cannot:

- Map data to a skeleton

## Catappr Puppet

[WIP at this repo.](https://github.com/virtual-puppet-project/catappr)

Works on the concept of stacking square images on top of each other, like a caterpillar. Each
square image can be deformed using a central pivot point.

Deforming each square can give the illusion of rotation. Moving each square can give the illusion of
translation.
