shader_type spatial;
//render_mode specular_disabled;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_schlick_ggx;

// VARIANTS:
// DEFAULT_MODE:
const float isOutline = 0.0;

// OUTLINE:
// // Comment `const float isOutline = 0.0;`
// render_mode cull_front;
// const float isOutline = 1.0;
// // Uncomment `ALPHA = alpha;` and comment `ALPHA_SCISSOR = _Cutoff` at end of fragment()

// TRANSPARENT:
// Uncomment `ALPHA = alpha;` and comment `ALPHA_SCISSOR = _Cutoff` at end of fragment()

// TRANSPARENT_WITH_ZWRITE:
//render_mode depth_draw_always;
// // Uncomment `ALPHA = alpha;` and comment `ALPHA_SCISSOR = _Cutoff` at end of fragment()

// CULL_OFF:
// render_mode cull_disabled;

// TRANSPARENT_CULL_OFF:
// render_mode cull_disabled;
// // Uncomment `ALPHA = alpha;` and comment `ALPHA_SCISSOR = _Cutoff` at end of fragment()

// TRANSPARENT_WITH_ZWRITE_CULL_OFF:
render_mode cull_disabled,depth_draw_always;
// Uncomment `ALPHA = alpha;` and comment `ALPHA_SCISSOR = _Cutoff` at end of fragment()


const bool CALCULATE_LIGHTING_IN_FRAGMENT = true;


uniform float _EnableAlphaCutout : hint_range(0,1,1) = 0.0;
uniform float _Cutoff : hint_range(0,1) = 0.5;
uniform vec4 _Color : hint_color = vec4(1.0,1.0,1.0,1.0); // "Lit Texture + Alpha"
uniform vec4 _ShadeColor : hint_color = vec4(0.97, 0.81, 0.86, 1); // "Shade Color"
uniform sampler2D _MainTex : hint_albedo;
uniform vec4 _MainTex_ST = vec4(1.0,1.0,0.0,0.0);
uniform sampler2D _ShadeTexture : hint_albedo;
uniform float _BumpScale : hint_range(-16,16) = 1.0; // "Normal Scale"
uniform sampler2D _BumpMap : hint_normal; // "Normal Texture"
uniform sampler2D _ReceiveShadowTexture : hint_white;
uniform float _ReceiveShadowRate = 1.0; // "Receive Shadow"
uniform sampler2D _ShadingGradeTexture : hint_white;
uniform float _ShadingGradeRate = 1.0; // "Shading Grade"
uniform float _ShadeShift : hint_range(-1.0, 1.0) = 0.0;
uniform float _ShadeToony : hint_range(0.0, 1.0) = 0.9;
uniform float _LightColorAttenuation : hint_range(0.0, 1.0) = 0.0;
uniform float _IndirectLightIntensity : hint_range(0.0, 1.0) = 0.1;
uniform sampler2D _RimTexture : hint_albedo;
uniform vec4 _RimColor : hint_color = vec4(0,0,0,1);
uniform float _RimLightingMix : hint_range(0.0, 1.0) = 0.0;
uniform float _RimFresnelPower : hint_range(0.0, 100.0) = 1.0;
uniform float _RimLift : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D _SphereAdd : hint_black_albedo; // "Sphere Texture(Add)"
uniform vec4 _EmissionColor : hint_color = vec4(0,0,0,1); // "Color"
uniform sampler2D _EmissionMap : hint_albedo;
// Not implemented:
// uniform float _OutlineWidthScreenCoordinates : hint_range(0,1,1);
uniform sampler2D _OutlineWidthTexture : hint_white;
uniform float _OutlineWidth : hint_range(0.01, 1.0) = 0.5;
uniform float _OutlineScaledMaxDistance : hint_range(1,10) = 1;
uniform float _OutlineColorMode : hint_range(0,1,1);
uniform vec4 _OutlineColor : hint_color = vec4(0,0,0,1);
uniform float _OutlineLightingMix : hint_range(0,1) = 0;
uniform sampler2D _UvAnimMaskTexture : hint_white;
uniform float _UvAnimScrollX = 0;
uniform float _UvAnimRotation = 0;
uniform float _UvAnimScrollY = 0;
uniform float _DebugMode : hint_range(0,3,1) = 0.0;

