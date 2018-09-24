 Shader "Maxwell/Specular" {
	Properties {

		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_SpecularMap("Specular(RGB)Smooth(A)", 2D) = "white"{}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_OcclusionMap("Occlusion Map", 2D) = "white"{}
		_Occlusion("Occlusion Scale", Range(0,1)) = 1
		_SpecularColor("Specular Color",Color) = (0.2,0.2,0.2,1)
		_EmissionColor("Emission Color", Color) = (0,0,0,1)

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		
	// ------------------------------------------------------------
	// Surface shader code generated out of a CGPROGRAM block:
CGINCLUDE

#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityShaderUtilities.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityMetaPass.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

		struct Input {
			float2 uv_MainTex;
		};
		
struct appdata{
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
};

    float4 _SpecularColor;
    float4 _EmissionColor;
		float _Occlusion;


		sampler2D _BumpMap;
		sampler2D _SpecularMap;
		sampler2D _HeightMap;
		sampler2D _OcclusionMap;
		sampler2D _MainTex;
		half _Glossiness;
		float4 _Color;

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			float2 uv = IN.uv_MainTex;// - parallax_mapping(IN.uv_MainTex,IN.viewDir);
			float4 c = tex2D (_MainTex, uv) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Occlusion = lerp(1, tex2D(_OcclusionMap, IN.uv_MainTex).r, _Occlusion);
			float4 spec = tex2D(_SpecularMap, IN.uv_MainTex);
			o.Specular = _SpecularColor;
			o.Smoothness = _Glossiness * spec.r;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Emission = _EmissionColor;

		}

ENDCG
	// ---- forward rendering base pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma target 5.0
#pragma multi_compile_fog
#pragma multi_compile_fwdbase

// vertex-to-fragment interpolation data
// no lightmaps:
#ifndef LIGHTMAP_ON
struct v2f_surf {
  UNITY_POSITION(pos);
  float2 pack0 : TEXCOORD0; // _MainTex
  float4 tSpace0 : TEXCOORD1;
  float4 tSpace1 : TEXCOORD2;
  float4 tSpace2 : TEXCOORD3;

  #if UNITY_SHOULD_SAMPLE_SH
  half3 sh : TEXCOORD4; // SH
  #endif
  UNITY_SHADOW_COORDS(5)
  UNITY_FOG_COORDS(6)
  #if SHADER_TARGET >= 30
  float4 lmap : TEXCOORD7;
  #endif
    float3 worldViewDir : TEXCOORD8;
    float3 lightDir : TEXCOORD9;
};
#endif
// with lightmaps:
#ifdef LIGHTMAP_ON
struct v2f_surf {
  UNITY_POSITION(pos);
  float2 pack0 : TEXCOORD0; // _MainTex
  float4 tSpace0 : TEXCOORD1;
  float4 tSpace1 : TEXCOORD2;
  float4 tSpace2 : TEXCOORD3;

  float4 lmap : TEXCOORD4;
  UNITY_SHADOW_COORDS(5)
  UNITY_FOG_COORDS(6)

    float3 worldViewDir : TEXCOORD7;
        float3 lightDir : TEXCOORD8;
};
#endif
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);

  o.pos = UnityObjectToClipPos(v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  o.worldViewDir = (UnityWorldSpaceViewDir(worldPos));
  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
  float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
   o.tSpace0 = (float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x));
  o.tSpace1 = (float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y));
  o.tSpace2 = (float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z));
    
  #ifdef DYNAMICLIGHTMAP_ON
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
  #endif
  #ifdef LIGHTMAP_ON
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif

  // SH/ambient and vertex lights
  #ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
      o.sh = 0;
      // Approximated illumination from non-important point lights
      #ifdef VERTEXLIGHT_ON
        o.sh += Shade4PointLights (
          unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
          unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
          unity_4LightAtten0, worldPos, worldNormal);
      #endif
      o.sh = ShadeSHPerVertex (worldNormal, o.sh);
    #endif
  #endif // !LIGHTMAP_ON

  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
    #ifndef USING_DIRECTIONAL_LIGHT
    o.lightDir = (UnityWorldSpaceLightDir(worldPos));
  #else
    o.lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  return o;
}

