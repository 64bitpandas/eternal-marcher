// https://www.shadertoy.com/view/tscBDl

Shader "Custom/infTerrain" {
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
            
            float max_steps = 500.;
            float max_dist = 1000.;
            float e = 1e-3;
            float camSize = 5.;
            float3 lightPos = float3(10., 10, 00.);
            float samples = 1.;
            float cyl( float3 p, float h, float r )
            {
            float2 d = abs(float2(length(p.xz),p.y)) - float2(h,r);
            return min(max(d.x,d.y),0.0) + length(max(d,0.0));
            }
            float cc( float3 p, float h, float r1, float r2 )
            {
            float2 q = float2( length(p.xz), p.y );
            float2 k1 = float2(r2,h);
            float2 k2 = float2(r2-r1,2.0*h);
            float2 ca = float2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
            float2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot(k2, k2), 0.0, 1.0 );
            float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
            return s*sqrt( min(dot(ca, ca),dot(cb, cb)) );
            }
            float mandel(float3 p) {
                float3 z = p;
                float dr = 1.;
                float r = 0.0;
                float power = 3.;
                for (int i = 0; i < 100; i ++) {
                    r = length(z);
                    if (r > 2.0) {
                        break;
                    }
                    float thata = acos(z.z/r) * power;
                    float phi = atan2(z.y, z.x) * power;
                    float zr = pow(r, power);
                    dr = pow(r, power-1.) * power * dr + 1.;
                    z = zr * float3(sin(thata) * cos(phi), sin(phi) * sin(thata), cos(thata));
                    z += p;
                }
                return 0.5 * log(r) * r / dr;
            }

            float3 rep( in float3 p, in float c, in float3 l)
            {
                float3 q = p-c*clamp(round(p/c),-l,l);
                return q;
            }

            float4 uni(float4 a, float4 b) {
                return a.w < b.w? a : b;
            }
            float4 difr(float4 a, float4 b) {
                return a.w > b.w? a : b;
            }
            float4 suni(float4 a, float4 b, float k) {
                float h = clamp( 0.5 + 0.5*(a.w-b.w)/k, 0.0, 1.0 );
                float3 c = lerp(a.rgb, b.rgb, h);
                float d = lerp( a.w, b.w, h) - k*h*(1.-h); 
                return float4(c, d);
            }

            float smax( float d1, float d2, float k ) {
                float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
                return lerp( d2, d1, h ) + k*h*(1.0-h); 
            }

            float smin( float d1, float d2, float k ) {
                float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
                return lerp( d2, d1, h ) - k*h*(1.0-h); 
            }

            float2x2 rot(float a) {
                float s = sin(a);
                float c = cos(a);
                return float2x2(c,-s,s,c);
            }
            float tor( float3 p, float2 t )
            {
            float2 q = float2(length(p.xz)-t.x,p.y);
            return length(q)-t.y;
            }
            float sphere( float3 p, float s )
            {
            return length(p)-s;
            }
            float box( float3 p, float3 b )
            {
            float3 q = abs(p) - b;
            return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }
            float hash(float2 p) {
                p = 50.* (p*0.3183099 - floor(p*0.3183099));
                return (p.x*p.y*(p.x+p.y) - floor(p.x*p.y*(p.x+p.y)));
            }

            float3 mushromStep(float3 p) {
                float val = clamp(abs(dot(sin(p*5.), sin(p*2.1)))/2., 0.3, 0.4);
                return float3(val/1., val/2., 0.0);
            }
            float n(float3 p) {
                float ou = sin(p.x/3.);
                ou += sin(p.z/2.);
                return ou/10.;
            }
            float noise( in float2 p )
            {
                float2 i = floor( p );
                float2 f = p - floor(p);
                
                float2 u = f*f*(3.0-2.0*f);

                return lerp( lerp( hash( i + float2(0.0,0.0) ), 
                                hash( i + float2(1.0,0.0) ), u.x),
                            lerp( hash( i + float2(0.0,1.0) ), 
                                hash( i + float2(1.0,1.0) ), u.x), u.y);
            }
            float terrain(float2 p) {
                float gs = 10000.;
                p = floor(p*gs)/gs;
                float scale = 0.5;
                float f  = 2.*noise( p*scale );
                    f  += (2.000)*noise( ((p*scale)*2.) + 100.0);
                    f  += (1.000)*noise( ((p*scale)*4.) + 1000.0);
                    f  += (0.500)*noise( ((p*scale)*16.) + 10000.0);
                    f  += (0.250)*noise( ((p*scale)*32.) + 10000.0);
                    f  += (0.125)*noise( ((p*scale)*64.) + 10000.0);
                    f  += (0.0625)*noise( ((p*scale)*300.) + 100000.0);
                f *= (1.0)*noise( ((p*scale)*0.2) + 24233.);
                f *= ((1.0)*noise( ((p*scale)*0.1) + 34541.)+1.);
                return f;
            }
            float4 SDF(float3 p) {
                float3 np = p;
            //   p = rep(p, 20., float3(10., 0.0, 10.));
            //   float3 pp = rep(p, 1., float3(100));
            //   float disp = min(sphere(pp, 1.0), box(pp, float3(1.)))+length(sin(p*5.)/3.);
            //   float shape1 = p.y-n(p);
            //   float4 shape2 = float4(mushromStep(p), lerp(cyl(p, 0.3, 7.)-0.5, disp, 0.1));
            //   float c = cc(rep(p-float3(0, 4, 0), 2.0, float3(0, 1.0, 0)), 1.0, 4.0, 2.5);
            //   float4 shape3 = float4(float3(0, 1, 0), c);
            //   float4 shape4 = float4(float3(0, 1.0, 0.0), cc((p-float3(0, 9.5, 0)), 2.0, 3.0, 0.0));
                //float4 o = suni(suni(suni(shape2, shape3, 2.0), shape4, 1.0), float4(float3(noise(np.xz/7.)), lerp(p.y,disp, 0.1)+7.), 1.0);
                float bb = (noise(p.xz*100.)+3.)/9.;
                float3 color = float3(0.4, 0.4, 0.6);
                if (p.y < (bb+0.7)/0.7) {
                    color = float3(0.5,0.0,0.0);
                }
                if (p.y < (bb+0.7)/1.2) {
                    color = float3(0.25,0.0,0.0);
                }
                if (p.y < (bb+0.7)/1.7) {
                    color = float3(0.1, 0.1, 0.1);
                }
                if (p.y < (bb+0.7)/2.5) {
                    color = float3(0.2, 0.5, 0.2);
                }
                if (p.y < 0.2) {
                    color = float3(0.2, 0.2, 0.5);
                }
                float4 o = float4(color, (p.y-terrain(p.xz)/2.));
                return o;
            }
            float softshadow( in float3 ro, in float3 rd, in float k )
            {
                float res = 1.0;
                float t = 0.0;
                for( int i=0; i<64; i++ )
                {
                    float4 kk;
                    float h = SDF(ro + rd*t).w/64.;
                    res = min( res, k*h/t );
                    if( res<0.001 ) break;
                    t += clamp( h, 0.01, 0.2 );
                }
                return clamp( res, 0.0, 1.0 );
            }
            float2 getDist(float3 ro, float3 rd, out float3 color) {
                float d0 = 0.01;
                float3 roo = ro;
                float3 rdd = rd;
                float steps = 0.0; 
                float3 c = float3(1.0,0.0,0.0);
                for (float i = 0.0; i < max_steps; i += 1.0) {
                    steps += 1.0;
                    float3 p = roo + rdd*d0;
                    float4 r = SDF(p);
                    float ds = r.w;
                    d0 += ds;
                    if (ds<e||ds>max_dist) {
                        c = r.xyz;
                        break;
                    };
                }
                color = c;
                return float2(d0, steps);
            }
            float3 getNormal(float3 p) {
                float d = SDF(p).w;
                float2 e = float2(.000001, 0);
                float3 n = d-float3(
                    SDF(p-e.xyy).w,
                    SDF(p-e.yxy).w,
                    SDF(p-e.yyx).w
                );
                return normalize(n);
            }
            float3 getLight(float3 p, float3 lightPos, float3 rd, float3 ro, float2 ray, float3 color) {
                float3 lp = normalize(lightPos-p);
                float3 norm = getNormal(p);
                float sha1 = softshadow( p+0.001*norm, lightPos, 2.0 );
                float l = length(p-lightPos)-1.0;
                float dif = dot(norm, lp)/clamp(l/1., 1., 100.0)*6.;
                float reflected = clamp(float((dot(reflect(rd, norm), lightPos)) - 10.0), 0.0, 1.0);
                dif = (dif+(reflected/(l/0.5)));
                if (ray.x < max_dist) {
                    dif -= clamp(min(ray.y/255., 0.5), 0.0, 0.25);
                    dif += 0.4;
                }
                dif /= 0.5;
                return (reflected/10.0 + color+clamp(ray.y/40.0, 0.0, 0.3));
                // return (reflected/10.0 + color+clamp(ray.y/40.0, 0.0, 0.3))*float3(clamp(dif, 0.0, 1.0))*float3(2.0, 2.0, 2.0);
            }

            float3 at = float3(10, 00, 10);
            
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

            fixed4 frag(v2f i) : SV_Target {
                float3 col = float3(0.0,0.0,0.0);
                // float2 mouse = ((iMouse.xy-.5*_screenParams.xy)/_screenParams.xy)*5.;
                // mouse.x *= _screenParams.x/_screenParams.y;
                // float r = noise(float2(iTime/5.))*5.;
                // float r1 = noise(float2((iTime+100.)/5.))*5.;
                // at.xz = at.xz + abs(float2(r, r1));
                // float3 ro = float3(at.x-10., 3., at.y-10.);
                float3 ro = float3(0.0,3.0,0.0);
                for (int i = 0; i < int(samples); i += 1) {
                    float2 uv = (i.vertex - 0.5 * _ScreenParams.xy) / _ScreenParams.y;
                    // float2 uv = ((i.vertex-0.5*_screenParams.xy)/_screenParams.xy);
                    uv.x *= _screenParams.x/_screenParams.y;
                    float3 c_z = normalize(at-ro);
                    float3 c_x = normalize(cross(float3(0,1,0), c_z));
                    float3 c_y = cross(c_z, c_x);
                    uv.x += (hash(uv+float(i))-0.5)/(_screenParams.y/2.);
                    uv.y += (hash(uv+1.+float(i))-0.5)/(_screenParams.x/2.);
                    float3 rd = normalize(uv.x * c_x + uv.y * c_y + 1.73 * c_z);
                    float3 color = float3(0);
                    float2 ray = getDist(ro, rd, color);
                    float dist = ray.x;
                    float3 p = ro+rd*dist;
                    float3 light = getLight(p, lightPos, rd, ro, ray, color);
                    float3 ocol = (light);
                    if (dist < max_dist) {
                        ocol += sqrt(ocol)/5.;
                        ocol /= 1.25+clamp(ray.y/30., 0.1, 5.0);
                    } else {
                    }
                    float val = abs(clamp(rd.y, 0.1, 1.0)+1.0)*0.9;
                    ocol = mix(ocol, float3(val/1.5, val/1.5, val), clamp(dist/40., 0.0, 1.0));
                    col += ocol;//ray.y/100.;//ocol;//ocol;
                }
                fragColor = float4(col/samples,1.0);
                return fragColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

