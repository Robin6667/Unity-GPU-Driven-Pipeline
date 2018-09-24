Shader "Hidden/OrthographiceDepth"
{
	SubShader
	{
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float4 _CameraState;	//xyz: camera forward w: farclipPlane
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				return dot(_CameraState.xyz, i.worldPos - _WorldSpaceCameraPos) / _CameraState.w;
			}
			ENDCG
		}
	}
}
