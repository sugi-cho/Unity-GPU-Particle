Shader "Unlit/ParticleVisualizer"
{
	Properties
	{
		_Size ("size", Float) = 0.1
	}
	CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
			float2 uv2 : TEXCOORD1;
			half4 color : COLOR;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			half4 color : TEXCOORD1;
			
			float4 vCenter : TEXCOORD2;
			float3 vRight : TEXCOORD3;
			float3 vUp : TEXCOORD4;
			float3 vForward : TEXCOORD5;
		};
		struct v2f_shadow
		{
			V2F_SHADOW_CASTER;
			float2 uv : TEXCOORD1;
		};
		
		uniform sampler2D _Pos,_Vel,_Col;
		half4 _Pos_TexelSize;
		uniform int _MRT_TexSize, _Offset;
		float4 _Col0,_Col1;
		float _Size;
		
		v2f vert (appdata v)
		{
			float numParticles = _Pos_TexelSize.w*_Pos_TexelSize.w;
			float id = floor(v.uv2.x) + _Offset;
			
			float2 uv = float2(frac(id/_MRT_TexSize),id/_MRT_TexSize/_MRT_TexSize);
			half4 pos = tex2Dlod(_Pos, float4(uv,0,0));
			half4 vel = tex2Dlod(_Vel, float4(uv,0,0));
			half4 col = tex2Dlod(_Col, float4(uv,0,0));
			
			v2f o;
			
			v.vertex.xyz = pos.xyz; // this is world space
			float4 vPos = mul(UNITY_MATRIX_V, v.vertex);
			o.vCenter = vPos;
			
			if(id < numParticles && pos.w > 0)
				vPos.xy += (v.uv-0.5)*_Size*saturate(pos.w);
			else
				vPos.xyz = 0;
			v.color = col;
			
			o.vertex = mul(UNITY_MATRIX_P, vPos);
			o.uv = v.uv;
			o.color = v.color;
			o.vRight = normalize(UNITY_MATRIX_V[0].xyz);
			o.vUp = normalize(UNITY_MATRIX_V[1].xyz);
			o.vForward = normalize(UNITY_MATRIX_V[2].xyz);
			return o;
		}
		v2f_shadow vertShadow(appdata v)
		{
			float numParticles = _Pos_TexelSize.w*_Pos_TexelSize.w;
			float id = floor(v.uv2.x) + _Offset;
			
			float2 uv = float2(frac(id/_MRT_TexSize),id/_MRT_TexSize/_MRT_TexSize);
			half4 pos = tex2Dlod(_Pos, float4(uv,0,0));
			half4 vel = tex2Dlod(_Vel, float4(uv,0,0));
			half4 col = tex2Dlod(_Col, float4(uv,0,0));
			
			v.vertex.xyz = mul(_World2Object, half4(pos.xyz,1)).xyz; // this is local space
			
			float4 wPos = mul(_Object2World, v.vertex);
			float3 wLitDir = UnityWorldSpaceLightDir( wPos.xyz );
			float3 lLitDir = mul(_World2Object, float4(wLitDir,0)).xyz;
			float3 lCamDir = mul(_World2Object, float4(_WorldSpaceCameraPos,1)).xyz;
			
			float3 right = normalize(cross(lLitDir, lCamDir));
			float3 up = normalize(cross(right, lLitDir));
			right = normalize(cross(up, lLitDir));
			
			if(id < numParticles && pos.w > 0)
				v.vertex.xyz += ((v.uv-0.5).x * right + (v.uv-0.5).y * up)*_Size*saturate(pos.w);
			else
				v.vertex.xyz = 0;
			
			v2f_shadow o;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			o.uv = v.uv;
			return o;
		}
		
		void frag (v2f i, 
			out half4 outDiffuse : SV_Target0,
			out half4 outSpecSmoothness : SV_Target1,
			out half4 outNormal : SV_Target2,
			out half4 outEmission : SV_Target3,
			out half outDepth : SV_Depth)
		{
			half3 vNormal;
			vNormal.xy = i.uv*2.0-1.0;
			half r2 = dot(vNormal.xy, vNormal.xy);
			if(r2 > 1.0)
				discard;
			vNormal.z = sqrt(1.0-r2);
			
			half4 vPos = half4(i.vCenter.xyz+vNormal*_Size, 1.0);
			half4 cPos = mul(UNITY_MATRIX_P, vPos);
			#if defined(SHADER_API_D3D11)
				outDepth = cPos.z/cPos.w;
			#else
				outDepth = (cPos.z/cPos.w) * 0.5 + 0.5;
			#endif
			if(outDepth <= 0)
				discard;
			
			outDiffuse = i.color;
			outSpecSmoothness = half4(0.1,0.1,0.1,0.8);
			outNormal.xyz = normalize(vNormal.x*i.vRight + vNormal.y*i.vUp + vNormal.z*i.vForward);
			outNormal = half4(outNormal.xyz*0.5+0.5,1);
			outEmission = 0;
		}
		// fragment shader for shadow caster
		fixed4 fragShadow (v2f_shadow i) : SV_Target {
			float2 uv = i.uv*2-1;
			if(dot(uv,uv) > 1.0)
				discard;
			SHADOW_CASTER_FRAGMENT(i)
		}
	ENDCG
	SubShader
	{
		Tags { "RenderType"="Opaque"}
		LOD 100
		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			ENDCG
		}
		pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			
			CGPROGRAM
			#pragma vertex vertShadow
			#pragma fragment fragShadow
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			ENDCG
		}
	}
}
