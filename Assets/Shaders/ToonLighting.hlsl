#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

struct CustomLightingData{
    //mesh data
    float3 positionWS;
    float3 normalWS;
    float3 viewDir;
    float4 shadowCoord;
    float ambientOcclusion;

    //surface
    float3 albedo;
    float smoothness;

    // Baked lighting
    float3 bakedGI;
    float4 shadowMask;
    float fogFactor;
};

float GetSmoothnessPower(float rawSmoothness){
    return exp2(10 * rawSmoothness + 1);
}

#ifndef SHADERGRAPH_PREVIEW
float3 Bandify(float3 i, int bands){
    return floor(pow(i, 2) * bands) / bands;
}

float3 CustomGlobalIllumination(CustomLightingData d){
    float3 indirectDiff = d.albedo * d.bakedGI * d.ambientOcclusion;
    float3 reflectVec = reflect(-d.viewDir, d.normalWS);
    float fresnel = Pow4(1 - saturate(dot(d.viewDir, d.normalWS)));
    float3 indirectSpec = GlossyEnvironmentReflection(
        reflectVec, RoughnessToPerceptualRoughness(1-d.smoothness),
        d.ambientOcclusion
    ) * fresnel;
    return indirectDiff + indirectSpec * 5;
}

//toon lighting
float3 CustomLightHandling(CustomLightingData d, Light light){
    float3 radiance = light.color * light.shadowAttenuation * light.distanceAttenuation;
    float3 diffuse = saturate(dot(d.normalWS, light.direction));
    diffuse = Bandify(diffuse, 3) * .8;
    
    float specDot = saturate(dot(d.normalWS, normalize(light.direction + d.viewDir)));
    float3 spec = pow(specDot, GetSmoothnessPower(d.smoothness)) * diffuse;
    spec = Bandify(spec, 3);

    float3 color = d.albedo * radiance * (diffuse + spec);

    return color;
}
#endif

float3 CalculateCustomLighting(CustomLightingData d){
#ifdef SHADERGRAPH_PREVIEW
    float3 l = float3(.5, .5, 0);
    float3 diff = saturate(dot(d.normalWS, l));
    float specDot = saturate(dot(d.normalWS, normalize(l + d.viewDir))); 
    float spec = pow(specDot, GetSmoothnessPower(d.smoothness)) * diff;
    return d.albedo * (diff + spec);
#else
    Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, 1);
    MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);
    float3 color = CustomGlobalIllumination(d);
    color += CustomLightHandling(d, mainLight);

    #ifdef _ADDITIONAL_LIGHTS
    uint numAdditionalLights = GetAdditionalLightsCount();
    for(uint i = 0; i < numAdditionalLights; i++){
        Light l = GetAdditionalLight(i, d.positionWS, d.shadowMask);
        color += CustomLightHandling(d, l);
    }

    #endif
    color = MixFog(color, d.fogFactor);

    return color;
#endif
}

void CalculateCustomLighting_float(
    float3 Position, float3 Normal, float3 ViewDirection, float2 LightmapUV,
    float3 Albedo, float Smoothness, float AmbientOcclusion,
    out float3 Color){
    CustomLightingData d;
    d.albedo = Albedo;
    d.normalWS = Normal;
    d.viewDir = ViewDirection;
    d.smoothness = Smoothness;
    d.positionWS = Position;
    d.ambientOcclusion = AmbientOcclusion;

#ifdef SHADERGRAPH_PREVIEW
    d.shadowCoord = 0;
    d.bakedGI = 0;
    d.shadowMask = 0;
    d.fogFactor = 0;
#else
    float4 positionCS = TransformWorldToHClip(Position);
    #if SHADOWS_SCREEN
        d.shadowCoord = ComputeScreenPos(positionCS);
    #else
        d.shadowCoord = TransformWorldToShadowCoord(Position);
    #endif

    float2 lightmapUV = 0;
    OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);
    float3 vertexSH;
    OUTPUT_SH(Normal, vertexSH);
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
    d.shadowMask = SAMPLE_SHADOWMASK(lightmapUV);
    d.fogFactor = ComputeFogFactor(positionCS.z);
#endif

    Color = CalculateCustomLighting(d);
}

void CalculateCustomLighting_half(
    half3 Position, half3 Normal, half3 ViewDirection, half2 LightmapUV,
    half3 Albedo, half Smoothness, float AmbientOcclusion,
    out half3 Color){
    CustomLightingData d;
    d.albedo = Albedo;
    d.normalWS = Normal;
    d.viewDir = ViewDirection;
    d.smoothness = Smoothness;
    d.positionWS = Position;

#ifdef SHADERGRAPH_PREVIEW
    d.shadowCoord = 0;
    d.bakedGI = 0;
    d.shadowMask = 0;
#else
    float4 positionCS = TransformWorldToHClip(Position);
    #if SHADOWS_SCREEN
        d.shadowCoord = ComputeScreenPos(positionCS);
    #else
        d.shadowCoord = TransformWorldToShadowCoord(Position);
    #endif

    float2 lightmapUV = 0;
    OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);
    float3 vertexSH;
    OUTPUT_SH(Normal, vertexSH);
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
    d.shadowMask = SAMPLE_SHADOWMASK(lightmapUV);
#endif
    Color = CalculateCustomLighting(d);
}
#endif