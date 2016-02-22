Shader "Unlit/ParticleUpdater"
{
	Properties
	{
		_Scale ("curl scale", Float) = 0.1
		_Speed ("curl speed", Float) = 1
		_Life ("life time", Float) = 30
		_Field ("field range", Vector) = (5,0.2,0,0)
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		
		#define CamR _Cam_W2C[0].xyz
		#define CamU _Cam_W2C[1].xyz
		#define CamF _Cam_W2C[2].xyz

		#define LIFE_SPAN o.pos.w-=unity_DeltaTime.x;
		#define ADD_FORCE(f) o.vel.xyz+=f;
		#define LOOP_IN_FIELD o.pos.xyz = (frac((o.pos.xyz+_Field.x)*_Field.y*0.5)-0.5)*_Field.x*2;
		#define CAM_SPACE_POS(wPos) mul(_Cam_W2C, float4(wPos,1)).xyz

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
			_Col,
			_SSCollTex,
			_DepthNormalBack,
			_DepthNormalFront;
		half4 _Pos_TexelSize;
		
		uniform float4x4 _Cam_W2C, _Cam_W2S, _Cam_S2C, _Cam_C2W,_Cam_C2S;
		uniform float4 _Cam_SParams, _Cam_PParams;

		uniform float2 _Field;
		float _Scale, _Speed, _Life;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy / v.vertex.w + 1.0)*0.5;
			return o;
		}
		inline float4 _ComputeScreenPos (float4 pos) {
			float4 o = pos * 0.5f;
			#if defined(UNITY_HALF_TEXEL_OFFSET)
			o.xy = float2(o.x, o.y*_Cam_PParams.x) + o.w * _Cam_SParams.zw;
			#else
			o.xy = float2(o.x, o.y*_Cam_PParams.x) + o.w;
			#endif
			
			o.zw = pos.zw;
			return o;
		}
		float2 sUV(float3 wPos)//screen space of main
		{
			float4 cPos = mul(_Cam_W2C, float4(wPos,1));
			cPos.w = 1;
			float4 sPos = mul(_Cam_C2S, cPos);
			sPos = _ComputeScreenPos(sPos);
			return sPos.xy/sPos.w;
		}
		float3 fullPos(float2 uv, float d){
			float n = _Cam_PParams.y;
			float f = _Cam_PParams.z;
			
			float w = d;
			float z = w*(2*(w-n)/(f-n)-1);
			float2 xy = w*(2*uv-1);
			
			float4 pos = float4(xy,z,w);
			pos = mul(_Cam_S2C,pos);
			pos.w = 1;
			pos = mul(_Cam_C2W,pos);
			
			return pos.xyz;
		}
		float3 rgb2hsv(float3 c)
		{
		    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

		    float d = q.x - min(q.w, q.y);
		    float e = 1.0e-10;
		    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}
		float3 hsv2rgb(float3 c)
		{
		    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		    return lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y) * c.z;
		}
		half3 curl3d(half3 pos){
			half2
				xy = tex2D(_NoiseTex, pos.xy + pos.z).xy,
				zx = tex2D(_NoiseTex, pos.zx + pos.y).xy;
			half3 c3d = 0;
			c3d.xy += xy;
			c3d.zx += zx;
			return c3d;
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
		pOut baseUpdate(pOut o){
			o.pos.xyz += o.vel.xyz*unity_DeltaTime.x;
			o.vel.xyz *= exp(-o.vel.w*unity_DeltaTime.x);
			return o;
		}
		pOut worldCurl(pOut o){
			half scale = _Scale;
			half speed = _Speed;

			for(int i = 0; i < 3; i++){
				float3 force = curl3d(o.pos.xyz*scale)*speed*unity_DeltaTime.x;
				ADD_FORCE(force)
				scale *= 2.0;
				speed *= 0.5;
			}

			return o;
		}

		pOut fragInit (v2f i)
		{
			pOut o;
			o.vel = float4(0,0,0,1);
			o.pos = float4(fullPos(i.uv,_Field), _Life);
			o.col = half4(hsv2rgb(half3(i.uv,1)),1);
			return o;
		}
		pOut emitFull(v2f i)
		{
			pOut o = createPOut(i);
			if(o.pos.w<0)
				o = fragInit(i);
			return o;
		}
		pOut example(v2f i){
			pOut o = createPOut(i);
			if(0<o.pos.w){
				o = worldCurl(o);
				o = baseUpdate(o);
				LOOP_IN_FIELD
				LIFE_SPAN
			}
			return o;
		}

		pOut noParticle (v2f i)
		{
			float id = i.uv.x*_Pos_TexelSize.x+i.uv.y;
			pOut o;
			o.vel = float4(0,0,0,1);
			o.pos = float4(fullPos(i.uv,_Field), -_Life-id);
			o.col = 0;
			return o;
		}
		pOut gravity(v2f i){
			pOut o = createPOut(i);
			if(0<o.pos.w){
				ADD_FORCE(float3(0,-1,0)*unity_DeltaTime.x)
				o = worldCurl(o);
				o = baseUpdate(o);
				LIFE_SPAN
			}
			return o;
		}
		pOut ssCollid(v2f i){
			pOut o = createPOut(i);
			float2 uv = sUV(o.pos.xyz+o.vel.xyz*unity_DeltaTime.x);
			if(uv.x<0||1<uv.x||uv.y<0||1<uv.y)
				o.pos.w -= 1;

			float4 nomd0 = tex2D(_DepthNormalBack, saturate(uv));
			float4 nomd1 = tex2D(_DepthNormalFront, saturate(uv));

			float depth = abs(CAM_SPACE_POS(o.pos.xyz).z);
			float d0 = distance(depth, nomd0.a);
			float d1 = distance(depth, nomd1.a);

			if(depth < nomd0.a && nomd1.a < depth){
				float3 normal = d0<d1 ? nomd0.xyz : nomd1.xyz;
				o.vel.xyz += normal*length(o.vel.xyz)*0.75;
//				o.col.rgb = normal;
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
			#pragma fragment fragInit
			#pragma target 3.0
			ENDCG
		}
		Pass//1
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment emitFull
			#pragma target 3.0
			ENDCG
		}
		Pass//2
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment example
			#pragma target 3.0
			ENDCG
		}
		Pass//3
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment noParticle
			#pragma target 3.0
			ENDCG
		}
		Pass//4
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment gravity
			#pragma target 3.0
			ENDCG
		}
		Pass//5
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment ssCollid
			#pragma target 3.0
			ENDCG
		}
	}
}