Shader "FX/SVL2/05_Hard_1Layer_Van_Dis" {
    Properties {
        [Enum(Add,1,Translucentert,10)] _Blend ("Blend Mode（混合模式）", Float) = 10
        [Enum(Front,2,Back,1,TwoSided,0)] _Cull ("Display Mode（显示模式）", Float) = 2
        _Color ("Color", Color) = (1,1,1,1)
        _Alpha ("Alpha（消散过程）", Range(0, 1)) = 1
        _Glow ("Glow（辉光强度）", Range(0, 5)) = 1
        [Header(MainTex)]
        _MainTex ("MainTex（主纹理贴图）", 2D) = "white" {}
        [Enum(Repeat,0,Clamp,1)] _WrapA ("Wrap Mode（ Main平铺模式）", Float) = 0
        _AngA ("MainAng（主纹理旋转角度）", Range(0, 360)) = 0
        [Header(VanTex)]
        _VanTex ("VanTex（消散贴图：A通道）", 2D) = "white" {}
        //[Enum(R,1,G,2,B,3,A,4)] _VanRGBA ("VanRGBA（选择通道）", Int) = 4
        _EdgeFeather ("Edge Feather（边缘羽化）", Range(1, 100)) = 100
        [Header(DisTex)]
        _DisTex ("DisTex（扭曲贴图：A通道）", 2D) = "white" {}
        //[Enum(R,1,G,2,B,3,A,4)] _DisRGBA ("DisRGBA（选择通道）", Int) = 4
        _DisStrength ("DisStrength（扭曲强度）", Range(0, 1)) = 0.1
        _DisSpeed ("XY:通道1速度；ZW:通道2速度", Vector) = (0.1, 0.2, -0.05, -0.1)
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha [_Blend]
            ZWrite Off
            Cull [_Cull]
                        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            sampler2D _MainTex,_VanTex,_DisTex; 
            fixed4 _Color,_DisSpeed,_MainTex_ST,_VanTex_ST,_DisTex_ST;
            int _AngA,_WrapA,_Test;
            fixed _Alpha,_EdgeFeather,_Glow,_DisStrength;
            struct a2v {
                fixed4 vertex : POSITION;
                fixed2 coord : TEXCOORD0;
                fixed4 vColor : COLOR;
            };
            struct v2f {
                fixed4 pos : SV_POSITION;
                fixed4 uv0 : TEXCOORD0;
                fixed4 uv1 : TEXCOORD1;
                fixed4 vColor : COLOR;
            };
            v2f vert (a2v v) {
                v2f o = (v2f)0;
                fixed b = 1.0/128.0;
                fixed2 uvT = clamp(v.coord,b,1-b);
                fixed time = -4 * (asin(_SinTime.y)+step(-_CosTime.y,0)*(1.57-asin(_SinTime.y)*2));//避免低端显卡出现数值过大的问题
                //fixed time = _Time.y;
                fixed2 disSpeed1 = time * _DisSpeed.xy; 
                fixed2 disSpeed2 = time * _DisSpeed.zw; 
                o.vColor = v.vColor;
                o.pos = UnityObjectToClipPos( v.vertex );
                fixed ang = (0.01745329*_AngA);
                fixed cosA = cos(ang);
                fixed sinA = sin(ang);
                fixed2 center = fixed2(0.5,0.5);
                fixed2 uvR = mul(uvT-center,fixed2x2( cosA, -sinA, sinA, cosA))+center;
                fixed2 uvMain = uvR * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv0.xy = lerp(uvMain,clamp(uvMain,0,1),_WrapA);
                o.uv0.zw = uvT * _VanTex_ST.xy + _VanTex_ST.zw;
                o.uv1.xy = (uvT + disSpeed1) * _DisTex_ST.xy + _DisTex_ST.zw;
                o.uv1.zw = (uvT * 1.25 + disSpeed2) * _DisTex_ST.xy + _DisTex_ST.zw;
                return o;
            }
            fixed4 frag(v2f i) : COLOR {
                fixed4 mainTex = tex2D(_MainTex,i.uv0.xy);
                fixed3 rcol = pow(max(0.001,(i.vColor.rgb*_Color.rgb*_Glow)),2.2);
                fixed3 finalColor = rcol * mainTex.rgb;
                fixed dis1 = tex2D(_DisTex,i.uv1.xy).w;
                fixed dis2 = tex2D(_DisTex,i.uv1.zw).w;
                fixed2 disTex = fixed2(dis1,dis2);
                fixed2 a = disTex * 2 - 1 ;
                fixed2 vanUV = i.uv0.zw + a * _DisStrength;
                fixed vanTex = tex2D(_VanTex,vanUV).w;
                fixed van = 1.0 - (_Alpha * i.vColor.a);
                fixed c = clamp(vanTex,0.01,1)-van;
                fixed Alpha = mainTex.a * saturate( c * _EdgeFeather);
                return fixed4(finalColor,Alpha);
            }
            ENDCG
        }
    }
}
