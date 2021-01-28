from . import *

###
# Validator
###

class GLTFValidatorException(Exception):
    pass


class InvalidAcccessorComponentTypeException(GLTFValidatorException):
    pass


class InvalidBufferViewIndex(GLTFValidatorException):
    pass


class InvalidAccessorSparseIndicesComponentTypeException(GLTFValidatorException):
    pass


class InvalidArrayLengthException(GLTFValidatorException):
    pass


class MismatchedArrayLengthException(GLTFValidatorException):
    pass


class InvalidMeshPrimitiveMode(GLTFValidatorException):
    pass


class InvalidValueError(GLTFValidatorException):
    pass


class InvalidBufferViewTarget(GLTFValidatorException):
    pass


class MissingRequiredField(GLTFValidatorException):
    pass


def validate_accessors(gltf: GLTF2):
    # pretty complete
    for accessor in gltf.accessors:
        if accessor.componentType not in COMPONENT_TYPES:
            raise InvalidAcccessorComponentTypeException(f"{accessor.componentType} not a valid component type")
        if accessor.max and len(accessor.max) not in [1, 2, 3, 4, 9, 16]:
            raise InvalidArrayLengthException(f"{len(accessor.max)} not a valid length for accessor max array")
        if accessor.min and len(accessor.min) not in [1, 2, 3, 4, 9, 16]:
            raise InvalidArrayLengthException(f"{len(accessor.min)} not a valid length for accessor min array")
        if accessor.min and accessor.max and len(accessor.min) != len(accessor.max):
            raise MismatchedArrayLengthException("accessor min and max arrays must be same lengths")


def validate_accessors_sparse(gltf: GLTF2):
    for accessor in gltf.accessors:
        sparse = accessor.sparse
        if sparse and sparse.indices:
            if sparse.indices.componentType not in ACCESSOR_SPARSE_INDICES_COMPONENT_TYPES:
                raise InvalidAccessorSparseIndicesComponentTypeException(
                    f"{sparse.indices.componentType} not a valid sparse indicies component type")
            bufferView = sparse.indices.bufferView
            if bufferView > len(gltf.bufferViews):
                raise InvalidBufferViewIndex("accessor.sparse.indices.bufferView refers to non-existent bufferView")
            if gltf.bufferViews[bufferView].target in BUFFERVIEW_TARGETS:
                raise InvalidBufferViewTarget("accessor.sparse.indices' referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target")
    #raise InvalidBufferViewTarget("accessor.sparse.indices' referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target")


def validate_animation_channel(gltf: GLTF2):
    for animation in gltf.animations:
        for channel in animation.channels:
            if not channel.sampler:
                raise MissingRequiredField("animation.channel requires sampler")
            if not channel.target:
                raise MissingRequiredField("animation.channel requires sampler")
    #raise MissingRequiredField("animation.channel requires sampler")


def validate_meshes(gltf: GLTF2):
    for mesh in gltf.meshes:
        if mesh.primitives:
            for primitive in mesh.primitives:
                if primitive.mode not in MESH_PRIMITIVE_MODES:
                    raise InvalidMeshPrimitiveMode(f"{primitive.mode} not a valid mesh primitive mode")


def validate_bufferViews(gltf: GLTF2):
    for bufferView in gltf.bufferViews:
        if bufferView.byteOffset:
            if bufferView.byteOffset < 0:
                raise InvalidValueError(f"bufferView.byteOffset {bufferView.byteOffset} needs to be >= 0")
        if bufferView.byteStride:
            if bufferView.byteStride < 4:
                raise InvalidValueError(f"bufferView.byteStride {bufferView.byteStride} needs to be >= 4")
            if bufferView.byteStride > 252:
                raise InvalidValueError(f"bufferView.byteStride {bufferView.byteStride} needs to be <= 252")
            if bufferView.byteStride / 4 != bufferView.byteStride // 4:
                raise InvalidValueError(f"bufferView.byteStride {bufferView.byteStride} needs to be a multiple of 4")
        if bufferView.target and bufferView.target not in BUFFERVIEW_TARGETS:
            raise InvalidBufferViewTarget(f"{bufferView.target} not a valid bufferView target type")


def validate(gltf: GLTF2, warning=False):
    """
    Validate a GLTF2 object. Will raises exceptions where validation fails.

    Args:
          gltf (GLTF2): A gltf2 object
          warning (Bool): If false, all errors throw exceptions, else

    Returns:
         errors List(Exception): A list of errors if warning is True, or an empty list validated correctly
    """
    errors = []
    warnings.warn("pygltf.utils.validator is a provisional function and may not exist in future versions.")
    for validator in [validate_accessors, validate_accessors_sparse, validate_animation_channel, validate_meshes, validate_bufferViews]:
        try:
            validator(gltf)
        except Exception as e:
            if warning:
                errors.append(e)
            else:
                raise e
    return errors


def summary(gltf: GLTF2):
    print("start validation.")
    errors = validate(gltf, warning=True)
    if errors:
        for error in errors:
            print("E:",error.args[0])
    print(f"{len(errors)} error(s) found.")
    print("done.")