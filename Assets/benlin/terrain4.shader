Shader "Custom/InfTerrains" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
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
            
            #define MAXSTEPS 100
            #define MINDIST 0.01
            float _Level;

            float noise (float3 n) 
			{ 
				return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float perlin_a (float3 n)
			{
				float3 base = floor(n * 64.0) * 0.015625;
				float3 dd = float3(0.015625, 0.0, 0.0);
				float a = noise(base);
				float b = noise(base + dd.xyy);
				float c = noise(base + dd.yxy);
				float d = noise(base + dd.xxy);
				float3 p = (n - base) * 64.0;
				float t = lerp(a, b, p.x);
				float tt = lerp(c, d, p.x);
				return lerp(t, tt, p.y);
			}

			float perlin_b (float3 n)
			{
				float3 base = float3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
				float3 dd = float3(0.015625, 0.0, 0.0);
				float3 p = (n - base) *  64.0;
				float front = perlin_a(base + dd.yyy);
				float back = perlin_a(base + dd.yyx);
				return lerp(front, back, p.z);
			}

			float fbm(float3 n)
			{
				float total = 0.0;
				float m1 = 1.0;
				float m2 = 0.1;
				for (int i = 0; i < 5; i++)
				{
					total += perlin_b(n * m1) * m2;
					m2 *= 2.0;
					m1 *= 0.5;
				}
				return total;
			}

			float3 heightmap (float3 n)
			{   
                // return perlin_a(n);
                float3 h1 = float3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);
                return h1 * * perlin_a(n) * (1-_Level) + 0.5*perlin_b(n*(_Level));
				// return float3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);
			}
			
			float map (float3 p)
			{
				return p.y-32.0*float4(float3((heightmap(float3(p.xz*0.005,1.0)*0.1)-1.0)),1.0).r;
			}
            
            float DistanceEstimator(float3 pos) {
                // translate
                pos = pos + 1.0 * float3(0, (0.5 + _Level*0.01) * _Time.y, _Time.y);
                float3 mod_pos = pos - floor(pos / 2.0) * 2.0;

                float d1 = length(mod_pos - float3(1, 1, 1)) - 0.54321;
                return d1;
                // return d1 * perlin_a(d1) * (1-_Level) + 0.5*perlin_b(d1*(_Level));
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
                return fixed4(dist - _Level, dist - _Level, dist - _Level, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}