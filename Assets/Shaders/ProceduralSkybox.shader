Shader "Custom/ProceduralSkybox"
{
    Properties
    {
        _SunSize ("Sun Size", Range(0, 1)) = 0.05
        _SunIntensity ("Sun Intensity", float) = 2
        _SunCol ("Sun Colour", Color) = (1, 1, 1, 1)
        _SunDirectionWS("Sun DirectionWS", Vector) = (1, 1, 1, 1)
        _ScatteringIntensity("Scattering Intensity", float) = 1

        _StarTex ("Star Texture", 2D) = "white" { }
        _MilkyWayTex ("Milky Way Texture", 2D) = "white" { }
        _MilkyWayNoise ("Milky Way Noise", 2D) = "white" { }
        [HDR]_MilkyWayCol1 ("Milky Way Color 1", Color) = (1, 1, 1, 1)
        [HDR]_MilkyWayCol2 ("Milky Way Color 2", Color) = (1, 1, 1, 1)
        _MilkywayIntensity("Milkyway Intensity", float) = 1
        _FlowSpeed("Flow Speed", float) = 0.05

        _MoonCol ("Moon Color", Color) = (1, 1, 1, 1)
        _MoonIntensity("Moon Intensity", Range(1, 3)) = 1.2
        _MoonDirectionWS("Moon DirectionWS", Vector) = (1, 1, 1, 1)

        _StarIntensity("Star Intensity", float) = 1

    }
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "RenderPipeline" = "UniversalRenderPipeline" }
        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
    
        float4 _SunCol;
        float4 _SunDirectionWS;
        float4 _MoonDirectionWS;
        float _SunSize;
        float _SunIntensity;
        float _ScatteringIntensity;

        float4x4 _MoonWorld2Obj;
        float4 _MoonCol;
        float _MoonIntensity;
        float4x4 _MilkyWayWorld2Local;
        float4 _MilkyWayTex_ST;
        float4 _MilkyWayNoise_ST;
        float4 _MilkyWayCol1;
        float4 _MilkyWayCol2;
        float _FlowSpeed;
        float _StarIntensity;
        float _MilkywayIntensity;

        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Skybox"
            //Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #define PI 3.1415926535
            #define MIE_G (-0.990)
            #define MIE_G2 0.9801
            static const float PI2 = PI * 2;
            static const float halfPI = PI * 0.5;


            struct a2v
            {
                float4 positionOS: POSITION;
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float3 moonPos: TEXCOORD2;
                float3 positionOS: TEXCOORD3;
                float3 milkyWayPos: TEXCOORD4;
            };
            
            TEXTURE2D(_SkyGradientTex);
            SAMPLER(sampler_SkyGradientTex);

            TEXTURE2D(_StarTex);
            SAMPLER(sampler_StarTex);
            TEXTURE2D(_MoonTex);
            SAMPLER(sampler_MoonTex);
            TEXTURE2D(_MilkyWayTex);
            SAMPLER(sampler_MilkyWayTex);
            TEXTURE2D(_MilkyWayNoise);
            SAMPLER(sampler_MilkyWayNoise);



            v2f vert(a2v v)
            {
                v2f o;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                o.positionOS = v.positionOS.xyz;

                o.moonPos = mul((float3x3)_MoonWorld2Obj, v.positionOS.xyz) * 6;
                o.moonPos.x *= -1;

                o.milkyWayPos = mul((float3x3)_MilkyWayWorld2Local, v.positionOS.xyz) * _MilkyWayTex_ST.xyz;

                return o;
            }
            

            // Calculates the Mie phase function
            half getMiePhase(half eyeCos, half eyeCos2)
            {
                half temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
                temp = pow(temp, pow(_SunSize, 0.65) * 10);
                temp = max(temp, 1.0e-4); // prevent division by zero, esp. in half precision
                temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;

                return temp;
            }

            // Calculates the sun shape
            half calcSunAttenuation(half3 lightPos, half3 ray)
            {
                // half3 delta = lightPos - ray;
                // half dist = length(delta);
                // half spot = 1.0 - smoothstep(0.0, _SunSize, dist);
                // return spot * spot;

                half focusedEyeCos = pow(saturate(dot(lightPos, ray)), 5);
                return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos);
            }

            inline float2 VoronoiRandomVector(float2 UV, float offset)
            {
                float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
                UV = frac(sin(mul(UV, m)) * 46839.32);
                return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
            }

            void VoronoiNoise(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells)
            {
                float2 g = floor(UV * CellDensity);
                float2 f = frac(UV * CellDensity);
                float t = 8.0;
                float3 res = float3(8.0, 0.0, 0.0);

                for(int y=-1; y<=1; y++)
                {
                    for(int x=-1; x<=1; x++)
                    {
                        float2 lattice = float2(x,y);
                        float2 offset = VoronoiRandomVector(lattice + g, AngleOffset);
                        float d = distance(lattice + offset, f);
                        if(d < res.x)
                        {
                            res = float3(d, offset.x, offset.y);
                            Out = res.x;
                            Cells = res.y;
                        }
                    }
                }
            }

            float softLight( float s, float d )
            {
                return (s < 0.5) ? d - (1.0 - 2.0 * s) * d * (1.0 - d) 
                        : (d < 0.25) ? d + (2.0 * s - 1.0) * d * ((16.0 * d - 12.0) * d + 3.0) 
                                    : d + (2.0 * s - 1.0) * (sqrt(d) - d);
            }

            float3 softLight(float3 s, float3 d)
            {
                return float3(softLight(s.x, d.x), softLight(s.y, d.y), softLight(s.z, d.z));
            }



            half4 frag(v2f i): SV_Target
            {
                float3 normalizePosWS = normalize(i.positionOS);
                float2 sphereUV = float2(atan2(normalizePosWS.x, normalizePosWS.z) / PI2, asin(normalizePosWS.y) / halfPI);


                //抄Unity自带的太阳计算
                half4 sun = calcSunAttenuation(normalizePosWS, -_SunDirectionWS) * _SunIntensity * _SunCol;
                //自定义的一个类似大范围bloom的散射
                half4 scattering = smoothstep(0.5, 1.5, dot(normalizePosWS, -_SunDirectionWS.xyz)) * _SunCol * _ScatteringIntensity;
                //刚日出时散射强度大
                half scatteringIntensity = max(0.15, smoothstep(0.6, 0.0, -_SunDirectionWS.y));
                scattering *= scatteringIntensity;

                sun += scattering;

                //日出颜色与白天颜色插值
                half4 skyColor = SAMPLE_TEXTURE2D(_SkyGradientTex, sampler_SkyGradientTex, float2(sphereUV.y, 0.5));
                
                
                float star = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, sphereUV).r;
                star = saturate(star * star * star * 3) * _StarIntensity;

                //return float4(saturate(i.moonPos.xy), 0, 1);
                half4 moon = SAMPLE_TEXTURE2D(_MoonTex, sampler_MoonTex, (i.moonPos.xy + 0.5)) * step(0.5, dot(normalizePosWS, -_MoonDirectionWS.xyz));
                half4 moonScattering = smoothstep(0.97, 1.3, dot(normalizePosWS, -_MoonDirectionWS.xyz));

                moon = (moon * _MoonIntensity + moonScattering * 0.8) * _MoonCol;


                half4 milkyWayTex = SAMPLE_TEXTURE2D(_MilkyWayTex, sampler_MilkyWayTex, (i.milkyWayPos.xy + 0.5));
                half milkyWay = smoothstep(0, 0.7, milkyWayTex.r);
                

                half noiseMove1 = SAMPLE_TEXTURE2D(_MilkyWayNoise, sampler_MilkyWayNoise, (i.milkyWayPos.xy + 0.5) * _MilkyWayNoise_ST.xy + _MilkyWayNoise_ST.zw + float2(0, _Time.y * _FlowSpeed)).r;
                half noiseMove2 = SAMPLE_TEXTURE2D(_MilkyWayNoise, sampler_MilkyWayNoise, (i.milkyWayPos.xy + 0.5) * _MilkyWayNoise_ST.xy - _MilkyWayNoise_ST.zw - float2(0, _Time.y * _FlowSpeed)).r;
                half noiseStatic = SAMPLE_TEXTURE2D(_MilkyWayNoise, sampler_MilkyWayNoise, (i.milkyWayPos.xy + 0.5) * _MilkyWayNoise_ST.xy * 0.5).r;

                milkyWay *= smoothstep(-0.2, 0.8, noiseStatic + milkyWay);
                milkyWay *= smoothstep(-0.4, 0.8, noiseStatic);
                //milkyWay = smoothstep(0, 0.8, milkyWay);

                noiseMove1 = smoothstep(0.0, 1.2, noiseMove1);

                half milkyWay1 = milkyWay;
                half milkyWay2 = milkyWay;
                milkyWay1 -= noiseMove1 * (smoothstep(0.4, 1, milkyWayTex.g) + 0.4);
                milkyWay2 -= noiseMove2 * (smoothstep(0.4, 1, milkyWayTex.g) + 0.4);

                milkyWay1 = saturate(milkyWay1);
                milkyWay2 = saturate(milkyWay2);

                half3 milkyWayCol1 = milkyWay1 * _MilkyWayCol1.rgb * _MilkyWayCol1.a;
                half3 milkyWayCol2 = milkyWay2 * _MilkyWayCol2.rgb * _MilkyWayCol2.a;

                half milkyStar;
                half cell;
                VoronoiNoise(sphereUV, 20, 200, milkyStar, cell);
                
                //return pow(1 - saturate(milkyStar), 10);
                milkyStar = pow(1 - saturate(milkyStar), 50) * (smoothstep(0.2, 1, milkyWayTex.g) + milkyWayTex.r * 0.5) * 3;
                //float milkyStar = SAMPLE_TEXTURE2D(_StarTex, sampler_StarTex, sphereUV) * milkyWayTex.g;

                half3 milkywayBG = smoothstep(0.1, 1.5, milkyWayTex.r) * _MilkyWayCol1.rgb * 0.2;
                //return milkywayBG.rgbr;
                //half3 milkyCol = milkyWay1 * _MilkyWayCol1.rgb * _MilkyWayCol1.a + milkyWay2 * _MilkyWayCol2.rgb * _MilkyWayCol2.a;
                half3 milkyCol = (softLight(milkyWayCol1, milkyWayCol2) + softLight(milkyWayCol2, milkyWayCol1)) * 0.5 * _MilkywayIntensity + milkywayBG + milkyStar;
                milkyCol *= _MilkywayIntensity;
                //return skyColor + star + moon + milkyCol.rgbr + milkyStar;


                half4 finCol = skyColor + sun + star + moon + milkyCol.rgbr;

                return finCol;
            }
            ENDHLSL

        }
    }
}