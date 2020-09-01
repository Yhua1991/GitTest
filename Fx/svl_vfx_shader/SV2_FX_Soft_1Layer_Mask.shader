Shader "FX/SVL2/02_Soft_1Layer_Mask" {
    Properties {
        [Enum(Add,1,Translucentert,10)] _Blend ("Blend Mode（混合模式）", Float) = 10
        [Enum(Front,2,Back,1,TwoSided,0)] _Cull ("Display Mode（显示模式）", Float) = 2
        _CoreColor ("CoreColor（核心颜色）", Color) = (1,1,1,1)
        _EdgeColor ("EdgeColor（边缘颜色）", Color) = (0.07843138,0.3921569,0.7843137,1)     
        _Alpha ("Alpha（透明度）", Range(0, 1)) = 1
        _Glow ("Glow（辉光强度）", Range(0, 5)) = 1
        [Header (MainTex)]
        _MainTex ("MainTex（主纹理贴图）", 2D) = "white" {}
        [Enum(Repeat,0,Clamp,1)] _WrapA ("Wrap Mode（ Main平铺模式）", Float) = 0
        _AngA ("MainAng（主纹理旋转角度）", Range(0, 360)) = 0
        _MainSpeed_U ("MainSpeed_U（主纹理U向速度）", Range(-3, 3)) = 0
		_MainSpeed_V ("MainSpeed_V（主纹理V向速度）", Range(-3, 3)) = 0
        [Header (MaskTex)]
        _MaskTex ("MaskTex（遮罩贴图：A通道）", 2D) = "white" {}
        [Enum(Repeat,0,Clamp,1)] _WrapB ("Wrap Mode（Mask平铺模式）", Float) = 0
        _AngB ("MaskAng（遮罩贴图旋转）", Range(0, 360)) = 0

        
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
            sampler2D _MainTex,_MaskTex; 
            fixed4 _EdgeColor,_MainTex_ST,_CoreColor,_MaskTex_ST;
            fixed _Alpha,_Glow,_MainSpeed_U,_MainSpeed_V;
            int _WrapA,_WrapB,_AngB,_AngA;
            struct a2v {
                fixed4 vertex : POSITION;
                fixed2 texcoord0 : TEXCOORD0;
                fixed4 vColor : COLOR;
            };
            struct v2f {
                fixed4 pos : SV_POSITION;
                fixed4 uv0 : TEXCOORD0;
                fixed4 vColor : COLOR;
            };
            v2f vert (a2v v) {
                v2f o = (v2f)0;
                o.vColor = v.vColor;
                o.pos = UnityObjectToClipPos( v.vertex );
                fixed time = -4 * (asin(_SinTime.y)+step(-_CosTime.y,0)*(1.57-asin(_SinTime.y)*2));//避免低端显卡出现数值过大的问题
                //fixed time = _Time.y;
                fixed2 mainSpeed = time * (fixed2(_MainSpeed_U, _MainSpeed_V)); 
                fixed ang01 = (0.01745329*_AngA);
                fixed cosA = cos(ang01);
                fixed sinA = sin(ang01);
                fixed2 center = fixed2(0.5,0.5);
                fixed2 uvA = mul(v.texcoord0-center,fixed2x2( cosA, -sinA, sinA, cosA))+center;
                fixed2 uv01 = (uvA + mainSpeed) * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv0.xy = lerp(uv01,clamp(uv01,0,1),_WrapA);
                fixed ang02 = (0.01745329*_AngB);
                fixed cosB = cos(ang02);
                fixed sinB = sin(ang02);
                fixed2 uvB = mul(v.texcoord0-center,fixed2x2( cosB, -sinB, sinB, cosB))+center;
                fixed2 uv02 = uvB * _MaskTex_ST.xy + _MaskTex_ST.zw;
                o.uv0.zw = lerp(uv02,clamp(uv02,0,1),_WrapB);
                return o;
            }
            fixed4 frag(v2f i) : COLOR {
                fixed4 mainTex = tex2D(_MainTex,i.uv0.xy);
                fixed4 maskTex =tex2D(_MaskTex,i.uv0.zw).w;
                fixed3 rcol = pow(max(i.vColor.rgb*lerp(_EdgeColor.rgb,_CoreColor.rgb * _Glow,mainTex.a),0.0001),2.2);
                fixed3 finalColor = rcol * mainTex.rgb ;
                fixed alpha = i.vColor.a * mainTex.a * _Alpha * maskTex;
                return fixed4(finalColor,alpha);
            }
            ENDCG
        }
    }
}
