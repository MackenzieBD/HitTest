//
//  HT_Icosahedron.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/11/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "HT_Icosahedron.h"
#import "HT_Types.h"
#import "HT_AppDefs.h"

@implementation HT_Icosahedron
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
        float   Dn = 0.85065080835 * scale,
                Ds = 0.52573111212 * scale;
        
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
        
        NSInteger       index[20][3] =
        {
            {  0 ,  8 ,  1 },    // 0
            {  0 ,  1 ,  9 },    // 1
            {  0 ,  4 ,  8 },    // 2
            
            {  0 ,  5 ,  4 },    // 3
            {  0 ,  9 ,  5 },    // 4
            
            {  1 ,  8 ,  6 },    // 5
            {  1 ,  6 ,  7 },    // 6
            {  1 ,  7 ,  9 },    // 7
            
            {  4 , 10 ,  8 },    // 8
            {  4 ,  2 , 10 },    // 9
            {  4 ,  5 ,  2 },    //10
            
            {  5 ,  9 , 11 },    //11
            {  5 , 11 ,  2 },    //12
            
            {  6 ,  8 , 10 },    //13
            {  6 , 10 ,  3 },    //14
            {  6 ,  3 ,  7 },    //15
            
            {  7 , 11 ,  9 },    //16
            {  7 ,  3 , 11 },    //17
            
            {  2 ,  3 , 10 },    //18
            {  2 , 11 ,  3 }     //19
        };
        
        
        // For the numbering of the vertexes see the diagram
        // in the READ ME file
        
        HT_Vertex   vertex[12] =
        {
            {
                { -Ds ,  Dn,     0.0 }        // 0
            },
            {
                {  Ds ,  Dn,     0.0 }        // 1
            },
            {
                { -Ds , -Dn,     0.0 }        // 2
            },
            {
                {  Ds , -Dn,     0.0 }        // 3
            },
            {
                { -Dn,     0.0 ,  Ds }        // 4
            },
            {
                { -Dn,     0.0 , -Ds }        // 5
            },
            {
                {  Dn,     0.0 ,  Ds }        // 6
            },
            {
                {  Dn,     0.0 , -Ds }        // 7
            },
            {
                {     0.0 ,  Ds ,  Dn}        // 8
            },
            {
                {     0.0 ,  Ds , -Dn}        // 9
            },
            {
                {     0.0 , -Ds ,  Dn}        // 10
            },
            {
                {     0.0 , -Ds , -Dn}        // 11
            }
        };
        
        output = [NSMutableData dataWithLength: sizeof(HT_Vertex [20][3])];
        f = [output mutableBytes];
        
        for( facet = 0, c = 0 ; facet < 20 ; facet++ , c++ )
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
    return @"Icosahedron";
}

@end
