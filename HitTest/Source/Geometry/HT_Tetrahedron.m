//
//  HT_Tetrahedron.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//



#import "HT_Tetrahedron.h"
#import "HT_Types.h"
#import "HT_AppDefs.h"

@implementation HT_Tetrahedron 
{
    NSData      *theData;
    NSUInteger  nodeID;
    float       scale;
}

- (instancetype) initNode: (NSUInteger)node
{
    self = [self init];
    
    if(self != nil)
    {
        nodeID = node;
        scale = 1.0;
    }
    
    return self;
}

// Define a tetrahedron contained in a radius 1.0 sphere
// centered on the origin
// left hand coordinates, clockwise winding

- (NSData *)vertexData
{
    
    if( theData == nil )
    {
        float   D = 0.57735 * scale;    //route 3 over 3 i.e the radius of a unit sphere
        
        HT_Vertex       (*f)[3];
        int             facet, point;
        NSMutableData   *output;
        vector_float3   v1,
                        v2,
                        normal;
        
        NSUInteger       index[4][3] =
        {
            { 0, 2, 1},
            { 0, 1, 3},
            { 0, 3, 2},
            { 1, 2, 3}
        };
        
        
        vector_float2 textMap[3]=
        {
            simd_make_float2( 0.0 , 1.0 ),
            simd_make_float2( 0.5 , 1.0 - 0.866 ),
            simd_make_float2( 1.0 , 1.0 )
        };
        
        HT_Vertex   vertex[4] =
        {
            {
                // 0 Right Up Front
                { D, D, -D}
            },
            {
                // 1 Left Up Back
                {-D, D, D}
            },
            {
                // 2 Left Down Front
                {-D,-D, -D}
            },
            {
                // 3 Right Down Back
                { D,-D, D}
            }
        };
        
        
        output = [NSMutableData dataWithLength: sizeof(HT_Vertex [4][3])];
        f = [output mutableBytes];
        
        for( facet = 0  ; facet < 4 ; facet++  )
        {
    
            
            for( point = 0 ; point < 3 ; point++ )
            {
                f[facet][point] = vertex[ index[facet][point]];
                f[facet][point].textCoor = textMap[ point ];
                f[facet][point].pickID = (int)nodeID;
                f[facet][point].facet = facet;
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
    return @"Tetrahedron";
}
@end
