Shader "Unlit/Occluder"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			Blend zero one
			CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			struct Point{
    			float3 vertex;
    			float4 tangent;
    			float3 normal;
    			float2 texcoord;
			};
			StructuredBuffer<Point> VertexBuffer;
			StructuredBuffer<float3x4> Transforms;
			float4 vert (uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID) : SV_POSITION
			{
				float4 worldPos = float4(mul(Transforms[instanceID], float4(VertexBuffer[vertexID].vertex, 1)), 1);
  				return mul(UNITY_MATRIX_VP, worldPos);
			}
			
			void frag (float4 vertex : SV_POSITION)
			{}
			ENDCG
		}
	}
}
