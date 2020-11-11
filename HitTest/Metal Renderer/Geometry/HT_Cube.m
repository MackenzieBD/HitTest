//
//  HT_Cube.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "HT_Cube.h"
#import "HT_Types.h"

@implementation HT_Cube
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
    
    if( theData == nil )
    {
        float D = 0.57735 * scale; //route 3 over 3
        
        HT_Vertex       (*f)[3];
        int             facet, point, c, i;
        NSMutableData   *output;
        vector_float3   v1,
                        v2,
                        normal;
        
        simd_float2 textMap[6] =
        {
            {0.0,1.0},
            {0.0,0.0},
            {1.0,0.0},

            {0.0,1.0},
            {1.0,0.0},
            {1.0,1.0}
        };
        
        NSInteger       index[12][3] =
        {
            {0,1,2}, // U
            {0,2,3},
            
            {0,3,4}, // R
            {0,4,5},
            
            {0,5,6}, // F
            {0,6,1},
            
            {7,4,3}, // B
            {7,3,2},
            
            {7,2,1}, // L
            {7,1,6},
            
            {7,6,5}, // D
            {7,5,4}
        };
        
        HT_Vertex   vertex[8] =
        {
            {
                // 0 RUF
                { D, D, -D}
            },
            {
                // 1 LUF
                {-D, D,-D}
            },
            {
                // 2 LUB
                {-D, D,  D}
            },
            {
                // 3 RUB
                { D, D, D}
            },
            {
                // 4 RDB
                { D,-D, D}
            },
            {
                // 5 RDF
                { D,-D,-D}
            },
            {
                // 6 LDF
                {-D,-D,-D}
            },
            {
                // 7 LDB
                {-D,-D, D}
            }
        };
        
        output = [NSMutableData dataWithLength: sizeof(HT_Vertex [12][3])];
        f = [output mutableBytes];
        
        for( facet = 0 , c = 0 ; facet < 12 ; facet++ , c++ )
        {
            i = facet % 2;
            for( point = 0 ; point < 3 ; point++ )
            {
                f[facet][point] = vertex[ index[facet][point]];
                f[facet][point].textCoor = textMap[ point + i * 3 ];
                f[facet][point].pickID = (int)nodeID;
                f[facet][point].facet = facet / 2;
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
    return @"Cube";
}
@end
