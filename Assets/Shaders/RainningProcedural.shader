Shader "Unlit/RainningProcedural"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Stencil
		{
			Ref 0
			Comp Always
			Pass Replace
		}
		Pass
		{
			Cull off blend srcAlpha oneMinusSrcAlpha
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			#include "UnityCG.cginc"
			struct RainPanel
			{
    			float3 normal;
    			float3 binormal;
    			float3 position;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
			};

			TextureCube _EnvReflect; SamplerState sampler_EnvReflect;
			StructuredBuffer<RainPanel> instancingBuffer;
			static const float2 vertices[4] = {
				float2(0.005, 0.03),
				float2(0.005, -0.03),
				float2(-0.005, -0.03),
				float2(-0.005, 0.03)
			};
			v2f vert (uint instancingID : SV_INSTANCEID, uint vertexID : SV_VertexID)
			{
				RainPanel p = instancingBuffer[instancingID];
				float2 vertOffset = vertices[vertexID];
				float3 worldPos = p.position + float3(0, 1, 0) * vertOffset.y + p.binormal * vertOffset.x;
				v2f o;
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				o.normal = p.normal;
				o.viewDir = worldPos - _WorldSpaceCameraPos;
				return o;
			}
			
			float4 frag (v2f i) : SV_TARGET
			{
				float3 dir = normalize(reflect(i.normal, normalize(i.viewDir)));
				float4 color = _EnvReflect.Sample(sampler_EnvReflect, dir);
				dir -= i.normal * 2;
				color += _EnvReflect.Sample(sampler_EnvReflect, dir);
				color += _EnvReflect.Sample(sampler_EnvReflect, i.viewDir);
				return float4(color.xyz * 0.25, 0.8);
			}
			ENDCG
		}
	}
}
