Shader "FX/SVL2/01_Soft_1Layer" {
    Properties {
        [Enum(Add,1,Translucentert,10)] _Blend ("Blend Mode（混合模式）", Float) = 10
        [Enum(Front,2,Back,1,TwoSided,0)] _Cull ("Display Mode（显示模式）", Float) = 2   
        _CoreColor ("CoreColor（核心颜色）", Color) = (1,1,1,1)
        _EdgeColor ("EdgeColor（边缘颜色）", Color) = (0.07843138,0.3921569,0.7843137,1)             
        _Alpha ("Alpha（透明度）", Range(0, 1)) = 1
        _Glow ("Glow（辉光强度）", Range(0, 10)) = 1
        [Header (MainTex)]
        _MainTex ("MainTex（主纹理贴图）", 2D) = "white" {}
        [Enum(Repeat,0,Clamp,1)] _Wrap ("Wrap Mode（ Main平铺模式）", Float) = 0
        _Ang ("MainAng（主纹理旋转角度）", Range(0, 360)) = 0

        
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
            sampler2D _MainTex; 
            fixed4 _EdgeColor,_MainTex_ST,_CoreColor;
            fixed _Alpha,_Glow;
            int _Wrap,_Ang;
            struct a2v {
                fixed4 vertex : POSITION;
                fixed2 texcoord0 : TEXCOORD0;
                fixed4 vColor : COLOR;
            };
            struct v2f {
                fixed4 pos : SV_POSITION;
                fixed2 uv0 : TEXCOORD0;
                fixed4 vColor : COLOR;
            };
            v2f vert (a2v v) {
                v2f o = (v2f)0;
                o.vColor = v.vColor;
                o.pos = UnityObjectToClipPos( v.vertex );
                fixed ang = (0.01745329*_Ang);
                fixed cosA = cos(ang);
                fixed sinA = sin(ang);
                fixed2 center = fixed2(0.5,0.5);
                fixed a = 1.0/128.0;//128像素剔除1像素
                v.texcoord0 = clamp(v.texcoord0,a,1-a);
                fixed2 uvA = mul(v.texcoord0-center,fixed2x2( cosA, -sinA, sinA, cosA))+center;
                fixed2 uvC = uvA * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv0 = lerp(uvC,clamp(uvC,0,1),_Wrap);
                return o;
            }
            fixed4 frag(v2f i) : COLOR {
                fixed4 mainTex = tex2D(_MainTex,i.uv0);
                fixed3 rcol = pow(max(i.vColor.rgb*lerp(_EdgeColor.rgb,_CoreColor.rgb * _Glow,mainTex.a),0.0001),2.2);
                fixed3 finalColor = rcol * mainTex.rgb ;
                fixed alpha = i.vColor.a * mainTex.a * _Alpha;
                return fixed4(finalColor,alpha);
            }
            ENDCG
        }
    }
}
