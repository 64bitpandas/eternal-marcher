Shader "Custom/InfSphere" {
    Properties {
        // TODO add texture
        _MainTex ("Texture", 2D) = "white" {}

        // Loudness of input sound
        _Level ("Level", Float) = 0

        _SpecShine ("Specular Shine", Float) = 1.0

        _Color ("Color", Color) = (0.7, 1, 0.7, 1)

        _Rand ("Random", Float) = 0
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
            float _SpecShine;
            float _FreqBands[8];
            float4 _Color;
            float _Rand;
            
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
        // https://www.shadertoy.com/view/4tcGDr
        float3x3 rotateY(float theta) {
            float c = cos(theta);
            float s = sin(theta);

            return float3x3(
                float3(c, 0, s),
                float3(0, 1, 0),
                float3(-s, 0, c)
            );
        }

        float3x3 rotateX(float theta) {
            float c = cos(theta);
            float s = sin(theta);
            return float3x3(
                float3(1, 0, 0),
                float3(0, c, -s),
                float3(0, s, c)
            );
        }

        //===========================
        // SDFs
        //===========================

        // https://iquilezles.org/articles/distfunctions/

        float sdSphere(float3 p, float r) {
            return length(p) - r;
        }

        float sdCube(float3 p, float r) {
            float3 q = abs(p) - r;
            return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
        }
        
        float sdTorus(float3 p, float r) {
            float2 t = float2(r,r/2);
            float2 q2 = float2(length(p.xz)-t.x,p.y);
            return length(q2)-t.y;
        }

        float sdOctahedron(float3 p, float r) {
            float3 p_oct = abs(p);
            return (p_oct.x+p_oct.y+p_oct.z- r.x)*0.57735027;
        }

        float sdSolidAngle( float3 p, float2 c, float ra ) {
            // c is the sin/cos of the angle
            float2 q = float2( length(p.xz), p.y );
            float l = length(q) - ra;
            float m = length(q - c*clamp(dot(q,c),0.0,ra) );
            return max(l,m*sign(c.y*q.x-c.x*q.y));
        }

        
        // float sdTwistedTorus(float3 p, float r) {
        //     const float k = 10.0; // or some other amount
        //     float c = cos(k*(p.y));
        //     float s = sin(k*(p.y));
        //     float2x2  m = float2x2(c,-s,s,c);
        //     float3 q = float3((m*p).x, (m*p).z, p.y);
        //     return sdTorus(q, r);   
        // }

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
            pos = mul(pos, rotateX(_Level/5)); // CAMERA MOVEMENT
            pos = pos + 1.0 * float3(0, (0.5 + _Level*0.01) * _Time.y, _Time.y);
            float3 mod_pos = pos - floor(pos / 2.0) * 2.0;

            // shape generation
            float r = _Level;
            float3 p = mod_pos - float3(1, 1, 1);
            p = mul(p, rotateY(_Time.y));

            float d = 1e10;
            float an = sin(_Time.y);

            float3 p2 = p-float3(0.0,0.5+0.3*an,0.0);

            // Shape combining
            float d1 = sdSphere(p2, r);
            float d2 = sdCube(p, r);
            if (_Rand == 1) {
                d1 = sdTorus(p2, r);
                d2 = sdOctahedron(p, r);
            } else if (_Rand == 2) {
                d1 = sdCube(p2, r);
                // d2 = sdTwistedTorus(p, r);
                d2 = sdSolidAngle(p, float2(3.0,4.0)/5.0, r);
            } else if (_Rand == 3) {
                d1 = sdOctahedron(p2, r);
                d2 = sdSolidAngle(p, float2(3.0,4.0)/5.0, r);
            } else if (_Rand == 4) {
                d1 = sdSphere(p2, r);
                d2 = sdTorus(p, r);
            }
            
            float dt = opSmoothUnion(d1,d2,0.25);
            d = min(d, dt);
            
            return d;
        }

        //=================
        // RAYMARCH
        //================= 

        float3 calculate_normal(float3 p)
        {
            const float3 small_step = float3(0.001, 0.0, 0.0);

            float gradient_x = DistanceEstimator(p + small_step.xyy) - DistanceEstimator(p - small_step.xyy);
            float gradient_y = DistanceEstimator(p + small_step.yxy) - DistanceEstimator(p - small_step.yxy);
            float gradient_z = DistanceEstimator(p + small_step.yyx) - DistanceEstimator(p - small_step.yyx);

            float3 normal = float3(gradient_x, gradient_y, gradient_z);

            return normalize(normal);
        }
    

        //====================
        // RAYMARCH + SHADING
        //====================
        float4 HueShift (float4 col, float Shift) {
            float3 temp = float3(0.55735,0.55735,0.55735);
            float3 P = temp*dot(temp,col.xyz);
            float3 U = col-P;
            float3 V = cross(temp,U);    
            float3 col2 = U*cos(Shift*6.2832) + V*sin(Shift*6.2832) + P;
            return float4(col2,1.0);
        }

        // https://www.shadertoy.com/view/MsjXRt

            float dist(float2 p0, float2 pf){return sqrt((pf.x-p0.x)*(pf.x-p0.x)+(pf.y-p0.y)*(pf.y-p0.y));} // https://www.shadertoy.com/view/4tjSWh
            
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
                        float3 dirToLight = normalize(lightPos - p);

                        // Diffuse shading
                        float diffuse_intensity = max(0.0, dot(normal, dirToLight));

                        // Blinn-Phong shading
                        float3 halfV = normalize(direction + dirToLight);
                        float specular = pow(max(0.0, dot(normal, halfV)), _SpecShine);

                        float3 color = _Color.xyz;
                        return color*0.1 + (color * diffuse_intensity) + (color * specular);
                    }
                }
                float d = dist(_ScreenParams.xy*0.5,from.xy)*(_SinTime[3]+1.5)*0.003;
                float4 bgCol = lerp(HueShift(_Color, 0.5), _Color*0.5, d); // Radial gradient
                return bgCol;
                float ret = float(steps) / float(MAXSTEPS);
                return 0.1*HueShift(_Color, -0.05);
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