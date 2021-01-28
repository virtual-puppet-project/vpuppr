from godot import exposed, export
from godot import *
from pygltflib import GLTF2, Scene


@exposed
class GLTF2Util(Node):

	def _ready(self):
		pass

	def load_file(self, filename) -> None:
		gltf = GLTF2.load(str(filename))
		
		for s in gltf.scenes:
			print("---")
			print(str(s))
			# t is an int
			for t in s.nodes:
				print("+++")
				node_t = gltf.nodes[t]
				print(str(node_t))
				# u is an int
				for u in node_t.children:
					node_u = gltf.nodes[u]
					print(str(node_u))
					if node_u.mesh != None:
						print("mesh")
						print(str(gltf.meshes[node_u.mesh]))
