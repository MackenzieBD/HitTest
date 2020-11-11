//
//  HT_Dodecahedron.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "HT_Dodecahedron.h"
#import "HT_Types.h"
#import "HT_AppDefs.h"

@implementation HT_Dodecahedron
{
    NSData      *theData;
    NSUInteger  nodeID;
    float       scale;
}

- (instancetype) initAsNode: (NSUInteger)node
{
    self = [self init];
    
    if(self != nil)
    {
        nodeID = node;
        scale = 1.0;
    }
    
    return self;
}

- (NSData *)vertexData
{
    
    if( theData == nil)
    {
        float   Dc = 0.57735 * scale,         // root(3) / 3
                Dn = 0.93417235896 * scale,
                Ds = 0.35682208977 * scale;
        
        HT_Vertex       (*f)[3];
        int             facet, point, c;
        NSMutableData   *output;
        vector_float3   v1,
                        v2,
                        normal;
  
        // Texture Coordinates for the three triangles
        // making up a pentagonal face
        
        vector_float2 textMap[3][3]=
        {
            {
            simd_make_float2( 0.191 , 1.0 ),
            simd_make_float2( 0.0   , 1 - 0.588 ),
            simd_make_float2( 0.5   , 1 - 0.951 )
            },
            {
            simd_make_float2( 0.191 , 1.0 ),
            simd_make_float2( 0.5 , 1 - 0.951 ),
            simd_make_float2( 1.0 , 1 - 0.588 )
            },
            {
            simd_make_float2( 0.191 , 1.0 ),
            simd_make_float2( 1.0   , 1 - 0.588 ),
            simd_make_float2( 0.809 , 1.0 )
            }
        };

        // facet vertex indexes
        // three triangular facets compose each pentagonal face
        
        NSInteger       index[36][3] =
        {   {  0 , 12 ,   4 },
            {  0 ,  4,   13 },
            {  0 , 13 ,   1 },
            
            {  0 ,  1 , 15 },
            {  0 , 15 ,  5 },
            {  0 ,  5 , 14 },
            
            {  0 , 14 , 10 },
            {  0 , 10 ,  8 },
            {  0 ,  8 , 12 },
            
            {  1 , 13 ,  9 },
            {  1 ,  9 , 11 },
            {  1 , 11 , 15 },
            
            {  4 , 12 ,  8 },
            {  4 ,  8 , 16 },
            {  4 , 16 ,  6 },
            
            {  4 ,  6 , 17 },
            {  4 , 17 ,  9 },
            {  4 ,  9 , 13 },
            
            {  5 ,  7 , 18 },
            {  5 , 18 , 10 },
            {  5 , 10 , 14 },
            
            {  5 , 15 , 11 },
            {  5 , 11 , 19 },
            {  5 , 19 ,  7 },
            
            {  2 ,  3 , 17 },
            {  2 , 17 ,  6 },
            {  2 ,  6 , 16 },
            
            {  2 , 16 ,  8 },
            {  2 ,  8 , 10 },
            {  2 , 10 , 18 },
            
            {  2 , 18 ,  7 },
            {  2 ,  7 , 19 },
            {  2 , 19 ,  3 },
            
            {  3 , 19 , 11 },
            {  3 , 11 ,  9 },
            {  3 ,  9 , 17 }
        };
        
        // For the numbering of the vertexes see the diagram
        // in the READ ME file
        
        HT_Vertex   vertex[20] =
        {
            {
                { 0.0 ,  Dn , -Ds }    //0
            },
            {
                { 0.0 ,  Dn ,  Ds }    //1
            },
            {
                { 0.0 , -Dn , -Ds }    //2
            },
            {
                { 0.0 , -Dn ,  Ds }    //3
            },
            {
                { -Dn ,  Ds , 0.0 }    //4
            },
            {
                {  Dn ,  Ds , 0.0 }    //5
            },
            {
                { -Dn , -Ds , 0.0 }    //6
            },
            {
                {  Dn , -Ds , 0.0 }    //7
            },
            {
                { -Ds , 0.0 , -Dn }    //8
            },
            {
                { -Ds , 0.0 ,  Dn }    //9
            },
            {
                {  Ds , 0.0 , -Dn }    //10
            },
            {
                {  Ds , 0.0 ,  Dn }    //11
            },
            {
                { -Dc ,  Dc , -Dc }    //12
            },
            {
                { -Dc ,  Dc ,  Dc }    //13
            },
            {
                {  Dc ,  Dc , -Dc }    //14
            },
            {
                {  Dc ,  Dc ,  Dc }    //15
            },
            {
                { -Dc , -Dc , -Dc }    //16
            },
            {
                { -Dc , -Dc ,  Dc }    //17
            },
            {
                {  Dc , -Dc , -Dc }    //18
            },
            {
                {  Dc , -Dc ,  Dc }    //19
            }
        };
        
        output = [NSMutableData dataWithLength: sizeof(HT_Vertex [36][3])];
        f = [output mutableBytes];
        
        for( facet = 0, c = 0 ; facet < 36 ; facet++ , c++ )
        {
            for( point = 0 ; point < 3 ; point++ )
            {
                f[facet][point] = vertex[ index[facet][point]];
                f[facet][point].textCoor = textMap[facet % 3][point];
                f[facet][point].pickID = (int)nodeID;
                f[facet][point].facet = facet / 3;
            }
            
            v1[0]= f[facet][0].position[0] - f[facet][1].position[0];
            v1[1]= f[facet][0].position[1] - f[facet][1].position[1];
            v1[2]= f[facet][0].position[2] - f[facet][1].position[2];
            
            v2[0]= f[facet][2].position[0] - f[facet][1].position[0];
            v2[1]= f[facet][2].position[1] - f[facet][1].position[1];
            v2[2]= f[facet][2].position[2] - f[facet][1].position[2];
            
            normal = simd_cross( v1 , v2 );
            normal = simd_normalize( normal );
            
            f[facet][0].normal = normal;
            f[facet][1].normal = normal;
            f[facet][2].normal = normal;
        }
        
        theData = [NSData dataWithData: output];
    }
    
    return theData;
}

-(NSString *)description
{
    return @"Dodecahedron";
}
@end
