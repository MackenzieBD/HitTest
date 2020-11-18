//
//  HT_Types.h
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#ifndef HT_Types_h
#define HT_Types_h

#include <simd/simd.h>

typedef enum HT_Buffer_Index
{
    HT_Vertex_Index = 0,
    HT_Uniform_Index = 1,
    HT_Texture_Index = 2
}HT_Buffer_Index;


typedef struct
{
    vector_float3   position,
                    normal;
    vector_float2   textCoor;
    uint            pickID,
                    facet;
}HT_Vertex;

typedef struct
{
    matrix_float4x4 normalsTransform[6],
                    nodeTransform[6],
                    perspectiveTransform;
    vector_float3   ambient,
                    lightColor,
                    lightPosition,
                    eyeDirection;
    float           constantAttenuation,
                    linearAttenuation,
                    quadradicAttenuation,
                    shininess,
                    strength;

}HT_Uniform;
 

#endif /* HT_Types_h */