float4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  surfIN.uv_MainTex = IN.pack0.xy;
  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
  float3 lightDir = normalize(IN.lightDir);
  float3 worldViewDir = normalize(IN.worldViewDir);
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif


  
    float3x3 wdMatrix= float3x3(  normalize(IN.tSpace0.xyz),  normalize(IN.tSpace1.xyz),  normalize(IN.tSpace2.xyz));
  // call surface function
  surf (surfIN, o);

  // compute lighting & shadowing factor
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  float4 c = 0;

  o.Normal = normalize(mul(wdMatrix, o.Normal));

  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  gi.light.color = _LightColor0.rgb;
  gi.light.dir = lightDir;
  // Call GI (lightmaps/SH/reflections) lighting function
  UnityGIInput giInput;
  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
  giInput.light = gi.light;
  giInput.worldPos = worldPos;
  giInput.worldViewDir = worldViewDir;
  giInput.atten = atten;
  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = IN.lmap;
  #else
    giInput.lightmapUV = 0.0;
  #endif
  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
    giInput.ambient = IN.sh;
  #else
    giInput.ambient.rgb = 0.0;
  #endif
  giInput.probeHDR[0] = unity_SpecCube0_HDR;
  giInput.probeHDR[1] = unity_SpecCube1_HDR;
  #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
  #endif
  #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
  #endif
  LightingStandardSpecular_GI(o, giInput, gi);

  // realtime lighting: call lighting function
  c += LightingStandardSpecular (o, worldViewDir, gi);
  c.rgb += o.Emission;
  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
  UNITY_OPAQUE_ALPHA(c.a);
  return c;
}


ENDCG

}

	// ---- forward rendering additive lights pass:
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardAdd" }
		ZWrite Off Blend One One

CGPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma target 5.0

#pragma multi_compile_fog
#pragma skip_variants INSTANCING_ON
#pragma multi_compile_fwdadd_fullshadows
// vertex-to-fragment interpolation data
struct v2f_surf {
  UNITY_POSITION(pos);
  float2 pack0 : TEXCOORD0; // _MainTex
  float3 tSpace0 : TEXCOORD1;
  float3 tSpace1 : TEXCOORD2;
  float3 tSpace2 : TEXCOORD3;
  float3 worldPos : TEXCOORD4;
  UNITY_SHADOW_COORDS(5)
  UNITY_FOG_COORDS(6)
  float3 worldViewDir : TEXCOORD7;
  float3 lightDir : TEXCOORD8;
};
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);

  o.pos = UnityObjectToClipPos(v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  o.worldViewDir = (UnityWorldSpaceViewDir(worldPos));
  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
  float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
  o.tSpace0 = (float3(worldTangent.x, worldBinormal.x, worldNormal.x));
  o.tSpace1 = (float3(worldTangent.y, worldBinormal.y, worldNormal.y));
  o.tSpace2 = (float3(worldTangent.z, worldBinormal.z, worldNormal.z));
      
  o.worldPos = worldPos;
      #ifndef USING_DIRECTIONAL_LIGHT
    o.lightDir = (UnityWorldSpaceLightDir(worldPos));
  #else
    o.lightDir = _WorldSpaceLightPos0.xyz;
  #endif
  UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy); // pass shadow coordinates to pixel shader
  UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
  return o;
}

float4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  surfIN.uv_MainTex = IN.pack0.xy;
  float3 worldPos = (IN.worldPos);
  float3 lightDir = normalize(IN.lightDir);
  float3 worldViewDir = normalize(IN.worldViewDir);
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif


  
    float3x3 wdMatrix= float3x3(  normalize(IN.tSpace0.xyz),  normalize(IN.tSpace1.xyz),  normalize(IN.tSpace2.xyz));
  // call surface function
  surf (surfIN, o);
  UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
  float4 c = 0;

  o.Normal = normalize(mul(wdMatrix, o.Normal));
  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  gi.light.color = _LightColor0.rgb;
  gi.light.dir = lightDir;
  gi.light.color *= atten;
  c += LightingStandardSpecular (o, worldViewDir, gi);
  c.a = 0.0;
  UNITY_APPLY_FOG(IN.fogCoord, c); // apply fog
  UNITY_OPAQUE_ALPHA(c.a);
  return c;
}

ENDCG

}

	// ---- deferred shading pass:
	Pass {
		Name "DEFERRED"
		Tags { "LightMode" = "Deferred" }

CGPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma target 5.0

#pragma exclude_renderers nomrt
#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
#pragma multi_compile_prepassfinal


struct v2f_surf {
  UNITY_POSITION(pos);
  float2 pack0 : TEXCOORD0; // _MainTex
  float4 tSpace0 : TEXCOORD1;
  float4 tSpace1 : TEXCOORD2;
  float4 tSpace2 : TEXCOORD3;
  float4 lmap : TEXCOORD5;
#ifndef LIGHTMAP_ON
  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
    half3 sh : TEXCOORD6; // SH
  #endif
#else
#endif
  float3 worldViewDir : TEXCOORD7;
};
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);

  o.pos = UnityObjectToClipPos(v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
  float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
  float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
  float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
   o.tSpace0 = (float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x));
  o.tSpace1 = (float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y));
  o.tSpace2 = (float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z));
    
  float3 viewDirForLight = (UnityWorldSpaceViewDir(worldPos));

