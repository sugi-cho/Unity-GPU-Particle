Shader "Hidden/CopyDepthNormal"
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
		
		sampler2D _MainTex;
    	sampler2D _CameraGBufferTexture2;
    	sampler2D_float _CameraDepthTexture;

		float4 frag (v2f i) : SV_Target
		{
			float4 tex = tex2D(_CameraGBufferTexture2, i.uv);
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			d = LinearEyeDepth (d);
			tex.a = d;
			return tex;
		}
	ENDCG
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}
}
