# Trackers

TODO you-win September 1, 2023: need to reconfirm all data examples.

| Name | Head | Blend shapes | Notes |
| --- | --- | --- | --- |
| [MediaPipe](https://github.com/google/mediapipe) | `true` | `true` | Uses [GDMP](https://github.com/j20001970/GDMP) |
| [iFacialMocap](https://www.ifacialmocap.com/) | `true` | `true` | Requires paid iOS app |
| [MeowFace](https://play.google.com/store/apps/details?id=com.suvidriel.meowface) | `true` | `true` | Only works on Android, uses same format as VTube Studio |
| [VTube Studio](https://denchisoft.com/) | `true` | `true` | Only works on iOS and Android |
| [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) | `true` | `false` | Uses webcam, blend shapes have to be parsed from data points |
| [Mouse tracking](https://github.com/virtual-puppet-project/mouse-tracker) | `true` | `false` | Maps mouse offset to head rotation |
| [Lip sync](https://github.com/virtual-puppet-project/real-time-lip-sync-gd) | `false` | `false` | Purely for lip syncing |

## Table of Contents

- [MediaPipe](#mediapipe)
- [iFacialMocap](#ifacialmocap)
- [MeowFace](#meowface)
- [VTube Studio](#vtube-studio)
- [OpenSeeFace](#openseeface)
- [Mouse tracking](#mouse-tracking)
- [Lip sync](#lip-sync)

## MediaPipe

Data is received as `Projection` and `Array<MediaPipeCategory>` which is roughly equivalent to
`Matrix4` and `Array<Dictionary<Name, Value>>`.

## iFacialMocap

Data is received as:

```
eyeLookIn_R-54|noseSneer_L-5|mouthPress_L-8|mouthSmile_R-4|mouthLowerDown_L-1|mouthSmile_L-1|eyeWide_L-26|
mouthRollUpper-1|mouthPucker-3|browOuterUp_L-3|mouthDimple_R-3|mouthShrugLower-21|mouthLeft-0|eyeLookUp_R-0|
mouthFunnel-1|mouthDimple_L-3|mouthUpperUp_R-2|noseSneer_R-6|eyeSquint_R-3|jawForward-2|mouthClose-2|
mouthFrown_L-0|mouthShrugUpper-15|eyeSquint_L-3|cheekSquint_L-3|eyeLookDown_L-16|mouthLowerDown_R-1|
eyeLookOut_R-0|jawLeft-0|mouthStretch_L-5|cheekPuff-3|eyeLookUp_L-0|eyeBlink_R-0|jawOpen-2|mouthRollLower-5|
browInnerUp-4|browOuterUp_R-3|mouthFrown_R-0|mouthStretch_R-5|eyeLookIn_L-0|tongueOut-0|eyeBlink_L-0|
browDown_L-0|eyeWide_R-26|eyeLookDown_R-16|mouthUpperUp_L-2|cheekSquint_R-3|mouthPress_R-8|browDown_R-0|
jawRight-0|mouthRight-2|eyeLookOut_L-44|hapihapi-0|=head#-1.6704091,-7.3032465,2.886358,0.084120944,
0.03458406,-0.4721467|rightEye#5.3555145,19.067966,1.8478252|leftEye#5.5607924,15.616646,1.5515244|
```

Will need to reconfirm that all data is always sent.

## MeowFace

Data is received as:

```json
{
    "Timestamp":1664817520079,
    "Hotkey":-1,
    "FaceFound":true,
    "Rotation": {
        "x":-11.091268539428711,
        "y":9.422998428344727,
        "z":3.1646311283111574
    },
    "Position": {
        "x":0.4682624340057373,
        "y":1.3167941570281983,
        "z":4.734524726867676
    },
    "EyeLeft": {
        "x":3.5520474910736086,
        "y":9.085052490234375,
        "z":0.5114284753799439
    },
    "EyeRight": {
        "x":3.459942579269409,
        "y":12.89495849609375,
        "z":0.7132274508476257
    },
    "BlendShapes":
    [
        {"k":"EyeBlinkRight","v":0.002937057288363576},
        {"k":"EyeWideRight","v":0.28645533323287966},
        {"k":"MouthLowerDownLeft","v":0.06704049557447434},
        {"k":"MouthRollUpper","v":0.10249163955450058},
        {"k":"CheekSquintLeft","v":0.06105339154601097},
        {"k":"MouthDimpleRight","v":0.12425188720226288},
        {"k":"BrowInnerUp","v":0.06119655817747116},
        {"k":"EyeLookInLeft","v":0.0},
        {"k":"MouthPressLeft","v":0.10954130440950394},
        {"k":"MouthStretchRight","v":0.09924199432134628},
        {"k":"BrowDownLeft","v":0.0},
        {"k":"MouthFunnel","v":0.026398103684186937},
        {"k":"NoseSneerLeft","v":0.0653044804930687},
        {"k":"EyeLookOutLeft","v":0.2591644525527954},
        {"k":"EyeLookInRight","v":0.3678726553916931},
        {"k":"MouthLowerDownRight","v":0.06102924421429634},
        {"k":"BrowOuterUpRight","v":0.0033271661959588529},
        {"k":"MouthLeft","v":0.02176971733570099},
        {"k":"CheekSquintRight","v":0.07157324254512787},
        {"k":"JawOpen","v":0.10355126112699509},
        {"k":"EyeBlinkLeft","v":0.0029380139894783499},
        {"k":"JawForward","v":0.14734186232089997},
        {"k":"MouthPressRight","v":0.11540094763040543},
        {"k":"NoseSneerRight","v":0.05933605507016182},
        {"k":"JawRight","v":0.0},
        {"k":"MouthShrugLower","v":0.2303646206855774},
        {"k":"EyeSquintLeft","v":0.11781732738018036},
        {"k":"EyeLookOutRight","v":0.0},
        {"k":"MouthFrownLeft","v":0.0},
        {"k":"CheekPuff","v":0.06076660752296448},
        {"k":"MouthStretchLeft","v":0.11452846229076386},
        {"k":"TongueOut","v":5.0197301176835299e-11},
        {"k":"MouthRollLower","v":0.237720787525177},
        {"k":"MouthUpperUpRight","v":0.015751656144857408},
        {"k":"MouthShrugUpper","v":0.1125534400343895},
        {"k":"EyeSquintRight","v":0.11850234866142273},
        {"k":"EyeLookDownLeft","v":0.09258905798196793},
        {"k":"MouthSmileLeft","v":0.03695908188819885},
        {"k":"EyeWideLeft","v":0.28617817163467409},
        {"k":"MouthClose","v":0.08427434414625168},
        {"k":"JawLeft","v":0.0317654088139534},
        {"k":"MouthDimpleLeft","v":0.12999406456947328},
        {"k":"MouthFrownRight","v":0.0},
        {"k":"MouthPucker","v":0.07617400586605072},
        {"k":"MouthRight","v":0.0},
        {"k":"EyeLookUpLeft","v":0.0},
        {"k":"BrowDownRight","v":0.0},
        {"k":"MouthSmileRight","v":0.01186437252908945},
        {"k":"MouthUpperUpLeft","v":0.019432881847023965},
        {"k":"BrowOuterUpLeft","v":0.003327207639813423},
        {"k":"EyeLookUpRight","v":0.0},
        {"k":"EyeLookDownRight","v":0.09135865420103073}
    ]
}
```

Will need to confirm that all data is always sent.

## VTube Studio

Data is received as:

```json
{
    "Timestamp":1664817520079,
    "Hotkey":-1,
    "FaceFound":true,
    "Rotation": {
        "x":-11.091268539428711,
        "y":9.422998428344727,
        "z":3.1646311283111574
    },
    "Position": {
        "x":0.4682624340057373,
        "y":1.3167941570281983,
        "z":4.734524726867676
    },
    "EyeLeft": {
        "x":3.5520474910736086,
        "y":9.085052490234375,
        "z":0.5114284753799439
    },
    "EyeRight": {
        "x":3.459942579269409,
        "y":12.89495849609375,
        "z":0.7132274508476257
    },
    "BlendShapes":
    [
        {"k":"EyeBlinkRight","v":0.002937057288363576},
        {"k":"EyeWideRight","v":0.28645533323287966},
        {"k":"MouthLowerDownLeft","v":0.06704049557447434},
        {"k":"MouthRollUpper","v":0.10249163955450058},
        {"k":"CheekSquintLeft","v":0.06105339154601097},
        {"k":"MouthDimpleRight","v":0.12425188720226288},
        {"k":"BrowInnerUp","v":0.06119655817747116},
        {"k":"EyeLookInLeft","v":0.0},
        {"k":"MouthPressLeft","v":0.10954130440950394},
        {"k":"MouthStretchRight","v":0.09924199432134628},
        {"k":"BrowDownLeft","v":0.0},
        {"k":"MouthFunnel","v":0.026398103684186937},
        {"k":"NoseSneerLeft","v":0.0653044804930687},
        {"k":"EyeLookOutLeft","v":0.2591644525527954},
        {"k":"EyeLookInRight","v":0.3678726553916931},
        {"k":"MouthLowerDownRight","v":0.06102924421429634},
        {"k":"BrowOuterUpRight","v":0.0033271661959588529},
        {"k":"MouthLeft","v":0.02176971733570099},
        {"k":"CheekSquintRight","v":0.07157324254512787},
        {"k":"JawOpen","v":0.10355126112699509},
        {"k":"EyeBlinkLeft","v":0.0029380139894783499},
        {"k":"JawForward","v":0.14734186232089997},
        {"k":"MouthPressRight","v":0.11540094763040543},
        {"k":"NoseSneerRight","v":0.05933605507016182},
        {"k":"JawRight","v":0.0},
        {"k":"MouthShrugLower","v":0.2303646206855774},
        {"k":"EyeSquintLeft","v":0.11781732738018036},
        {"k":"EyeLookOutRight","v":0.0},
        {"k":"MouthFrownLeft","v":0.0},
        {"k":"CheekPuff","v":0.06076660752296448},
        {"k":"MouthStretchLeft","v":0.11452846229076386},
        {"k":"TongueOut","v":5.0197301176835299e-11},
        {"k":"MouthRollLower","v":0.237720787525177},
        {"k":"MouthUpperUpRight","v":0.015751656144857408},
        {"k":"MouthShrugUpper","v":0.1125534400343895},
        {"k":"EyeSquintRight","v":0.11850234866142273},
        {"k":"EyeLookDownLeft","v":0.09258905798196793},
        {"k":"MouthSmileLeft","v":0.03695908188819885},
        {"k":"EyeWideLeft","v":0.28617817163467409},
        {"k":"MouthClose","v":0.08427434414625168},
        {"k":"JawLeft","v":0.0317654088139534},
        {"k":"MouthDimpleLeft","v":0.12999406456947328},
        {"k":"MouthFrownRight","v":0.0},
        {"k":"MouthPucker","v":0.07617400586605072},
        {"k":"MouthRight","v":0.0},
        {"k":"EyeLookUpLeft","v":0.0},
        {"k":"BrowDownRight","v":0.0},
        {"k":"MouthSmileRight","v":0.01186437252908945},
        {"k":"MouthUpperUpLeft","v":0.019432881847023965},
        {"k":"BrowOuterUpLeft","v":0.003327207639813423},
        {"k":"EyeLookUpRight","v":0.0},
        {"k":"EyeLookDownRight","v":0.09135865420103073}
    ]
}
```

Will need to confirm that all data is always sent.

## OpenSeeFace

Data is sent as bytes and needs to be parsed in the following order:

1. time: `f64`
2. id: `i32`
3. camera_resolution: `f32`, `f32`
4. right_eye_open: `f32`
5. left_eye_open: `f32`
6. got_3d: `u8`
7. fit_3d_error: `f32`
8. raw_quaternion: `f32`, `f32`, `f32`, `f32`
9. raw_euler: `f32`, `f32`, `f32`
10. translation: `f32`, `f32`, `f32`
11. confidence: `f32` * 68
12. points: `f32` * 68
13. points_3d: `f32` * 70
14. eye_left: `f32`
15. eye_right: `f32`
16. eyebrow_steepness_left: `f32`
17. eyebrow_up_down_left: `f32`
18. eyebrow_quirk_left: `f32`
19. eyebrow_steepness_right: `f32`
20. eyebrow_up_down_right: `f32`
21. eyebrow_quirk_right: `f32`
22. mouth_corner_up_down_left: `f32`
23. mouth_corner_in_out_left: `f32`
24. mouth_corner_up_down_right: `f32`
25. mouth_corner_in_out_right: `f32`
26. mouth_open: `f32`
27. mouth_wide: `f32`

Gaze tracking can be calculated via:

- right_gaze: `points_3d[67] - points_3d[69]`
- left_gaze: `points_3d[66] - points_3d[68]`

## Mouse Tracking

Rust libraries can be used to poll the position of the user's mouse. This probably
doesn't work on Wayland or on MacOS.

WIP

## Lip Sync

Rust libraries can be used to parse audio.

WIP