uniform float _MToonVersion = 33;

// const
const float PI_2 = 6.28318530718;
const float EPS_COL = 0.00001;


varying vec4 posWorld; // : TEXCOORD0;
varying vec3 tspace0; // : TEXCOORD1;
varying vec3 tspace1; // : TEXCOORD2;
varying vec3 tspace2; // : TEXCOORD3;


void vertex() {
	UV=UV*_MainTex_ST.xy+_MainTex_ST.zw;
	COLOR=COLOR;

	if (isOutline == 1.0) {
	    float outlineTex = textureLod(_OutlineWidthTexture, UV, 0).r;
	    vec3 worldNormalLength = vec3(1.0/length(mat3(transpose(WORLD_MATRIX)) * NORMAL));
	    vec3 outlineOffset = 0.01 * _OutlineWidth * outlineTex * worldNormalLength * NORMAL;
	    VERTEX += outlineOffset;
	}
	/*
#elif defined(MTOON_OUTLINE_WIDTH_SCREEN)
    vec4 nearUpperRight = (xINV_PROJECTION_MATRIX * vec4(1, 1, 0, 1));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    vec3 viewNormal = mat3(xINV_CAMERA_MATRIX) * mat3(xWORLD_MATRIX) * normal.xyz;
    vec3 clipNormal = TransformViewToProjection(viewNormal.xyz);
    vec2 projectedNormal = normalize(clipNormal.xy);
    projectedNormal *= min(vertex.w, _OutlineScaledMaxDistance);
    projectedNormal.x *= aspect;
    vertex.xy += 0.01 * _OutlineWidth * outlineTex * projectedNormal.xy * saturate(1 - abs(normalize(viewNormal).z)); // ignore offset when normal toward camera
#else
    float4 vertex = UnityObjectToClipPos(v.vertex);
#endif
	*/

	posWorld = (MODELVIEW_MATRIX*vec4(VERTEX.xyz, 1.0));
    vec3 worldNormal = mat3(MODELVIEW_MATRIX)*NORMAL;
    vec3 worldTangent = mat3(MODELVIEW_MATRIX)*TANGENT;
    vec3 worldBitangent = mat3(MODELVIEW_MATRIX)*BINORMAL;
    tspace0 = vec3(worldTangent.x, worldBitangent.x, worldNormal.x);
    tspace1 = vec3(worldTangent.y, worldBitangent.y, worldNormal.y);
    tspace2 = vec3(worldTangent.z, worldBitangent.z, worldNormal.z);
}

vec3 UnpackScaleNormal(vec4 normalmap, float scale) {
	normalmap.xy = scale * (normalmap.xy * 2.0 - 1.0);
	normalmap.z = sqrt(max(0.0, 1.0 - dot(normalmap.xy, normalmap.xy))); //always ignore Z, as it can be RG packed, Z may be pos/neg, etc.
	return normalmap.xyz;
}

vec3 calculateLighting(vec2 mainUv, float dotNL, float lightAttenuation, vec4 shade, vec4 lit, vec3 lightColor, out vec3 col, out float lightIntensity) {
    // Decide albedo color rate from Direct Light
    float shadingGrade = 1.0 - _ShadingGradeRate * (1.0 - texture(_ShadingGradeTexture, mainUv).r);
    lightIntensity = dotNL; // [-1, +1]
    lightIntensity = lightIntensity * 0.5 + 0.5; // from [-1, +1] to [0, 1]
    lightIntensity = lightIntensity * lightAttenuation; // receive shadow
    lightIntensity = lightIntensity * shadingGrade; // darker
    lightIntensity = lightIntensity * 2.0 - 1.0; // from [0, 1] to [-1, +1]
    // tooned. mapping from [minIntensityThreshold, maxIntensityThreshold] to [0, 1]
    float maxIntensityThreshold = mix(1, _ShadeShift, _ShadeToony);
    float minIntensityThreshold = _ShadeShift;
    lightIntensity = clamp((lightIntensity - minIntensityThreshold) / max(EPS_COL, (maxIntensityThreshold - minIntensityThreshold)),0.0,1.0);

    col = mix(shade.rgb, lit.rgb, lightIntensity);
    //DEBUG_OVERRIDE = vec4(vec3(shade.rgb),1.0);
    //DEBUG_OVERRIDE = vec4(vec3(col.rgb),1.0);
    // Direct Light
    vec3 lighting = lightColor / 3.14159;
    lighting = mix(lighting, max(vec3(EPS_COL), max(lighting.x, max(lighting.y, lighting.z))), _LightColorAttenuation); // color atten
	return lighting;
}

