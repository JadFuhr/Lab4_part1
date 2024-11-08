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
                OUT.pos = UnityObjectToClipPos(IN.vertex); // Transform vertex position to clip space
                OUT.uv = IN.uv; // Pass UV coordinates

                // Transform normal and position to world space
                OUT.worldNormal = normalize(mul(IN.normal, (float3x3) unity_WorldToObject));
                OUT.worldPos = mul(unity_ObjectToWorld, IN.vertex).xyz;

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
                if (_WorldSpaceLightPos0.w == 0.0)
                    lightDir = normalize(_WorldSpaceLightPos0.xyz); // Directional light direction
                else
                {
                    lightDir = _WorldSpaceLightPos0.xyz - mul(IN.posOS, unity_ObjectToWorld);
                    attenuation = 1.0/length(lightDir);
                    lightDir = normalize(lightDir);
                }

                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos); // View direction
                float3 normal = normalize(IN.worldNormal); // Surface normal

                // Diffuse lighting calculation
    
                float NdotL = max(dot(normal, lightDir), 0.0); // Lambertian diffuse factor
                float4 diffuse = attenuation * _DiffuseColor * NdotL; // Diffuse component

                // Specular lighting calculation
    
                float3 reflectDir = reflect(-lightDir, normal); // Reflection direction
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), _Shininess); // Specular intensity
                float4 specular = spec * _SpecularColor; // Scale the specular colour by the calculated spec intensity

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