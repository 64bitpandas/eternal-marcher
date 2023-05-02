Shader "Custom/InfSphere" {
    Properties {
        // TODO add texture
        _MainTex ("Texture", 2D) = "white" {}

        // Loudness of input sound
        _Level ("Level", Float) = 0
    }

    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
        //===============
        // DEFINITIONS
        //===============

            #define MAXSTEPS 100
            #define MINDIST 0.01
            float _Level;
            sampler2D _MainTex;
            
        //===============
        // NOISE GEN
        //===============

            // https://forum.unity.com/threads/generate-random-float-between-0-and-1-in-shader.610810/
            float random (float3 n) { 
				return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float perlin_a (float3 n) {
				float3 base = floor(n * 64.0) * 0.015625;
				float3 dd = float3(0.015625, 0.0, 0.0);
				float a = random(base);
				float b = random(base + dd.xyy);
				float c = random(base + dd.yxy);
				float d = random(base + dd.xxy);
				float3 p = (n - base) * 64.0;
				float t = lerp(a, b, p.x);
				float tt = lerp(c, d, p.x);
				return lerp(t, tt, p.y);
			}

			float perlin_b (float3 n) {
				float3 base = float3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
				float3 dd = float3(0.015625, 0.0, 0.0);
				float3 p = (n - base) *  64.0;
				float front = perlin_a(base + dd.yyy);
				float back = perlin_a(base + dd.yyx);
				return lerp(front, back, p.z);
			}

        //===========================
        // DISTANCE ESTIMATION
        //===========================
            
            float DistanceEstimator(float3 pos) {
                // time-based path translation
                pos = pos + 1.0 * float3(0, (0.5 + _Level*0.01) * _Time.y, _Time.y);
                float3 mod_pos = pos - floor(pos / 2.0) * 2.0;

                // shape generation
                float3 r = _Level;
                float3 p = mod_pos - float3(1, 1, 1);
                float3 q = abs(p) - r;

                float sphere_sd = length(p) - r;
                float cube_sd = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);

                float d1 = cube_sd;

                // add noise
                if (random(d1) < 0.5) {
                    d1 = sphere_sd;
                }
                return d1 * perlin_a(d1) * (1-_Level) + 0.5*perlin_b(d1*(_Level));
            }
        

        //=================
        // RAYMARCH
        //=================
            
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