vec3 calculateAddLighting(vec2 mainUv, float dotNL, float dotNV, float shadowAttenuation, vec3 lighting, vec3 col) {
//    UNITY_LIGHT_ATTENUATION(shadowAttenuation, i, posWorld.xyz);
//#ifdef _ALPHABLEND_ON
//    lighting *= step(0, dotNL); // darken if transparent. Because Unity's transparent material can't receive shadowAttenuation.
//#endif
    lighting *= 0.5; // darken if additional light.
    lighting *= min(0.0, dotNL) + 1.0; // darken dotNL < 0 area by using float lambert
    lighting *= shadowAttenuation; // darken if receiving shadow
    col *= lighting;

    // parametric rim lighting
    vec3 staticRimLighting = vec3(0.0);
    vec3 mixedRimLighting = lighting;

    vec3 rimLighting = mix(staticRimLighting, mixedRimLighting, _RimLightingMix);
    vec3 rim = pow(clamp(1.0 - dotNV + _RimLift, 0.0, 1.0), _RimFresnelPower) * _RimColor.rgb * texture(_RimTexture, mainUv).rgb;
    col += mix(rim * rimLighting, vec3(0.0), isOutline);
	return col;
}
float SchlickFresnel(float u) {
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m; // pow(m,5)
}
void fragment() {
	bool _NORMALMAP = textureSize(_BumpMap, 0).x > 8;
	bool MTOON_OUTLINE_COLOR_FIXED = _OutlineColorMode == 0.0;
	bool MTOON_OUTLINE_COLOR_MIXED = _OutlineColorMode == 1.0;

    // uv
    vec2 mainUv = UV; //TRANSFORM_TEX(i.uv0, _MainTex);
    
    // uv anim
    float uvAnim = texture(_UvAnimMaskTexture, mainUv).r * TIME;
    // translate uv in bottom-left origin coordinates.
    mainUv += vec2(_UvAnimScrollX, -_UvAnimScrollY) * uvAnim;
    // rotate uv counter-clockwise around (0.5, 0.5) in bottom-left origin coordinates.
    float rotateRad = _UvAnimRotation * PI_2 * uvAnim;
    const vec2 rotatePivot = vec2(0.5, 0.5);
    mainUv = mat2(vec2(cos(rotateRad), -sin(rotateRad)), vec2(-sin(rotateRad), cos(rotateRad))) * (mainUv - rotatePivot) + rotatePivot;
    
    // main tex
    vec4 mainTex = texture(_MainTex, mainUv);
    vec4 DEBUG_OVERRIDE = vec4(0.0);
    // alpha
	float alpha = _Color.a * mainTex.a;
 
    // normal
    vec3 viewNormal;
	if (_NORMALMAP) {
	    vec3 tangentNormal = UnpackScaleNormal(texture(_BumpMap, mainUv), _BumpScale);
	    viewNormal.x = dot(tspace0, tangentNormal);
	    viewNormal.y = dot(tspace1, tangentNormal);
	    viewNormal.z = dot(tspace2, tangentNormal);
	} else {
	    viewNormal = vec3(tspace0.z, tspace1.z, tspace2.z);
	}
    vec3 viewView = -VIEW;
    viewNormal *= step(0.0, dot(viewView, viewNormal)) * 2.0 - 1.0; // flip if projection matrix is flipped
    viewNormal *= mix(+1.0, -1.0, isOutline);
    viewNormal = normalize(viewNormal);

    // Unity lighting
	// dir light in light()

	// Indirect Light
	// ...

    // Albedo color
    vec4 shade = _ShadeColor * texture(_ShadeTexture, mainUv);
    vec4 lit = _Color * mainTex;

    shade = min(shade, lit); ///// Mimic look of non-PBR min() clamp we commented out below.

	vec3 col = vec3(0.0);
	float lightIntensity = 1.0;

   
    //col = min(col, lit.rgb); // comment out if you want to PBR absolutely.

    // parametric rim lighting

    vec3 rimLighting = vec3(1.0);
    vec3 rim = pow(clamp(1.0 - dot(viewNormal, viewView) + _RimLift, 0.0, 1.0), _RimFresnelPower) * _RimColor.rgb * texture(_RimTexture, mainUv).rgb;
    vec3 rimEmission = mix(rim * rimLighting, vec3(0, 0, 0), isOutline);


    // additive matcap
    vec3 viewCameraUp = vec3(0.0,1.0,0.0);//normalize(CAMERA_MATRIX[1].xyz); // FIXME!!
    vec3 viewViewUp = normalize(viewCameraUp - viewView * dot(viewView, viewCameraUp));
    vec3 viewViewRight = normalize(cross(viewView, viewViewUp));
    vec2 matcapUv = vec2(-dot(viewViewRight, viewNormal), dot(viewViewUp, viewNormal)) * 0.5 + 0.5;
    vec3 matcapLighting = texture(_SphereAdd, matcapUv).rgb;
    col += mix(matcapLighting, vec3(0, 0, 0), isOutline);

    // Emission
    vec3 emission = texture(_EmissionMap, mainUv).rgb * _EmissionColor.rgb;
    col += mix(emission, vec3(0, 0, 0), isOutline);


    // outline
	if (isOutline == 1.0) {
		if (MTOON_OUTLINE_COLOR_FIXED) {
	        col = mix(col, _OutlineColor.rgb, isOutline);
		} else if (MTOON_OUTLINE_COLOR_MIXED) {
	        col = mix(col, _OutlineColor.rgb * mix(vec3(1, 1, 1), col, _OutlineLightingMix), isOutline);
	    }
	}

    // debug
	if (_DebugMode == 1.0) { //MTOON_DEBUG_NORMAL
		col = ((mat3(CAMERA_MATRIX) * -viewNormal) * 0.5 + vec3(0.5));
	} else if (_DebugMode == 2.0) { //MTOON_DEBUG_LITSHADERATE
		col = lightIntensity * rimLighting;
	} else if (_DebugMode == 3.0) { // Add pass lighting
		col = vec3(0.0);
	}

    EMISSION = mix(col.rgb, DEBUG_OVERRIDE.rgb, DEBUG_OVERRIDE.a);

    ALBEDO = lit.rgb;//vec3(0.0);
	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
	METALLIC = 0.0;
	ALPHA = alpha;
	//if (_EnableAlphaCutout == 1.0 && alpha < _Cutoff) { discard;  } // ALPHA_SCISSOR = _Cutoff;
}

