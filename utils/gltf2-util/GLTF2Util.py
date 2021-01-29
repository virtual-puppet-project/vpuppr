from godot import exposed, export
from godot import *
from pygltflib import GLTF2, Scene


@exposed
class GLTF2Util(Node):

	def _ready(self):
		pass

	def load_file(self, filename) -> None:
		gltf = GLTF2.load(str(filename))
		
		# for s in gltf.scenes:
		# 	print("---")
		# 	print(str(s))
		# 	# t is an int
		# 	for t in s.nodes:
		# 		print("+++")
		# 		node_t = gltf.nodes[t]
		# 		print(str(node_t))
		# 		# u is an int
		# 		for u in node_t.children:
		# 			node_u = gltf.nodes[u]
		# 			print(str(node_u))
		# 			if node_u.mesh != None:
		# 				print("mesh")
		# 				print(str(gltf.meshes[node_u.mesh]))

		# print("nodes")
		# for i, n in enumerate(gltf.nodes):
		# 	print(str(i))
		# 	print(str(n))

		# print("meshes")
		# for i, m in enumerate(gltf.meshes):
		# 	print(str(i))
		# 	print(str(m))

		# for i, n in enumerate(gltf.nodes):
		# 	if n.mesh:
		# 		print(gltf.meshes[n.mesh])

		# if gltf.scenes:
		# 	print(str(gltf.scenes))

		print("extensions")
		if gltf.extensions:
			for k in gltf.extensions["VRM"]:
				print(gltf.extensions["VRM"][k])

		# print("used")
		# if gltf.extensionsUsed:
		# 	print(str(gltf.extensionsUsed))

		# print("required")
		# if gltf.extensionsRequired:
		# 	print(str(gltf.extensionsRequired))

		# print("skins")
		# if gltf.skins:
		# 	print(str(gltf.skins))
		
		# print("materials")
		# if gltf.materials:
		# 	print(str(gltf.materials))

		# print("accessors")
		# if gltf.accessors:
		# 	print(str(gltf.accessors))

		# print("asset")
		# if gltf.asset:
		# 	print(str(gltf.asset))

		# print("skins")
		# if gltf.skins:
		# 	print(str(gltf.skins))

		# print("bufferViews")
		# if gltf.bufferViews:
		# 	print(str(gltf.bufferViews))

		# print("buffers")
		# if gltf.buffers:
		# 	print(str(gltf.buffers))

		# print("cameras")
		# if gltf.cameras:
		# 	print(str(gltf.cameras))

		# print("samplers")
		# if gltf.samplers:
		# 	print(str(gltf.samplers))

		# print("textures")
		# if gltf.textures:
		# 	print(str(gltf.textures))

		# print("animations")
		# if gltf.animations:
		# 	print(str(gltf.animations))

		# print("images")
		# if gltf.images:
		# 	print(str(gltf.images))
