Shader "Unlit/Raymarch"
{
    Properties
    {
        _ParamA ("ParamA", Float) = 0.5
        _ParamB ("ParamB", Float) = 10
        _T ("T", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 1e-3

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            float4 _MainTex_ST;
            float _ParamA;
            float _ParamB;
            float _T;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float GetDist(float3 p) {
                float dstA = dot(sin(p * _ParamA), 1);
                float dstB = dot(p % _ParamB, 1);
                float d = lerp(dstA, dstB, 0.5);

                return d;
            }

            float Raymarch(float3 ro, float3 rd) {
                float dO = 0;
                float dS;

                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * dO;
                    dS = GetDist(p);
                    dO += dS;
                    if (abs(dS) < SURF_DIST || dO > MAX_DIST) break;
                }

                return dO;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.01, 0);
                float3 n = GetDist(p) - float3(
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - .5;
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro, rd);
                fixed4 col = 0;

                if (d < MAX_DIST) {
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);
                    col.rgb = n;
                } else discard;

                return col;
            }
            ENDCG
        }
    }
}
