//
//  HT_Hemisphere.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 11/17/20.
//

#import "HT_Hemisphere.h"
#import "HT_Types.h"
#import "AAPLMathUtilities.h"

@implementation HT_Hemisphere
{
    NSData      *vertexData;
    NSUInteger  pickID;
    
}

-(NSData *)vertexData
{
    return vertexData;
}

-(instancetype)initAsNode: (NSUInteger) node;
{
    self = [super init];
    
    if( self != nil )
    {
        pickID = node;
        [self initVertexData];
    }
    
    return self;
}

-(void)initVertexData
{
    vector_float3   point[7],
                    facet[3];
    float           angle;
    matrix_float3x3 rotate;
    NSData          *aFacet;
    HT_Vertex       item;
    NSMutableArray  *facets;
    NSMutableData   *vertexes;
    NSUInteger      n;
    
    facets = [NSMutableArray array];
    vertexes = [NSMutableData data];
    
    point[0] = simd_make_float3(0.0, 0.0, 1.0);
    point[1] = simd_make_float3(1.0, 0.0, 0.0);
    
    rotate = matrix3x3_rotation(M_PI/3, 0.0 , 0.0 , 1.0 );
    for( n = 1 ; n < 6 ; n++ )
    {
        point[n+1] = simd_mul( rotate , point[n] );
        facet[0] = point[0];
        facet[2] = point[n];
        facet[1] = point[n+1];
        [facets addObject: [NSData dataWithBytes: facet
                                          length: sizeof(vector_float3 [3])]];
    }
    facet[2] = point[6];
    facet[1] = point[1];
    [facets addObject: [NSData dataWithBytes: facet
                                      length: sizeof(vector_float3 [3])]];
    
    [self tesselate: facets];
    [self tesselate: facets];
    [self tesselate: facets];
    
    for(aFacet in facets )
    {
        [aFacet getBytes: facet length: sizeof(vector_float4 [3])];
        
        point[6].x = (facet[0].x + facet[1].x + facet[2].x ) / 3.0;
        point[6].y = (facet[0].y + facet[1].y + facet[2].y ) / 3.0;
        point[6].z = (facet[0].z + facet[1].z + facet[2].z ) / 3.0;
        
        // calculate a rotation matrix to rotate the facet perpendicular to the
        // z axis.  This to use the x,y coordinates for texture coordinates.
        
        angle = atanf( point[6].y / point[6].x );
        rotate = matrix3x3_rotation( angle , 0.0 , 0.0, -1.0 );
        
        point[6] = simd_mul(rotate , point[6] );
        
        angle = atanf( point[6].x / point[6].z );
        rotate = simd_mul( matrix3x3_rotation(angle , 0.0 ,-1.0 , 0.0 ) , rotate);
        
        for(n = 0 ; n < 3 ; n++ )
        {
            item.position = facet[n];
            item.normal =  facet[n];
            item.pickID = (int)pickID;
            
            point[0] = simd_mul(rotate, facet[n] );
            
            item.textCoor.x = point[0].x + 0.5;
            item.textCoor.y = point[0].y + 0.5;
            
            [vertexes appendBytes: &item length: sizeof( HT_Vertex )];
        }
    }
    
    vertexData = [[NSData alloc] initWithData: vertexes ];
}

-(void)tesselate: (NSMutableArray *) facets
{
    vector_float3   points[6],
                    facet[3];
    NSUInteger      index,
                    maxIndex;
    
    maxIndex = [facets count];
    
    for( index = 0 ; index < maxIndex ; index++ )
    {
        [[facets objectAtIndex: index] getBytes: points
                                         length: sizeof(vector_float4 [3] ) ];
        
        points[3].x = (points[1].x + points[0].x) / 2.0;
        points[3].y = (points[1].y + points[0].y) / 2.0;
        points[3].z = (points[1].z + points[0].z) / 2.0;
        points[3] = simd_normalize( points[3] );
        
        points[4].x = (points[1].x + points[2].x) / 2.0;
        points[4].y = (points[1].y + points[2].y) / 2.0;
        points[4].z = (points[1].z + points[2].z) / 2.0;
        points[4] = simd_normalize( points[4] );
        
        points[5].x = (points[2].x + points[0].x) / 2.0;
        points[5].y = (points[2].y + points[0].y) / 2.0;
        points[5].z = (points[2].z + points[0].z) / 2.0;
        points[5] = simd_normalize( points[5] );
        
        facet[0] = points[3];
        facet[1] = points[4];
        facet[2] = points[5];
        
        [facets replaceObjectAtIndex: index
                          withObject: [NSData dataWithBytes: facet length: sizeof(vector_float3 [3])]];
        
        facet[0] = points[0];
        facet[1] = points[3];
        facet[2] = points[5];
        
        [facets addObject: [NSData dataWithBytes: facet length: sizeof(vector_float3 [3])] ];
        
        facet[0] = points[3];
        facet[1] = points[1];
        facet[2] = points[4];
        
        [facets addObject: [NSData dataWithBytes: facet length: sizeof(vector_float3 [3])] ];
        
        facet[0] = points[4];
        facet[1] = points[2];
        facet[2] = points[5];
        
        [facets addObject: [NSData dataWithBytes: facet length: sizeof(vector_float3 [3])] ];
        
    }
}

-(NSString *)description
{
    return @"Hemisphere Interior";
}
@end
