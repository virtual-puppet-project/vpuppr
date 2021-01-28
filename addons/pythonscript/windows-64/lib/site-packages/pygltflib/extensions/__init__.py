from dataclasses_json import dataclass_json
from dataclasses import dataclass

@dataclass_json
@dataclass
class KHR_draco_mesh_compression:
    "bufferView": 5,
    "attributes": {
        "POSITION": 0,
        "NORMAL": 1,
        "TEXCOORD_0": 2,
        "WEIGHTS_0": 3,
        "JOINTS_0": 4