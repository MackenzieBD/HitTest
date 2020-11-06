//
//  HT_Shaders.metal
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/26/20.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "HT_Types.h"



// Vertex shader outputs and fragment shader inputs
typedef struct
{
    
    float4 clipSpacePosition [[position]];
    float4 eyeSpacePosition;
    float2 textureCoordinate;
    float4 normal;
    float4 color;
    
} RasterizerData;


// *********************************************************
// ************ Shaders for Textured Models ****************
// *********************************************************


// Vertex function
vertex RasterizerData
vertexTexShader(uint vertexID [[vertex_id]],
             constant HT_Vertex *vertices [[buffer(HT_Vertex_Index)]],
             constant HT_Uniform *param [[buffer(HT_Uniform_Index)]])
{
    RasterizerData out;
    
    vector_float4  newPosition = float4( vertices[vertexID].position , 1 );
    
    newPosition = param->modelTransform[vertices[vertexID].pickID] * newPosition;
    out.eyeSpacePosition = newPosition;
    
    newPosition = param->perspectiveTransform * newPosition;
    out.clipSpacePosition = newPosition;
    
    // Apply rotations about the origin to the normals
    
    vector_float4 newNormal = float4( vertices[vertexID].normal , 1);
    out.normal = param->orientationTransform[vertices[vertexID].pickID] * newNormal;
    
    out.textureCoordinate = vertices[vertexID].textCoor;
    
    return out;
}

// Fragment function
fragment float4 fragmentTexShader(RasterizerData in [[stage_in]],
                                  constant HT_Uniform *param [[buffer(HT_Uniform_Index)]],
                                  texture2d<half> colorTexture [[ texture(HT_Texture_Index) ]],
                                  sampler textureSampler [[sampler(HT_Texture_Index)]])
{
       
       vector_float4   outColor;
       
       vector_float3    lightDirection;
       float            lightDistance;
       float            attenuation;
       vector_float3    halfVector;
       float            diffuse;
       float            specular;
       vector_float3    scatteredLight;
       vector_float3    reflectedLight;
       vector_float3    rgb;
       half4            colorSample;
       
        // Sample the texture to obtain a color
        colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
       
      // Apply Point-Light Source Lighting
      // Adapted from Example 7.4 in the OpenGL Programming Guide, ninth edition
    
       lightDirection = in.eyeSpacePosition.xyz - param->lightPosition;  //Metal left hand coordinates reversed from OpenGL
       lightDistance = length(lightDirection);
       lightDirection =  lightDirection / lightDistance;
       
       attenuation = 1.0 / (param->constantAttenuation +
                            param->linearAttenuation * lightDistance +
                            param->quadradicAttenuation * lightDistance * lightDistance);
       
       halfVector = normalize( lightDirection + param->eyeDirection);
       
       diffuse = max(0.0, dot(in.normal.xyz , lightDirection));
       specular = max(0.0, dot(in.normal.xyz , halfVector));
       
       
       if(diffuse == 0.0)
           specular = 0.0;
       else
           specular = pow(specular , param->shininess) * param->strength;
       
       scatteredLight = param->ambient + param->lightColor * diffuse * attenuation;
       reflectedLight = param->lightColor * specular * attenuation;
       
       rgb = min( vector_float4(colorSample).rgb * (scatteredLight + reflectedLight) , vector_float3(1.0));
       
       outColor = vector_float4(rgb, colorSample.a);
       
       return outColor;
    
}

// *********************************************************
// ************ Shaders: Hit Test Rendering ****************
// *********************************************************

// Vertex shader outputs and fragment shader inputs

typedef struct
{
    
    float4  clipSpacePosition [[position]];
    float4  eyeSpacePosition;
    float4  color;
    
} pickData;

// Vertex function for rendering a simplified scene to a hit test texture
vertex pickData
pickVertexShader(uint vertexID [[vertex_id]],
             constant HT_Vertex *vertices [[buffer(HT_Vertex_Index)]],
             constant HT_Uniform *param [[buffer(HT_Uniform_Index)]])
{
    pickData out;
    
    vector_float4  newPosition = float4( vertices[vertexID].position , 1 );
    
    newPosition = param->modelTransform[vertices[vertexID].pickID] * newPosition;
    out.eyeSpacePosition = newPosition;
    
    newPosition = param->perspectiveTransform * newPosition;
    out.clipSpacePosition = newPosition;
    
    // Encode the object ID as a color
    
    out.color.r = vertices[vertexID].pickID / 255.0;  // (0 to 255) integer encoded as (0.0 to 1.0) float
    out.color.g = vertices[vertexID].facet / 255.0;   // the rasterizer converts back when the color is stored in the texture
    out.color.b = 0.0;
    out.color.a = 1.0;
    
    return out;
}

// Fragment function
fragment float4 pickFragmentShader(pickData in [[stage_in]])
{
       return in.color;
}

