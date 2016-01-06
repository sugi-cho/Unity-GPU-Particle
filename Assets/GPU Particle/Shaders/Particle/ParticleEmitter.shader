Shader "Unlit/ParticleEmitter"
{
	Properties
	{
		_EPoint ("emit point", Vector) = (0,0,0,0)
		_Vel0 ("initial velocity", Vector) = (0,0,0,0)
		_Emission ("emission", Float) = 10
		_Color ("color", Color) = (1,1,1,1)
		_Life ("life time", Float) = 10
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGINC/Random.cginc"
		
		#define CamR _Cam_W2C[0].xyz
		#define CamU _Cam_W2C[1].xyz
		#define CamF _Cam_W2C[2].xyz

		#define LIFE_SPAN o.pos.w-=unity_DeltaTime.x;
		#define ADD_FORCE(f) o.vel.xyz+=f;
		#define LOOP_IN_FIELD o.pos.xyz = (frac((o.pos.xyz+_Field.x)*_Field.y*0.5)-0.5)*_Field.x*2;
		#define NUM_PARTICLES _Pos_TexelSize.z*_Pos_TexelSize.w

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
		
		struct pOut
		{
			float4 vel : SV_Target0;
			float4 pos : SV_Target1;// (pos.xyz, life)
			float4 col : SV_Target2;
		};

		uniform sampler2D
			_NoiseTex,
			_Vel,
			_Pos,
			_Col;
		half4 _Pos_TexelSize;
		
		uniform float4x4 _Cam_W2C, _Cam_W2S, _Cam_S2C, _Cam_C2W;
		uniform float4 _Cam_SParams, _Cam_PParams;

		uniform float4 _EPoint,_Vel0,_Color;
		uniform float _Emission,_Life;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy / v.vertex.w + 1.0)*0.5;
			return o;
		}

		pOut createPOut(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}

		pOut emitFromPos(v2f i){
			pOut o = createPOut(i);
			if(o.pos.w < 0){
				float3
					r1 = rand3(i.uv+float2(frac(_Time.x),-frac(_Time.y))),
					r2 = rand3(r1.xy+r1.yz+r1.zx);
				float3 randPos = float3(
					r1.x+r1.y*0.03,
					r1.z+r2.x*0.03,
					r2.y+r2.z*0.03
				)*2-1;
				randPos = normalize(randPos)*r1.y;
				float3 pos = _EPoint.xyz + randPos*_EPoint.w;
				LIFE_SPAN
				float id = i.uv.x*_Pos_TexelSize.x+i.uv.y;
				float d = distance(frac(o.pos.w),id);
				float emitRate = _Emission*unity_DeltaTime.x*0.5*_Pos_TexelSize.x*_Pos_TexelSize.y;
				if(d < emitRate){
					o.vel = _Vel0;
					o.vel.xyz += randPos;
					o.pos = float4(pos,_Life);
					o.col = _Color;
				}
			}
			return o;
		}
	ENDCG
	SubShader
	{
		ZTest Always

		Pass//0
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment emitFromPos
			#pragma target 3.0
			ENDCG
		}
	}
}