#ifdef DYNAMICLIGHTMAP_ON
  o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#else
  o.lmap.zw = 0;
#endif
#ifdef LIGHTMAP_ON
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#else
  o.lmap.xy = 0;
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
      o.sh = 0;
      o.sh = ShadeSHPerVertex (worldNormal, o.sh);
    #endif
#endif
	o.worldViewDir = viewDirForLight;
  return o;
}

#ifdef LIGHTMAP_ON
float4 unity_LightmapFade;
#endif
float4 unity_Ambient;

// fragment shader
void frag_surf (v2f_surf IN,
    out half4 outGBuffer0 : SV_Target0,
    out half4 outGBuffer1 : SV_Target1,
    out half4 outGBuffer2 : SV_Target2,
    out half4 outEmission : SV_Target3
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
    , out half4 outShadowMask : SV_Target4
#endif
) {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.uv_MainTex.x = 1.0;
  
  surfIN.uv_MainTex = IN.pack0.xy;
  float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
  float3 worldViewDir = normalize(IN.worldViewDir);
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif


  
    float3x3 wdMatrix= float3x3(  normalize(IN.tSpace0.xyz),  normalize(IN.tSpace1.xyz),  normalize(IN.tSpace2.xyz));
  // call surface function
  surf (surfIN, o);

  o.Normal = normalize(mul(wdMatrix, o.Normal));

  // Setup lighting environment
  UnityGI gi;
  UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
  
  gi.indirect.diffuse = 0;
  gi.indirect.specular = 0;
  gi.light.color = 0;
  gi.light.dir = half3(0,1,0);
  // Call GI (lightmaps/SH/reflections) lighting function
  UnityGIInput giInput;
  UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
  giInput.light = gi.light;
  giInput.worldPos = worldPos;
  giInput.worldViewDir = worldViewDir;
  giInput.atten = 1;
  #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
    giInput.lightmapUV = IN.lmap;
  #else
    giInput.lightmapUV = 0.0;
  #endif
  #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
    giInput.ambient = IN.sh;
  #else
    giInput.ambient.rgb = 0.0;
  #endif

  LightingStandardSpecular_GI(o, giInput, gi);

  // call lighting function to output g-buffer
  outEmission = LightingStandardSpecular_Deferred (o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
  #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
    outShadowMask = UnityGetRawBakedOcclusions (IN.lmap.xy, float3(0, 0, 0));
  #endif
  #ifndef UNITY_HDR_ON
  outEmission.rgb = exp2(-outEmission.rgb);
  #endif
}


ENDCG

}

Pass {
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }
		ZWrite On ZTest Less

CGPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf

#pragma target 5.0

#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
#pragma multi_compile_shadowcaster


struct v2f_surf {
  V2F_SHADOW_CASTER;
};

// vertex shader
inline v2f_surf vert_surf (appdata_base v) {
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
  TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
  return o;
}

// fragment shader
inline float4 frag_surf (v2f_surf IN) : SV_Target {
 	SHADOW_CASTER_FRAGMENT(IN)
}


ENDCG

}

	// ---- meta information extraction pass:
	Pass {
		Name "Meta"
		Tags { "LightMode" = "Meta" }
		Cull Off

CGPROGRAM
// compile directives
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma target 5.0

#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
#pragma skip_variants INSTANCING_ON
#pragma shader_feature EDITOR_VISUALIZATION


struct v2f_surf {
  UNITY_POSITION(pos);
  float2 pack0 : TEXCOORD0; // _MainTexW
  UNITY_VERTEX_INPUT_INSTANCE_ID
  UNITY_VERTEX_OUTPUT_STEREO
};
float4 _MainTex_ST;

// vertex shader
v2f_surf vert_surf (appdata v) {
  UNITY_SETUP_INSTANCE_ID(v);
  v2f_surf o;
  UNITY_INITIALIZE_OUTPUT(v2f_surf,o);

  o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  return o;
}

// fragment shader
float4 frag_surf (v2f_surf IN) : SV_Target {
  UNITY_SETUP_INSTANCE_ID(IN);
  // prepare and unpack data
  Input surfIN;
  UNITY_INITIALIZE_OUTPUT(Input,surfIN);
  surfIN.uv_MainTex.x = 1.0;
  
  surfIN.uv_MainTex = IN.pack0.xy;
  #ifdef UNITY_COMPILER_HLSL
  SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
  #else
  SurfaceOutputStandardSpecular o;
  #endif



  // call surface function
  surf (surfIN, o);
  UnityMetaInput metaIN;
  UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
  metaIN.Albedo = o.Albedo;
  metaIN.Emission = o.Emission;
  metaIN.SpecularColor = o.Specular;
  return UnityMetaFragment(metaIN);
}


ENDCG

}
	}
  Fallback "Standard"
}

