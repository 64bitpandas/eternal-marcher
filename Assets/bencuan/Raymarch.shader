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


        //=================
        // TRANSFORMS
        //=================
        
        // https://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/
        float3x3 rotateY(float theta) {
            float c = cos(theta);
            float s = sin(theta);

            return float3x3(
                float3(c, 0, s),
                float3(0, 1, 0),
                float3(-s, 0, c)
            );
        }

        //===========================
        // SDFs
        //===========================

        // https://iquilezles.org/articles/distfunctions/

        float sdSphere(float3 p, float3 r) {
            return length(p) - r;
        }

        float sdCube(float3 p, float3 r) {
            float3 q = abs(p) - r;
            return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
        }

        float opSmoothUnion(float d1, float d2, float k) {
            float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
            return lerp(d2, d1, h) - k*h*(1.0-h);
        }

        float opSmoothSubtraction(float d1, float d2, float k) {
            float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
            return lerp(d2, -d1, h) + k*h*(1.0-h); 
        }

        float opSmoothIntersection(float d1, float d2, float k) {
            float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
            return lerp(d2, d1, h) + k*h*(1.0-h); 
        }

        //===========================
        // DISTANCE ESTIMATION
        //===========================
        
        float DistanceEstimator(float3 pos) {
            // time-based path translation
            // pos = mul(pos, rotateY(_Time.y / 5));
            pos = pos + 1.0 * float3(0, (0.5 + _Level*0.01) * _Time.y, _Time.y);
            float3 mod_pos = pos - floor(pos / 2.0) * 2.0;

            // shape generation
            float3 r = _Level;
            float3 p = mod_pos - float3(1, 1, 1);
            p = mul(p, rotateY(_Time.y));

            float d = 1e10;
            float an = sin(_Time.y);
            
            float d1 = sdSphere(p-float3(0.0,0.5+0.3*an,0.0),r);
            float d2 = sdCube(p, r);
            // Shape combining
            float dt = opSmoothUnion(d1,d2,0.25);
            d = min(d, dt);

            // add noise
            // if (random(d1) < 0.5) {
            //     d1 = sphere_sd;
            // }
            return d;
        }

        //=================
        // RAYMARCH
        //================= 

        float3 calculate_normal(float3 p)
        {
            const float3 small_step = float3(0.0, 0.001, 0.0);

            float gradient_x = DistanceEstimator(p + small_step.xyy) - DistanceEstimator(p - small_step.xyy);
            float gradient_y = DistanceEstimator(p + small_step.yxy) - DistanceEstimator(p - small_step.yxy);
            float gradient_z = DistanceEstimator(p + small_step.yyx) - DistanceEstimator(p - small_step.yyx);

            float3 normal = float3(gradient_x, gradient_y, gradient_z);

            return normalize(normal);
        }
    

        //=================
        // RAYMARCH
        //=================
            
            float3 Trace(float3 from, float3 direction) {
                float totalDistance = 0.0;
                int steps;
                for (steps = 0; steps < MAXSTEPS; steps++) {
                    float3 p = from + totalDistance * direction;
                    // p = mul(p, rotateY(_Time.y / 5));
                    float dist = DistanceEstimator(p);
                    totalDistance += dist;
                    if (dist < MINDIST) {
                        float3 normal = calculate_normal(p);
                        float3 lightPos = float3(0.0,1.0,0.0);
                        float3 dirToLight = normalize(dist - lightPos);
                        float diffuse_intensity = max(0.0, dot(normal, dirToLight));
                        // return normal * 0.5 + 0.5; //comment in for rainbow
                        float3 color = float3(0.2,0.8,1.0);
                        return color * diffuse_intensity + float3(0.05,0.05,0.2);
                    }
                }
                float ret = 1.0 - float(steps) / float(MAXSTEPS);
                return float3(ret,ret,ret);
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
                float3 dist = Trace(camPos, camViewDir);
                return fixed4(dist, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}