Shader "Hidden/ComputeCurl"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#define EPSILON 1e-3

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			static const float2 Dx = float2(EPSILON,0);
			static const float2 Dy = float2(0,EPSILON);
			
			sampler2D _MainTex;

			half2 curl(float2 uv){
				float dpdx = tex2D(_MainTex, uv + Dx.xy) - tex2D(_MainTex, uv - Dx.xy);
				float dpdy = tex2D(_MainTex, uv + Dy.xy) - tex2D(_MainTex, uv - Dy.xy);
				return float2(dpdy, -dpdx) / (2.0 * EPSILON);
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float o = tex2D(_MainTex, i.uv).r;
				float2 c = curl(i.uv);
				
				return half4(c,o,1);
			}
			ENDCG
		}
	}
}
