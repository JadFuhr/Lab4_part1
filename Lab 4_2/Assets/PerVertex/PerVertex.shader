Shader "Custom/PerVertex"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _AmbientColor ("Ambient Color", Color) = (0.2, 0.2, 0.2, 1) // Ambient light color
        _DiffuseColor ("Diffuse Color", Color) = (0.5, 0.5, 0.5, 1) // Diffuse light color
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)     // Specular light color
        _Shininess ("Shininess", Range(1, 256)) = 32          // Shininess factor for specular highlight
    }
    SubShader
    {
            Tags { "RenderType"="Opaque" }
            LOD 200     // level of detail (performance)

            Pass{



            HLSLPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0  // Use shader model 3.0 target, to get nicer looking lighting
            
            #include "UnityCG.cginc"
        
            sampler2D _MainTex;

            float4 _AmbientColor;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Shininess;

            struct VertexInput
            {
                float4 vertex : POSITION; // Vertex position in object space
                float3 normal : NORMAL; // Vertex normal vector
                float2 uv : TEXCOORD0; // Texture coordinates
            };

            // Output structure for vertex shader (input to fragment shader)

            struct VertexOutput
            {
                float4 pos : SV_POSITION; // Clip space position
                float3 color : COLOR; // Calculated color (ambient, diffuse, specular)
                float2 uv : TEXCOORD0; // Pass texture coordinates
            };

            // Vertex shader 

            VertexOutput vert(VertexInput IN)
            {
                VertexOutput OUT;
                OUT.pos = UnityObjectToClipPos(IN.vertex); // Transform vertex position to clip space
                OUT.uv = IN.uv; // Pass through UV coordinates

                // Transform normal to world space
                float3 worldNormal = normalize(mul(IN.normal, (float3x3) unity_WorldToObject));

               // Calculate ambient term
                float3 ambient = _AmbientColor.rgb;

                // Calculate diffuse term
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); // Directional light direction
                float NdotL = max(dot(worldNormal, lightDir), 0.0); // Lambertian diffuse factor
                float3 diffuse = _DiffuseColor.rgb * NdotL; // Diffuse component

                // Calculate specular term
                float3 viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, IN.vertex).xyz); // View direction
                float3 reflectDir = reflect(-lightDir, worldNormal); // Reflection direction
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), _Shininess); // Specular intensity
                float3 specular = _SpecularColor.rgb * spec; // Specular component

                // Combine lighting terms and assign to color output
                OUT.color = ambient + diffuse + specular;
                return OUT;
            }

            // Fragment shader
            float4 frag(VertexOutput IN) : SV_Target
            {
           
                float4 texColor = tex2D(_MainTex, IN.uv); // Sample texture color
                       
                return float4(IN.color, 1.0) * texColor;     // Multiply texture color by lighting color and output final color
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
