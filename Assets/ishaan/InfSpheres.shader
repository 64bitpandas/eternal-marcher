Shader "Custom/DistanceEstimator" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            #define MAXSTEPS 100
            #define MINDIST 0.01
            
            float DistanceEstimator(float3 pos) {
                // translate
                pos = pos + 1.0 * float3(0, 0.5 * _Time.y, _Time.y);
                float3 mod_pos = pos - floor(pos / 2.0) * 2.0;
                float d1 = length(mod_pos - float3(1, 1, 1)) - 0.54321;
                return d1;
            }
            
            float Trace(float3 from, float3 direction) {
                float totalDistance = 0.0;
                int steps;
                for (steps = 0; steps < MAXSTEPS; steps++) {
                    float3 p = from + totalDistance * direction;
                    float dist = DistanceEstimator(p);
                    totalDistance += dist;
                    if (dist < MINDIST) {
                        break;
                    }
                }
                return 1.0 - float(steps) / float(MAXSTEPS);
            }
            
            struct appdata {
                float4 vertex : POSITION;
            };
            
            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xy;
                return o;
            }
            
            sampler2D _MainTex;
            
            fixed4 frag (v2f i) : SV_Target {
                float2 uv = (i.vertex - 0.5 * _ScreenParams.xy) / _ScreenParams.y;
                float3 camPos = float3(0, 2, 0);
                float3 camViewDir = normalize(float3(uv.xy, 1.0));
                float dist = Trace(camPos, camViewDir);
                return fixed4(dist, dist, dist, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}