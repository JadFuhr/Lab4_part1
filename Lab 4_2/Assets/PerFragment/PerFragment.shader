Shader "Custom/PerFragmentPhongShader"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}          
        _AmbientColor ("Ambient Color", Color) = (0.2, 0.2, 0.2, 1) 
        _DiffuseColor ("Diffuse Color", Color) = (0.5, 0.5, 0.5, 1) 
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)     
        _Shininess ("Shininess", Range(1, 256)) = 32     
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200    // Level of detail for performance

    Pass
    {
            HLSLPROGRAM
            #pragma vertex vert  // Vertex shader function
            #pragma fragment frag // Fragment shader function
            #include "UnityCG.cginc"
            

            sampler2D _MainTex;
            float4 _AmbientColor;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Shininess;

            // Input structure for vertex shader

            struct VertexInput
            {
                float4 vertex : POSITION; // Vertex position in object space
                float3 normal : NORMAL; // Vertex normal vector
                float2 uv : TEXCOORD0; // Texture coordinates
            };

            // Output structure from vertex shader, input to fragment shader

            struct FragmentInput
            {
                float4 pos : SV_POSITION; // Clip space position
                float3 worldNormal : TEXCOORD1; // World space normal
                float3 worldPos : TEXCOORD2; // World space position
                float2 uv : TEXCOORD0; // Pass through texture coordinates
                float3 posOS : TEXCOORD3;
            };

            // Vertex shader

            FragmentInput vert(VertexInput IN)
            {
                FragmentInput OUT;
                OUT.pos = UnityObjectToClipPos(IN.vertex); // transforms the vertex position to clip space for rendering on screen.
                OUT.uv = IN.uv; // Pass UV coordinates

                // Transform normal and position to world space

                OUT.worldNormal = normalize(mul(IN.normal, (float3x3) unity_WorldToObject));    // this line converts the object-space normal into world space 
                                                                                                //(adjusting for any rotations or scaling of the object) and ensures it has a length of 1

                OUT.worldPos = mul(unity_ObjectToWorld, IN.vertex).xyz;     // converts the vertex position to world space, essential for lighting calculations in the fragment shader.

                OUT.posOS = IN.vertex;

                return OUT;
            }

            // Fragment shader - performs lighting calculation per pixel

            float4 frag(FragmentInput IN) : SV_Target
            {
                float4 ambient = _AmbientColor; // Ambient lighting color

                // Lighting calculations in fragment shader
    
                float3 lightDir;

                float attenuation = 1.0;

                if (_WorldSpaceLightPos0.w == 0.0)          // If the light is directional (_WorldSpaceLightPos0.w == 0.0), it uses a fixed direction.
                {
                    lightDir = normalize(_WorldSpaceLightPos0.xyz); // Directional light direction
                }
                else
                {
                    lightDir = _WorldSpaceLightPos0.xyz - mul(IN.posOS, unity_ObjectToWorld);   // _WorldSpaceLightPos0.xyz represents the position of the light in world space. 

                                                                                                //mul(IN.posOS, unity_ObjectToWorld) converts the current vertex position from object
                                                                                                // space to world space, allowing it to be directly compared with the light's position.

                                                                                                //lightDir = _WorldSpaceLightPos0.xyz - mul(IN.posOS, unity_ObjectToWorld); calculates 
                                                                                                // the vector pointing from the vertex to the light source by subtracting the vertex's 
                                                                                                // world-space position from the light's world-space position.

                    attenuation = 1.0/length(lightDir);         // length(lightDir) computes the distance from the vertex to the light source by finding the magnitude (or length) 
                                                                // of the lightDir vector.

                                                                // attenuation = 1.0 / length(lightDir); calculates the attenuation factor, which decreases the light's intensity  
                                                                // as the distance between the vertex and the light source increases.

                    lightDir = normalize(lightDir);             // normalize(lightDir) scales the lightDir vector to a unit length (1), preserving only its direction.
                                                                //This normalized lightDir is used in the dot product calculations in the lighting model, allowing the 
                                                                // shader to use only the direction of the light without its distance affecting the calculations.
                }

                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos); // View direction

                float3 normal = normalize(IN.worldNormal); // Surface normal

                // Diffuse lighting calculation
    
                float NdotL = max(dot(normal, lightDir), 0.0); // using the dot product to determine the diffuse light intensity based 
                                                               // on the angle between the light direction and surface normal.

                // Specular lighting calculation

                float4 diffuse = attenuation * _DiffuseColor * NdotL; NdotL = max(dot(normal, lightDir), 0.0); //scales the light intensity by attenuation and the predefined diffuse color.

    
                float3 reflectDir = reflect(-lightDir, normal); // Reflection direction

                float spec = pow(max(dot(viewDir, reflectDir), 0.0), _Shininess); // spec = pow(max(dot(viewDir, reflectDir), 0.0), _Shininess), 
                                                                                  // where dot(viewDir, reflectDir) gives the angle between the view and reflection directions. 
                                                                                  // The pow function, with _Shininess, controls the sharpness of the specular highlight.

                float4 specular = spec * _SpecularColor; // specular = spec * _SpecularColor, scaling the specular intensity by the specular color.

                // Combine lighting components
                
                float4 lighting = ambient + diffuse + specular; // Add up the ambient, diffuse, and specular contributions

                // Apply lighting to texture color

                float4 texColor = tex2D(_MainTex, IN.uv); // Fetch the texture color at the fragment's UV coordinates

                return lighting * texColor; // Return the final colour by applying the lighting to the texture colour
            }
            ENDHLSL
        }
    }
FallBack "Diffuse" // Fallback shader in case this one fails to render
}