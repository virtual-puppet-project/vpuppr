- [English](README.md)

# VRM addon for Godot Engine

このパッケージには VRM Addon として [VRM v0.0](https://github.com/vrm-c/vrm-specification/tree/master/specification/0.0) に準拠した VRM モデルのインポーターと、VRM を動かすためのスクリプトが含まれています。Godot Engine 3.2.2 stable 以降に対応しています。

[V-Sekai team](https://v-sekai.org/about) が自信を持ってお届けします。

また、VRM Addon とは別に Godot 用の MToon シェーダーも同梱されています。（MToon 単体での利用が可能です）

![Example of VRM Addon used to import two example characters](vrm_samples/screenshot/vrm_sample_screenshot.png)


VRM が持つデータは全てインポートされ、インスペクタに表示されます。ただし、ボーンアニメーション等を行う場合に[リターゲットの必要性が出てくる](https://qiita.com/TokageItLab/items/e5880123a9f508b2769d)ので、それらに関しては他のスクリプトやアドオンの導入を各自で検討して下さい。

## VRM とは？

参照：[https://vrm.dev/](https://vrm.dev/)

「VRM」は VR アプリケーション向けの人型 3D アバター（3D モデル）データを扱うためのファイルフォーマットです。[glTF 2.0](https://www.khronos.org/gltf/) をベースとしており、誰でも自由に利用することができます。

## 現在 Godot で動作する VRM の機能

* vrm.blendshape
  * binds / blend shapes: 実装済み（AnimationTrack として追加）
  * material binds: 実装済み（AnimationTrack として追加）
* vrm.firstperson
  * firstPersonBone: 実装済み（Metadata に追加）
  * meshAnnotations / head shrinking: 実装済み（`TODO_scale_bone` というメソッドで AnimationMethodTrack として追加）
  * lookAt: 実装済み（AnimationTrack として追加）
* vrm.humanoid
  * humanBones: 実装済み（Metadata に辞書として追加）
  * Unity HumanDescription values: **サポート外**
  * Automatic mesh retargeting: **検討中**
  * humanBones renamer: **検討中**
* vrm.material
  * shader
    * `VRM/MToon`: 実装済み
    * `VRM/UnlitTransparentZWrite`: 実装済み
    * `VRM_USE_GLTFSHADER` with PBR: 実装済み
    * `VRM_USE_GLTFSHADER` with `KHR_materials_unlit`: 実装済み
    * legacy UniVRM shaders (`VRM/Unlit*`): 実装済み
    * legacy UniGLTF shaders (`UniGLTF/UniUnlit`, `Standard`): 既存の GLTF material を使用
  * renderQueue: 実装済み（render_priority に割り当て、ただしモデル間での前後関係は保証されません）
  * floatProperties, vectorProperties, textureProperties: 実装済み
* vrm.meta (Metadata, including License information and screenshot): 実装済み
* vrm.secondaryanimation (Springbone)
  * boneGroups: 実装済み（ボーン操作最適化パッチの適用を推奨）
  * colliderGroups: 実装済み（ボーン操作最適化パッチの適用を推奨）

エクスポートには未対応です。将来的に Godot 4.0 で GLTF Export 機能が実装された場合に対応する予定です。

## Godot 4.x

VRM は最新の Godot のマスターブランチでも動作しますが、現在、以下のパッチを適用する必要があります。

* https://github.com/godotengine/godot/pull/48253
* https://github.com/godotengine/godot/pull/48014

警告：現在の実装において、リアルタイムのオムニライトやスポットライトがあるシーンで、どれが指向性のライトなのかを判別する事は出来ないため、クラスタリングでアーティファクトが発生します。この問題に関しては、いくつかの不足している変数が Godot 本体側で追加実装された場合に解決すると考えられます。

## Godot 3.x

Godot 3.x（3.2.2 以降）は、このリポジトリの `godot3` ブランチを利用して下さい。

https://github.com/V-Sekai/godot-vrm

## 使い方

VRM Addon を addons/vrm にインストールします。**生成された VRM meta のスクリプトからパスを参照するので、決してリネームしないで下さい。**

Godot-MToon-Shader を addons/Godot-MToon-Shader にインストールします。**マテリアルからパスを参照するので、決してリネームしないで下さい。**

godot_gltf GDNative ヘルパーを addons/godot_gltf にインストールします。**GDNative C++ コードも同様にパスを参照するので、決してリネームしないで下さい。**

「プロジェクト設定」→「プラグイン」で、「VRM」と「Godot-MToon-Shader」を探し、VRM と MToon プラグインを有効にします。

## 謝辞

Godot-VRM のテストと開発にご協力頂きました [V-Sekai team](https://v-sekai.org/about) とコントリビューターの方々に感謝致します。

- https://github.com/fire
- https://github.com/TokageItLab
- https://github.com/lyuma
- https://github.com/SaracenOne

また、UniVRM、MToon、その他 VRM ツールの開発者の方々に感謝致します。

- The VRM Consortium ( https://github.com/vrm-c )
- https://github.com/Santarh
- https://github.com/ousttrue
- https://github.com/saturday06
- https://github.com/FMS-Cat
