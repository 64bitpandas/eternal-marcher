Shader "GLSL basic shader" { // defines the name of the shader 
   SubShader { // Unity chooses the subshader that fits the GPU best
      Pass { // some shaders require multiple passes
        GLSLPROGRAM // here begins the part in Unity's GLSL

        #ifdef VERTEX // here begins the vertex shader

        void main() // all vertex shaders define a main() function
        {
        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            // this line transforms the predefined attribute 
            // gl_Vertex of type vec4 with the predefined
            // uniform gl_ModelViewProjectionMatrix of type mat4
            // and stores the result in the predefined output 
            // variable gl_Position of type vec4.
        }

        #endif // here ends the definition of the vertex shader


        #ifdef FRAGMENT // here begins the fragment shader
        
        float distance_from_sphere(in vec3 p, in vec3 c, float r)
        {
            return length(p - c) - r;
        }

        float map_the_world(in vec3 p)
        {
            float sphere_0 = distance_from_sphere(p, vec3(0.0), 1.0);

            return sphere_0;
        }

        vec3 calculate_normal(in vec3 p)
        {
            const vec3 small_step = vec3(0.001, 0.0, 0.0);

            float gradient_x = map_the_world(p + small_step.xyy) - map_the_world(p - small_step.xyy);
            float gradient_y = map_the_world(p + small_step.yxy) - map_the_world(p - small_step.yxy);
            float gradient_z = map_the_world(p + small_step.yyx) - map_the_world(p - small_step.yyx);

            vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

            return normalize(normal);
        }

        vec3 ray_march(in vec3 ro, in vec3 rd)
        {
            float total_distance_traveled = 0.0;
            const int NUMBER_OF_STEPS = 32;
            const float MINIMUM_HIT_DISTANCE = 0.001;
            const float MAXIMUM_TRACE_DISTANCE = 1000.0;

            for (int i = 0; i < NUMBER_OF_STEPS; ++i)
            {
                vec3 current_position = ro + total_distance_traveled * rd;

                float distance_to_closest = map_the_world(current_position);

                if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
                {
                    vec3 normal = calculate_normal(current_position);
                    vec3 light_position = vec3(2.0, -5.0, 3.0);
                    vec3 direction_to_light = normalize(current_position - light_position);

                    float diffuse_intensity = max(0.0, dot(normal, direction_to_light));

                    return vec3(1.0, 0.0, 0.0) * diffuse_intensity;
                }

                if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
                {
                    break;
                }
                total_distance_traveled += distance_to_closest;
            }
            return vec3(0.0);
        }

        void main()
        {
            vec2 uv = vUV.st * 2.0 - 1.0;

            vec3 camera_position = vec3(0.0, 0.0, -5.0);
            vec3 ro = camera_position;
            vec3 rd = vec3(uv, 1.0);

            vec3 shaded_color = ray_march(ro, rd);

            gl_FragColor = vec4(shaded_color, 1.0);
            gl_FragColor = o_color;
        }

        #endif // here ends the definition of the fragment shader

        ENDGLSL // here ends the part in GLSL 
      }
   }
}