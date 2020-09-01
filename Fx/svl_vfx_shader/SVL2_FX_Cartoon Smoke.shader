Shader "FX/SVL2/07_Cartoon Smoke" {
    Properties {
        [Header (CustomVertexStreams__Custom1.xy)]
        [Header (Note_ Do not use RGB for color in particle systems)]
        [Header (StepTex)]
        _StepTex ("StepTex（色阶贴图）", 2D) = "gray" {}        
        _Glow ("Glow（辉光强度）", Range(1, 64)) = 1
        _Feather ("Feather（边缘硬度）", Range(0, 30)) = 30
        _Noise ("Noise（Noise消散密度）", Range(0.1, 5)) = 0
        [Header (Light)]
        _LightSteps ("LightSteps（光照阶度）", Range(2, 32)) = 3
        _LightIntensity ("LightIntensity（光照强度）", Range(0, 2)) = 1
        _LightA ("LightColor（光照颜色饱和度）", Range(0, 1)) = 0.5
        _Gam ("Gammer(光照伽马值)", Range(1, 3)) = 2.2

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
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            //Cull off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Noise2D.cginc"
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
             fixed4 _LightColor0,_StepTex_ST;
             fixed _Glow,_Feather,_LightIntensity,_LightA,_Gam,_Noise;
             int _LightSteps;
             sampler2D _StepTex;
            struct a2v {
                fixed4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed4 texcoord0 : TEXCOORD0;
                fixed4 vCol : COLOR;
            };
            struct v2f {
                fixed4 pos : SV_POSITION;
                fixed4 uv0 : TEXCOORD0;
                fixed4 vCol : COLOR;
            };
            v2f vert (a2v v) {
                v2f o = (v2f)0;
                o.uv0.zw = v.texcoord0.zw;//自定义顶点数据 x = 控制stepTex文件在粒子生命时间的有限位移，y = 控制消散;
                fixed nos = (noise2D(fixed2(v.texcoord0.x,v.texcoord0.y) * _Noise ) + 1) * 0.5;
                v.vCol.z = (v.vCol.x + nos) * 0.5;
                o.vCol = fixed4(v.vCol.x,v.vCol.yzw);//顶点颜色.x=Depth      
                o.pos = UnityObjectToClipPos( v.vertex );
                fixed stepU = clamp(( 1 - o.vCol.x) + (o.uv0.z*2.0-1.0),0,1);//Step纹理U方向随着粒子生命位移
                o.uv0.xy = clamp(fixed2(stepU,v.texcoord0.y) * _StepTex_ST.xy + _StepTex_ST.zw,0.3,0.999);//Step贴图UV  
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                o.vCol.y = pow(0.5*dot(v.normal,lightDirection)+0.5,_Gam);  //光照
                return o;
            }
            fixed4 frag(v2f i) : COLOR {
                fixed4 stepTex = tex2D(_StepTex,i.uv0.xy);
                fixed3 Dark = stepTex.rgb ; 
                fixed3 lightColor = lerp(_LightColor0.rgb,dot(_LightColor0.rgb,fixed3(0.3,0.59,0.11)),_LightA);//_LightColor0.rgb;
                fixed3 bright = (lightColor * _LightIntensity + 1.0)  * Dark ;
                //光照风格化
                fixed light = saturate(floor( i.vCol.y * _LightSteps) / (_LightSteps - 1));
                fixed3 finalCol = lerp(Dark,bright,light) * (stepTex.a * _Glow + 1);
                fixed alpha = clamp((i.uv0.w - i.vCol.z)*_Feather,0,1) * i.vCol.a;
                fixed4 finalRGBA = fixed4(finalCol,alpha);
                return finalRGBA;
            }
            ENDCG
        }
    }
}
