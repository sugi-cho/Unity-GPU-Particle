Shader "Unlit/DepthNormalDrawer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float3 normal : TEXCOORD0;
			float depth : TEXCOORD1;
			float4 vertex : SV_POSITION;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		
		v2f vert (appdata v)
		{
			half4 vPos = mul(UNITY_MATRIX_MV, v.vertex);
			v2f o;
			o.vertex = mul(UNITY_MATRIX_P, vPos);
			o.normal = UnityObjectToWorldNormal(v.normal);
			o.depth = abs(vPos.z);
			return o;
		}
		
		fixed4 frag (v2f i) : SV_Target
		{
			// sample the texture
			fixed4 col = half4(i.normal, i.depth);
			return col;
		}
	ENDCG
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}

		Pass
		{
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}
}
