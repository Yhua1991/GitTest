Shader "FX/SVL2/06_Blood"
{
	Properties
	{
		[Header (AgePercent     StableRandom)]
		
		_MainTex ("Mask Texture", 2D) = "white" {}
		_U ("粒子长宽比(y/x)", float) = 1
		_NoiseDen ("Noise 密度", range(0,5)) = 0.2
		_DisStr ("扭曲强度", range(0,1)) = 0.2
		_AlphaMin ("Alpha Clip 出血量（值越大血越少）", Range (0, 1.0)) = 0.1
		_FallOffset ("Gravity 重力偏移", range(-1,1)) = -0.5 
	}

	SubShader
	{
		Tags 
		{
            "IgnoreProjector"="True"
            "Queue"="Transparent"
        }

		Pass 
		{
            Name "FORWARD"
            Tags 
            {
                "LightMode"="ForwardBase" 
            }
			
			Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "Noise2D.cginc"
			#include "UnityCG.cginc"
			//#include "AutoLight.cginc"
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0					
			fixed _AlphaMin;
			sampler2D _MainTex; float4 _MainTex_ST; 
			half _U,_NoiseDen;
			fixed _DisStr;
			half _FallOffset;
			struct a2v
			{
				float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord0 : TEXCOORD0; 
                float4 color : COLOR;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 color : Color;
				float4 vertLight : TEXCOORD2;
				float2 customData : TEXCOORD3; //x:粒子生命，y:随机




			};

			v2f vert (a2v v)
			{
				v2f o = (v2f)0;
				o.customData = float2(v.texcoord0.z,v.texcoord0.w);//x：消散，y:粒子生命，z:随机
				float lifetime = o.customData.x;//粒子生命				
				lifetime = (_FallOffset + 1) * lifetime;
				float4 fallPos = float4(0,lifetime,0,0);
				o.vertex = UnityObjectToClipPos(v.vertex) + fallPos;
				o.color = v.color;				
				o.uv.xy = v.texcoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//……………………………………………………………………
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{	

				fixed noise = noise2D((i.uv.xy + i.customData.yy ) * fixed2(_U,1) * _NoiseDen ) * _DisStr * i.customData.xx;
				fixed mainTex = tex2D(_MainTex, clamp(i.uv.xy + noise,0.01,0.99)).a;
				fixed4 vCol = max(0.001, i.color);
				vCol.a =  saturate(((mainTex-_AlphaMin) - (1-i.color.a)) * 10 );//i.color.a控制消散
				
				return vCol;
			}
			ENDCG
		}

	}
}
