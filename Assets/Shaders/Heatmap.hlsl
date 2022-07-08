#ifndef CUSTOM_HEATMAP_INCLUDED
#define CUSTOM_HEATMAP_INCLUDED

#define MAX_POINTS 32
float4 _Points[MAX_POINTS];
uint _PointsSize;
float _GlobalInt;

void Heatmap_float(float3 wpos, out float3 Color){
    float3 blendColor = 0;
    for(int i=0; i<_PointsSize; i++){
        blendColor += _Points[i].rgb;
    }

    blendColor /= (_PointsSize-1);
    Color = blendColor;
}

void Heatmap_half(half3 wpos, out half3 Color){
    Color = half3(1, 0, 0);
}
#endif