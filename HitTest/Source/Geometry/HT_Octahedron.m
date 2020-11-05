//
//  HT_Octahedron.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "HT_Octahedron.h"
#import "HT_Types.h"
#import "HT_AppDefs.h"

@implementation HT_Octahedron
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


- (NSData *)vertexData
{
    
    if( theData == nil)
    {
        float D = 1.0 * scale;
        
        HT_Vertex       (*f)[3];
        int             facet, point, c;
        NSMutableData   *output;
        vector_float3   v1,
                        v2,
                        normal;
                        
        vector_float2 textMap[3]=
        {
            simd_make_float2( 0.0 , 1.0 ),
            simd_make_float2( 0.5 , 1 - 0.866 ),
            simd_make_float2( 1.0 , 1.0 )
        };
        
        NSInteger       index[8][3] =
        {
            {0,1,2}, // RUF
            
            {0,2,3}, // RDF
            
            {0,4,1}, // LUF
            
            {0,3,4}, // LDF
            
            {5,2,1}, // RUB
            
            {5,3,2}, // RDB
            
            {5,4,3}, // LDB
            
            {5,1,4}  // LUB
        };
        
        HT_Vertex   vertex[6] =
        {
            {
                // 0 F
                { 0, 0, -D}
            },
            {
                // 1 U
                { 0, D, 0}
            },
            {
                // 2 R
                { D, 0, 0}
            },
            {
                // 3 D
                { 0,-D, 0}
            },
            {
                // 4 L
                {-D, 0, 0}
            },
            {
                // 5 B
                { 0, 0, D},
            }
        };
        
        output = [NSMutableData dataWithLength: sizeof(HT_Vertex [8][3])];
        f = [output mutableBytes];
        
        for( facet = 0, c = 0 ; facet < 8 ; facet++ , c++ )
        {
            for( point = 0 ; point < 3 ; point++ )
            {
                f[facet][point] = vertex[ index[facet][point]];
                f[facet][point].textCoor = textMap[point];
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
    return @"Octahedron";
}
@end
