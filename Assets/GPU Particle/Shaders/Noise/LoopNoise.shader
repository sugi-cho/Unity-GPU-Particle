Shader "Noise/Loop/Simple"
{
	Properties
	{
		_S ("noise speed", Float) = 0.1
	}
	CGINCLUDE

	#pragma multi_compile CNOISE PNOISE

	#include "UnityCG.cginc"
	#include "/Assets/CGINC/ClassicNoise3D.cginc"
	
	float _S;
	v2f_img vert(appdata_base v)
	{
		v2f_img o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	}

	float4 frag(v2f_img i) : SV_Target 
	{
		float o = 0.5;
		float2 uv = i.uv * 8.0;

		float3 coord = float3(uv, _Time.y*_S);
		float3 period = float3(4, 4, 4) * 2;

		o += pnoise(coord, period)*0.5;

		return float4(o, o, o, 1);
	}

	ENDCG
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}
