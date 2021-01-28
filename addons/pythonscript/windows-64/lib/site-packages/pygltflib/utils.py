"""
pygltflib.utils.py : A collection of functions for manipulating GLTF2 objects.


Copyright (c) 2018, 2019 Luke Miller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import base64
from struct import calcsize
import pathlib
import warnings


from . import *


# some higher level helper functions


def add_node(gltf, node):
    warnings.warn("pygltf.utils.add_node is a provisional function and may not exist in future versions.")
    if gltf.scene is not None:
        gltf.scenes[gltf.scene].nodes.append(len(gltf.nodes))
    gltf.nodes.append(node)
    return gltf


def add_default_camera(gltf):
    warnings.warn("pygltf.utils.add_default_camera is a provisional function and may not exist in future versions.")
    n = Node()
    n.rotation = [0.0, 0.0, 0.0, 1]
    n.translation = [-1.0, 0.0, 0.0]
    n.name = "Camera"
    n.camera = len(gltf.cameras)

    gltf.add_node(n)
    c = Camera()
    c.type = PERSPECTIVE
    c.perspective = Perspective()
    c.perspective.aspectRatio = 1.5
    c.perspective.yfov = 0.6
    c.perspective.zfar = 1000
    c.perspective.znear = 0.001
    gltf.cameras.append(c)
    return gltf


def add_default_scene(gltf):
    warnings.warn("pygltf.utils.add_default_scene is a provisional function and may not exist in future versions.")
    s = Scene()
    s.name = "Scene"
    gltf.scene = 0
    gltf.scenes.append(s)
    return gltf


def add_camera(gltf, rotation, translation, scale):
    warnings.warn("pygltf.utils.add_camera is a provisional function and may not exist in future versions.")
    n = Node()
    n.rotation = rotation
    n.translation = translation
    n.scale = scale
    n.name = "Camera"
    n.camera = len(gltf.cameras)

    gltf.add_node(n)
    c = Camera()
    c.type = PERSPECTIVE
    c.perspective = Perspective()
    c.perspective.aspectRatio = 1.5
    c.perspective.yfov = 0.6
    c.perspective.zfar = 1000
    c.perspective.znear = 0.001
    gltf.cameras.append(c)
    return gltf


def uri2vectors(uri):
    base64.b64decode(uri[len('data:application/octet-stream;base64,'):])


def indices_and_vertices_to_gltf(gltf, indices, vertices):
    pass


def get_accessor_for_bufferview(gltf, bufferview=0):
    warnings.warn("pygltf.utils.get_accessor_for_bufferview is a provisional function and may not exist in future versions.")
    for accessor in gltf.accessors:
        if accessor.bufferView == bufferview:
            return accessor
    return None

def get_bufferview_for_accessor(gltf, accessor):
    warnings.warn("pygltf.utils.get_accessor_for_bufferview is a provisional function and may not exist in future versions.")
    #bufferview =
    for bufferview in gltf.accessors:
        if accessor.bufferView == bufferview:
            return accessor
    return None


def unpackURI(gltf, buffer_index=0):
    """ Unpack a data uri of a primitive with indexed geometry

    Args:
        gltf (GLTF2): a gltf object containing indexed geometry
        buffer_index: the index pointing to the buffer to unpack in gltf.buffers

    Returns:
        indices, vertices (List(Any)): List of indices that point to elements in the list of vertices (also returned)
        """

    warnings.warn("pygltf.utils.unpackURI is a provisional function and may not exist in future versions.")

    start = 'data:application/octet-stream;base64,'
    buffer = gltf.buffers[buffer_index]
    if not buffer.uri.startswith(start):
        warnings.warn(f"buffer {buffer_index} does not appear to be a data uri.")
        return {}
    data = base64.b64decode(buffer.uri[len(start):])
    if len(data) != buffer.byteLength:
        warnings.warn(f"buffer {buffer_index} is not the expected length.")
    indices = []
    vertices = []
    for i, accessor in enumerate(gltf.accessors):
        buffer_view = gltf.bufferViews[accessor.bufferView]
        chunk = data[buffer_view.byteOffset:buffer_view.byteOffset + buffer_view.byteLength]
        if buffer_view.buffer != buffer_index:
            continue
        supported = {
            UNSIGNED_SHORT: "H",
            FLOAT: "f",

        }
        unpack = supported[accessor.componentType] * accessor.count  # one record in this data set
        size = calcsize(unpack)  # size of one record
        num_of_vals = buffer_view.byteLength//size  # num of records in this chunk
        for j in range(0, num_of_vals):
            v = struct.unpack(unpack, chunk[j*size:(j*size)+size])
            if buffer_view.target == ELEMENT_ARRAY_BUFFER:  # index data (unsigned shorts)
                indices.append(v)
            elif buffer_view.target == ARRAY_BUFFER:  # vertex data (floats)
                vertices.append(v)
            else:
                warnings.warn(f"bufferview {i} doesn't seem relevant to indexed vertices")
    return indices, vertices


def add_indexed_geometry(gltf, indices, vertices):
    """
    Add a primitive object to the GLTF that is a list of indices and vertices.
    eg a triangle with indices [(0, 1, 2)] and vertices [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0)]
    """
    buffer = Buffer()
    bufferView1 = BufferView()  # indices buffer view
    bufferView2 = BufferView()  # vertices buffer view
    accessor1 = Accessor()
    accessor2 = Accessor()

    mesh = Mesh()
    primitive = Primitive()
    node = Node()

    # add to gltf
    gltf.meshes.append(mesh)
    gltf.meshes[-1].primitives.append(primitive)
    gltf.nodes.append(node)
    gltf.buffers.append(buffer)
    gltf.bufferViews.append(bufferView1)
    gltf.bufferViews.append(bufferView2)
    gltf.accessors.append(accessor1)
    gltf.accessors.append(accessor2)

    bufferview1_index = len(gltf.bufferViews)-2
    bufferview2_index = len(gltf.bufferViews)-1
    buffer_index = len(gltf.buffers) - 1
    node_index = len(gltf.nodes)-1

    # accessor for indices
    accessor1.bufferView = bufferview1_index
    accessor1.byteOffset = 0
    accessor1.componentType = UNSIGNED_SHORT
    accessor1.count = 3
    accessor1.type = SCALAR
    accessor1.max = [2]
    accessor1.min = [0]

    # accessor for vertices
    accessor2.bufferView = bufferview2_index
    accessor2.byteOffset = 0
    accessor2.componentType = FLOAT
    accessor2.count = 3
    accessor2.type = VEC3
    accessor2.max = [1.0, 1.0, 0.0]
    accessor2.min = [0.0, 0.0, 0.0]

    primitive.attributes = Attributes()
    primitive.attributes.POSITION = 1
    node.mesh = 0
    scene = None
    if not gltf.scenes:
        warnings.warn("Adding primitive to GLTF but there is no scene. You may want to add one.")
    if len(gltf.scenes)>1:
        warnings.warn("Multiple scenes found, adding to most recent one.")
        scene = gltf.scenes[-1]

    if scene:
        if not scene.nodes:
            scene.nodes = [node_index]
        else:
            scene.nodes.append(node_index)

    # add the data
    stream = "data:application/octet-stream;base64,"
    buffer.uri = stream  # first part of the datastream is set up

    chunk = b""
    pack = "<HHH"
    for v in indices:
        chunk += struct.pack(pack, *v)

    bufferView1.buffer = buffer_index
    bufferView1.byteOffset = 0
    byte_length = bufferView1.byteLength = len(chunk)
    bufferView1.target = ELEMENT_ARRAY_BUFFER
    buffer.uri += base64.b64encode(chunk).decode("utf-8")  # add to data stream

    # DH: we do not need this line.
    # byte_length += 4 - byte_length % 4  # pad to next chunk

    chunk = b""
    pack = "<fff"
    for v in vertices:
        chunk += struct.pack(pack, *v)

    # record_size = byte_length * num_of_fields
    bufferView2.buffer = buffer_index
    bufferView2.byteOffset = byte_length
    bufferView2.byteLength = len(chunk)
    bufferView2.target = ARRAY_BUFFER
    buffer.uri += base64.b64encode(chunk).decode("utf-8")  # add vertices to data stream

    buffer.byteLength = bufferView2.byteOffset + bufferView2.byteLength
    return True


def add_primitive(_gltf):
    warnings.warn("pygltf.utils.add_primitive is a provisional function and may not exist in future versions.")

    # create gltf objects for a scene with a primitive triangle with indexed geometery
    gltf = GLTF2()
    scene = Scene()
    mesh = Mesh()
    primitive = Primitive()
    node = Node()
    buffer = Buffer()
    bufferView1 = BufferView()
    bufferView2 = BufferView()
    accessor1 = Accessor()
    accessor2 = Accessor()

    # add data
    primitive.attributes = Attributes()
    primitive.attributes.POSITION = 1

    buffer.uri = "data:application/octet-stream;base64,AAABAAIAAAAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAACAPwAAAAA="
    buffer.byteLength = 44

    bufferView1.buffer = 0
    bufferView1.byteOffset = 0
    bufferView1.byteLength = 6
    bufferView1.target = ELEMENT_ARRAY_BUFFER

    bufferView2.buffer = 0
    bufferView2.byteOffset = 8
    bufferView2.byteLength = 36
    bufferView2.target = ARRAY_BUFFER

    accessor1.bufferView = 0
    accessor1.byteOffset = 0
    accessor1.componentType = UNSIGNED_SHORT
    accessor1.count = 3
    accessor1.type = SCALAR
    accessor1.max = [2]
    accessor1.min = [0]

    accessor2.bufferView = 1
    accessor2.byteOffset = 0
    accessor2.componentType = FLOAT
    accessor2.count = 3
    accessor2.type = VEC3
    accessor2.max = [1.0, 1.0, 0.0]
    accessor2.min = [0.0, 0.0, 0.0]

    node.mesh = 0
    scene.nodes = [0]

    # assemble into a gltf structure
    gltf.scenes.append(scene)
    gltf.meshes.append(mesh)
    gltf.meshes[0].primitives.append(primitive)
    gltf.nodes.append(node)
    gltf.buffers.append(buffer)
    gltf.bufferViews.append(bufferView1)
    gltf.bufferViews.append(bufferView2)
    gltf.accessors.append(accessor1)
    gltf.accessors.append(accessor2)
    # save to file
    # gltf.save("primitive.glb")
    unpackURI(gltf, 0)
    return gltf


def gltf2glb(source, destination=None, override=False):
    """
    Save a .gltf file as its .glb equivalent.

    Args:
        source (str): Path to existing .gltf file.
        destination (Optional(str)): Filename to write to (default is to use existing filename as base)
        override (bool): Override existing file.

    """
    path = Path(source)
    if not destination:
        destination = path.with_suffix(".glb")
    else:
        destination = Path(destination)
    if destination.is_file() and override is False:
        raise FileExistsError
    else:
        GLTF2().load(str(path)).save_binary(str(destination))
    return True


def glb2gltf(source, destination=None, override=False):
    """
    Save a .glb file as its .gltf equivalent.

    Args:
        source (str): Path to existing .glb file.
        destination (Optional(str)): Filename to write to (default is to use existing filename as base)
        override (bool): Override existing file.

    """
    path = Path(source)
    if not destination:
        destination = path.with_suffix(".gltf")
    else:
        destination = Path(destination)
    if destination.is_file() and override is False:
        raise FileExistsError
    else:
        GLTF2().load(str(path)).save_json(str(destination))
    return True