void light() {
    // uv
    vec2 mainUv = UV; //TRANSFORM_TEX(i.uv0, _MainTex);
    // uv anim
    float uvAnim = texture(_UvAnimMaskTexture, mainUv).r * TIME;
    // translate uv in bottom-left origin coordinates.
    mainUv += vec2(_UvAnimScrollX, -_UvAnimScrollY) * uvAnim;
    // rotate uv counter-clockwise around (0.5, 0.5) in bottom-left origin coordinates.
    float rotateRad = _UvAnimRotation * PI_2 * uvAnim;
    const vec2 rotatePivot = vec2(0.5, 0.5);
    mainUv = mat2(vec2(cos(rotateRad), sin(rotateRad)), vec2(-sin(rotateRad), cos(rotateRad))) * (mainUv - rotatePivot) + rotatePivot;

	float addDotNL = dot(NORMAL, LIGHT);
    vec4 mainTex = texture(_MainTex, mainUv);
    vec4 shade = _ShadeColor * texture(_ShadeTexture, mainUv);
   	vec4 lit = _Color * mainTex;

	vec3 addCol = vec3(0.0);
	float addTmp;
	vec3 addLighting = calculateLighting(mainUv, addDotNL, 1.0, shade, lit, LIGHT_COLOR, addCol, addTmp);
	// addLighting *= step(0, addDotNL); // darken if transparent. Because Unity's transparent material can't receive shadowAttenuation.
	DIFFUSE_LIGHT += calculateAddLighting(mainUv, addDotNL, dot(NORMAL, VIEW), length(vec3(ATTENUATION))/sqrt(3.0), addLighting, addCol);

    SPECULAR_LIGHT = vec3(0.0);
}
