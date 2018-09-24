Shader "Hidden/ShadowDepth"
{
	SubShader
	{
		ZTest less
		Tags {"RenderType" = "Opaque"}
		CGINCLUDE
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
			#include "UnityCG.cginc"
			#include "CGINC/Procedural.cginc"
			float4 _ShadowCamDirection;
			float _ShadowCamFarClip;
			float4x4 _ShadowMapVP;
			float4 _NormalBiases;

			struct v2f
			{
				
				float4 vertex : SV_POSITION;
				float2 ndcXY : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			float3 _ShadowCamPos;
			float4 frag (v2f i) : SV_Target
			{
				bool2 judge = abs(i.ndcXY) > 1;
				if(judge.x || judge.y)
				{
					discard;
				}
				float dist = dot(_ShadowCamDirection.xyz, i.worldPos - _ShadowCamPos) + _ShadowCamDirection.w;
				dist /= _ShadowCamFarClip;
				return dist;
			}
		ENDCG
		//Pass 0: Left Up
		Pass
		{
			CGPROGRAM
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			v2f vert (uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
			{
				Point v = getVertex(vertexID, instanceID); 
				float4 worldPos = float4(v.vertex - _NormalBiases.x * v.normal, 1);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				o.ndcXY = o.vertex.xy;
				o.vertex.xy = o.vertex.xy * 0.5 - 0.5;
				o.worldPos = worldPos.xyz;
				return o;
			}


			ENDCG
		}

		//Pass 1: Right Up
		Pass
		{
			CGPROGRAM
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			v2f vert (uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
			{
				Point v = getVertex(vertexID, instanceID); 
				float4 worldPos = float4(v.vertex - _NormalBiases.y * v.normal, 1);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				o.ndcXY = o.vertex.xy;
				o.vertex.xy = o.vertex.xy * 0.5  + float2(0.5, -0.5);
				o.worldPos = worldPos.xyz;
				return o;
			}
			ENDCG
		}

		//Pass 2: Left Down
		Pass
		{
			CGPROGRAM
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			v2f vert (uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
			{
				Point v = getVertex(vertexID, instanceID); 
				float4 worldPos = float4(v.vertex - _NormalBiases.z * v.normal, 1);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				o.ndcXY = o.vertex.xy;
				o.vertex.xy = o.vertex.xy * 0.5  + float2(-0.5, 0.5);
				o.worldPos = worldPos.xyz;
				return o;
			}
			ENDCG
		}

		
		//Pass 3: Right Down
		Pass
		{
			CGPROGRAM
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			v2f vert (uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
			{
				Point v = getVertex(vertexID, instanceID); 
				float4 worldPos = float4(v.vertex - _NormalBiases.w * v.normal, 1);
				v2f o;
				o.vertex = mul(_ShadowMapVP, worldPos);
				o.ndcXY = o.vertex.xy;
				o.vertex.xy = o.vertex.xy * 0.5  + 0.5;
				o.worldPos = worldPos.xyz;
				return o;
			}
			ENDCG
		}
	}
}
