Shader "Unlit/TestShader"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		ZWrite off ZTest Always Cull off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 color : TEXCOORD0;
			};
			static const float2 verts[6] = 
			{
				float2(0,1),
				float2(0,-1),
				float2(-1, 1),
				float2(1,1),
				float2(1, -1),
				float2(0, 1)
			};
			v2f vert (uint instanceID : SV_INSTANCEID, uint vertexID : SV_VERTEXID)
			{
				v2f o;
				o.vertex = float4(verts[instanceID * 3 + vertexID], 0.5, 1);
				o.color = instanceID < 0.5 ? float3(0, 1, 0) : float3(0,0,1);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return float4(i.color, 1);
			}
			ENDCG
		}
	}
}
