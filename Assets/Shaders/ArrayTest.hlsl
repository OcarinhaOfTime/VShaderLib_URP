#ifndef CUSTOM_HEATMAP_INCLUDED
#define CUSTOM_HEATMAP_INCLUDED

#define MAX_POINTS 32
float4 _Points[MAX_POINTS];
uint _Size;

void Heatmap_float(float3 wpos, out float3 Color){
    Color = float3(1, 0, 0);
}

void Heatmap_half(half3 wpos, out half3 Color){
    Color = half3(1, 0, 0);
}
#endif