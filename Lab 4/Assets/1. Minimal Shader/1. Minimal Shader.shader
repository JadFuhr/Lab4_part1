Shader"HLSL basic shader" { // defines the name of the shader 
   SubShader { // Unity chooses the subshader that fits the GPU best
      Pass { // some shaders require multiple passes
         HLSLPROGRAM 
#include "UnityCG.cginc"
         #pragma vertex vert 
            // this specifies the vert function as the vertex shader 
         #pragma fragment frag
            // this specifies the frag function as the fragment shader
float4 vert(float4 vertexPos : POSITION) : SV_POSITION
            // vertex shader 
{
    return UnityObjectToClipPos(float4(1.0, 0.1, 1.0, 1.0) * vertexPos);
}

float4 frag(void) : COLOR // fragment shader
{
    return float4(0.6, 1.0, 0.0, 1.0);
               // (red = 0.6, green = 1.0, blue = 0.0, alpha = 1.0)
}

         ENDHLSL // here ends the part in HLSL
      }
   }
}