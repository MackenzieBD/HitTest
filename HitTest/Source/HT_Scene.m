//
//  HT_Scene.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/22/20.
//

#import "HT_Scene.h"
#import "HT_AppDefs.h"

@import simd;

#import "HT_Types.h"
#import "LightDefs.h"
#import "HT_Textures.h"
#import "HT_Dodecahedron.h"
#import "HT_Tetrahedron.h"
#import "HT_Octahedron.h"
#import "HT_Cube.h"
#import "HT_Icosahedron.h"

#import "AAPLMathUtilities.h"

// The figures are defined to fit in a 1" sphere
// The scene draws five of them across the x axis
// so the scene needs to be scaled down by a factor of seven

#define SCENE_SCALE (1.0/7.0)

#define ROOT2  0.7071
#define ROOT3  0.5773


@implementation HT_Scene
{
    id<MTLDevice>               device;
    id<HT_Figure>               node[5];
    
    id<MTLTexture>              pickTexture;
    id<MTLBuffer>               vertexBuffer[5],
                                uniformBuffer;
    id<MTLRenderPipelineState>  pickPipelineState;
    id<MTLDepthStencilState>    depthState;
    MTLRenderPassDescriptor     *pickRenderPassDescriptor;
    
    HT_Uniform                  *uniform;
    
    CGSize                      viewportSize;
    matrix_float4x4             partialRotation,
                                modelScale,
                                hitScale,
                                modelRotation,
                                modelTranslation,
                                scenePerspective,
                                pickPerspective,
                                nodeRotation[5],
                                nodeTransform[5],
                                nodeOrientation[5];
    
    float                       pickScaleFactor;
    
    HT_Textures                 *theTextures;
    
    NSUInteger                  vertexCount[5],
                                selection;
    
    vector_float3               axis[26];
    FILE                        *randomDevice;
}

-(instancetype)initWithDevice: d;
{
    NSData          *item;
    NSUInteger      n;
    
    self = [super init];
    
    if( self != nil )
    {
        device = d;
        selection = 0;
        
        theTextures = [[HT_Textures alloc] initWithMTLDevice: device];
        
        uniformBuffer = [device newBufferWithLength: sizeof(HT_Uniform) options: MTLResourceStorageModeShared ];
        uniform = [uniformBuffer contents];
        
        partialRotation = matrix4x4_identity();
        
        [self defaultLightModel];
        
        node[0] = [[HT_Tetrahedron alloc] initNode: 0];
        
        node[1] = [[HT_Octahedron alloc] initNode: 1];
        
        node[2] = [[HT_Icosahedron alloc] initNode: 2];
        
        node[3] = [[HT_Dodecahedron alloc] initNode: 3];
        
        node[4] = [[HT_Cube alloc] initNode: 4];
        
        modelTranslation = matrix4x4_translation( 0.0 , 0.0 , 26.66);
        
        nodeTransform[0] = matrix4x4_translation( -6.0 , 0.0 , 0.0 );
        nodeTransform[1] = matrix4x4_translation( -3.0 , 0.0 , 0.0 );
        nodeTransform[2] = matrix4x4_translation( 0.0 , 0.0 , 0.0 );
        nodeTransform[3] = matrix4x4_translation( 3.0 , 0.0 , 0.0 );
        nodeTransform[4] = matrix4x4_translation( 6.0 , 0.0 , 0.0 );
        
        for( n = 0 ; n < 5 ; n++ ) 
        {
            item = [node[n] vertexData];
            vertexCount[n] = [item length] / sizeof(HT_Vertex);
            vertexBuffer[n] = [device newBufferWithLength: [item length]
                                                  options: MTLResourceStorageModeShared ];
            
            [item getBytes: [vertexBuffer[n] contents] length: [item length]];
            
            nodeRotation[n] = matrix4x4_identity();
            nodeOrientation[n] = matrix4x4_identity();
        }
        
        [self initOffScreenView];
        [self initAxes];
        srandomdev();
        randomDevice = fopen("/dev/random", "r");
        
    }
    
    return self;
}



-(void)defaultLightModel
{
    NSArray *values;
    
    values = [DEF_AMBIENT componentsSeparatedByString: @","];
    uniform->ambient.r = [[values objectAtIndex: 0] floatValue];
    uniform->ambient.g = [[values objectAtIndex: 1] floatValue];
    uniform->ambient.b = [[values objectAtIndex: 2] floatValue];
    
    values = [DEF_LAMP_COLOR componentsSeparatedByString: @","];
    uniform->lightColor.r = [[values objectAtIndex: 0] floatValue];
    uniform->lightColor.g = [[values objectAtIndex: 1] floatValue];
    uniform->lightColor.b = [[values objectAtIndex: 2] floatValue];
    
    values = [DEF_POSITION componentsSeparatedByString: @","];
    uniform->lightPosition.x = [[values objectAtIndex: 0] floatValue];
    uniform->lightPosition.y = [[values objectAtIndex: 1] floatValue];
    uniform->lightPosition.z = [[values objectAtIndex: 2] floatValue];
    
    uniform->eyeDirection = vector3( 0.0f , 0.0f , 1.0f );
    
    uniform->constantAttenuation = [DEF_ATTEN0 floatValue];
    uniform->linearAttenuation = [DEF_ATTEN1 floatValue];
    uniform->quadradicAttenuation = [DEF_ATTEN2 floatValue];
    uniform->shininess = [DEF_SHININESS floatValue];
    uniform->strength = [DEF_STRENGTH floatValue];
}

// Compose transform matrixes( modelScale and scenePerspective ) to display the scene
// within the largest square that fits in the screen viewport.
// Also, compose transform matrixes( hitScale and pickPerspective ) to render the scene
// in a PICK_TEXTURE_SIZE x PICK_TEXTURE_SIZE square in the off screen texture.
// pickScaleFactor gives the conversion factor needed to go from screen coordinates to
// pick texture coordinates.

- (void)drawableSizeWillChange:(CGSize)size
{
    float   aspect,
            factor = 6.33 * SCENE_SCALE;
    
    if(uniformBuffer != nil)  // Ignore calls until this class is initialized
    {
        viewportSize = size;
        aspect = size.width / size.height;
        
        hitScale = matrix4x4_scale( factor, factor, factor );
        
        //the perspective transform scales to the height.  For tall narrow drawables
        //the figure is scaled down so it's not clipped on the right and the left.
        
        if( aspect > 1.0 )
        {
            pickScaleFactor = PICK_TEXTURE_SIZE / size.height;
            modelScale = matrix4x4_scale( factor, factor, factor );
        }
        else
        {
            pickScaleFactor = PICK_TEXTURE_SIZE / size.width;
            modelScale = matrix4x4_scale( factor * aspect, factor * aspect, factor * aspect );
        }
        
        /// Constructs a symmetric perspective Projection Matrix
        /// from left-handed Eye Coordinates to left-handed Clip Coordinates,
        /// with a vertical viewing angle of fovyRadians, the specified aspect ratio,
        /// and the provided absolute near and far Z distances from the eye.
        //
        //matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_perspective_left_hand(float fovyRadians, float aspect, float nearZ, float farZ);
        
        scenePerspective = matrix_perspective_left_hand(0.49, aspect, 20.0 , 200.0 );
        
        pickPerspective = matrix_perspective_left_hand(0.49, 1.0 , 20.0 , 200.0 );
        
        partialRotation = matrix4x4_identity();
    }
}

-(void)drawScene: (id<MTLRenderCommandEncoder>)renderEncoder
{
    NSUInteger       n;
    
    uniform->perspectiveTransform = scenePerspective;
    
    for( n = 0 ; n < 5 ; n++ )
    {
        uniform->orientationTransform[n] = simd_mul(nodeRotation[n] , nodeOrientation[n]);
        
        uniform->modelTransform[n] = simd_mul(nodeRotation[n] , modelTranslation);
        uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , modelScale );
        uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , nodeTransform[n] );
        uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , nodeOrientation[n] );
    }
    
    [renderEncoder setVertexBuffer: uniformBuffer
                            offset: 0
                           atIndex: HT_Uniform_Index];
    
    [renderEncoder setFragmentBuffer: uniformBuffer
                              offset: 0
                             atIndex: HT_Uniform_Index];
    
    for( n = 0 ; n < 5 ; n++ )
    {
        if(selection == n )
            [renderEncoder setFragmentTexture: [theTextures textureNamed: @"Brass"]
                                      atIndex: HT_Texture_Index];
        else
            [renderEncoder setFragmentTexture: [theTextures textureNamed: @"Marble"]
                                      atIndex: HT_Texture_Index];
        
        [renderEncoder setVertexBuffer: vertexBuffer[n]
                                offset: 0
                               atIndex: HT_Vertex_Index];
        
        
        [renderEncoder drawPrimitives: MTLPrimitiveTypeTriangle
                          vertexStart: 0
                          vertexCount: vertexCount[n]];
    }
}

-(void)hitTest:(NSPoint)clickPoint
  commandQueue: (id<MTLCommandQueue>)queue
{
    NSUInteger  n;
    uint8       hit[4];
    
    @autoreleasepool
    {
        id<MTLCommandBuffer> commandBuffer = [queue commandBuffer];
        
        [commandBuffer enqueue];
        
        commandBuffer.label = @"PickCommandBuffer";
        
        if( pickRenderPassDescriptor != nil )
        {
            
            id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor: pickRenderPassDescriptor];
            
            renderEncoder.label = @"PickRenderEncoder";
            [renderEncoder setCullMode: MTLCullModeBack];
            
            // Set the region of the drawable to which we'll draw.
            [renderEncoder setViewport:(MTLViewport){0.0, 0.0, PICK_TEXTURE_SIZE, PICK_TEXTURE_SIZE, 0.0, 1.0 }];
            
            [renderEncoder setRenderPipelineState: pickPipelineState];
            
            [renderEncoder setDepthStencilState: depthState];
            
            uniform->perspectiveTransform = pickPerspective;
            for( n = 0 ; n < 5 ; n++ )
            {
                uniform->orientationTransform[n] = simd_mul(nodeRotation[n] , nodeOrientation[n]);
                
                uniform->modelTransform[n] = simd_mul(nodeRotation[n] , modelTranslation);
                uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , hitScale );
                uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , nodeTransform[n] );
                uniform->modelTransform[n] = simd_mul(uniform->modelTransform[n] , nodeOrientation[n] );
            }
                        
            [renderEncoder setVertexBuffer: uniformBuffer
                                    offset: 0
                                   atIndex: HT_Uniform_Index];
            
            [renderEncoder setFragmentBuffer: uniformBuffer
                                      offset: 0
                                     atIndex: HT_Uniform_Index];
            
            for( n = 0 ; n < 5 ; n++ )
            {
                
                [renderEncoder setVertexBuffer: vertexBuffer[n]
                                        offset: 0
                                       atIndex: HT_Vertex_Index];
                
                
                [renderEncoder drawPrimitives: MTLPrimitiveTypeTriangle
                                  vertexStart: 0
                                  vertexCount: vertexCount[n]];
            }
            
            [renderEncoder endEncoding];
            
            id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
            
            [blitEncoder synchronizeResource: pickTexture];
            
            [blitEncoder endEncoding];
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            
            // The center point of the screen viewport maps onto
            // the center point of the off-screen viewport
            
            // Transpose from top-left origin to center origin
            clickPoint.x -= viewportSize.width / 2.0;
            clickPoint.y = (viewportSize.height / 2.0) - clickPoint.y;
            
            // Transpose from view coordinates to texture coordinates
            clickPoint.x *= pickScaleFactor;
            clickPoint.y *= pickScaleFactor;
            
            // Transpose from center origin to top-left origin
            clickPoint.x = (PICK_TEXTURE_SIZE / 2.0) + clickPoint.x;
            clickPoint.y = (PICK_TEXTURE_SIZE / 2.0) - clickPoint.y;
            
            // filter points outside of the texture view
            if( clickPoint.x >= PICK_TEXTURE_SIZE)
                clickPoint.x = PICK_TEXTURE_SIZE - 1;
            if( clickPoint.x <= 0)
                clickPoint.x = 1;
            if( clickPoint.y >= PICK_TEXTURE_SIZE)
                clickPoint.y = PICK_TEXTURE_SIZE - 1;
            if( clickPoint.y <= 0 )
                clickPoint.y = 1;
            
            [pickTexture getBytes: hit
                      bytesPerRow: PICK_TEXTURE_SIZE * sizeof(uint8 [4])
                       fromRegion: MTLRegionMake2D( clickPoint.x ,  clickPoint.y , 1, 1)
                      mipmapLevel: 0];
            
            selection = hit[0];
            
            NSString *comment;
            
            switch( hit[0] )
            {
                case 0:
                    comment = [NSString stringWithFormat: @"\nObject: Tetrahedron\nFacet: %d\n", hit[1]];
                    break;
                    
                case 1:
                    comment = [NSString stringWithFormat: @"\nObject: Octahedron\nFacet: %d\n", hit[1]];
                    break;
            
                case 2:
                    comment = [NSString stringWithFormat: @"\nObject: Icosahedron\nFacet: %d\n", hit[1]];
                    break;
            
                case 3:
                    comment = [NSString stringWithFormat: @"\nObject: Dodecahedron\nFacet: %d\n", hit[1]];
                    break;
            
                case 4:
                    comment = [NSString stringWithFormat: @"\nObject: Cube\nFacet: %d\n", hit[1]];
                    break;
                    
                default:
                    selection = -1;
                    comment = @"\nNothing Hit\n\n";
            }
            
            [self report: comment];
        }
    }
    
}

-(void)initAxes
{
    NSInteger   n;
    vector_float3   a[26] =
    {
        // C4 axes
        { 1.0, 0.0, 0.0},
        {-1.0, 0.0, 0.0},
        { 0.0, 1.0, 0.0},
        { 0.0,-1.0, 0.0},
        { 0.0, 0.0, 1.0},
        { 0.0, 0.0,-1.0},
        //C2d axes
        { ROOT2, ROOT2,   0.0},
        {-ROOT2,-ROOT2,   0.0},
        {-ROOT2, ROOT2,   0.0},
        { ROOT2,-ROOT2,   0.0},
        {   0.0, ROOT2,-ROOT2},
        {   0.0,-ROOT2, ROOT2},
        {   0.0, ROOT2, ROOT2},
        {   0.0,-ROOT2,-ROOT2},
        { ROOT2,   0.0, ROOT2},
        {-ROOT2,   0.0,-ROOT2},
        {-ROOT2,   0.0, ROOT2},
        { ROOT2,   0.0,-ROOT2},
        //C3 axes
        { ROOT3, ROOT3, ROOT3},
        {-ROOT3,-ROOT3,-ROOT3},
        { ROOT3, ROOT3,-ROOT3},
        {-ROOT3,-ROOT3, ROOT3},
        {-ROOT3, ROOT3, ROOT3},
        { ROOT3,-ROOT3,-ROOT3},
        {-ROOT3, ROOT3,-ROOT3},
        { ROOT3,-ROOT3, ROOT3}
    };
    
    for(n=0;n<26;n++)
        axis[n] = a[n];
}

-(void)initOffScreenView
{
    MTLTextureDescriptor        *texDescriptor;
    NSError                     *error;
    id<MTLTexture>              depthTexture;
    
    //Create the render target texture
    texDescriptor = [MTLTextureDescriptor new];
    texDescriptor.textureType = MTLTextureType2D;
    texDescriptor.width = PICK_TEXTURE_SIZE;
    texDescriptor.height = PICK_TEXTURE_SIZE;
    texDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;  //i.e. (uint8 [4])
    texDescriptor.storageMode = MTLStorageModeManaged;
    texDescriptor.usage = MTLTextureUsageRenderTarget;
    
    pickTexture = [device newTextureWithDescriptor: texDescriptor];
    
    //Create the depth texture
    texDescriptor.textureType = MTLTextureType2D;
    texDescriptor.width = PICK_TEXTURE_SIZE;
    texDescriptor.height = PICK_TEXTURE_SIZE;
    texDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    texDescriptor.storageMode = MTLStorageModePrivate;
    texDescriptor.usage = MTLTextureUsageRenderTarget;
    
    depthTexture = [device newTextureWithDescriptor: texDescriptor];
    
    pickRenderPassDescriptor = [MTLRenderPassDescriptor new];
    
    pickRenderPassDescriptor.colorAttachments[0].texture = pickTexture;
    pickRenderPassDescriptor.depthAttachment.texture = depthTexture;
    pickRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    pickRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake( 1.0 , 1.0 , 1.0 , 1.0);
    pickRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    MTLDepthStencilDescriptor *depthStencilDesc = [[MTLDepthStencilDescriptor alloc] init];
    
    depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDesc.depthWriteEnabled = YES;
    depthState = [device newDepthStencilStateWithDescriptor:depthStencilDesc];
    
    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];
    
    // Load the vertex function from the library
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"pickVertexShader"];
    
    // Load the fragment function from the library
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"pickFragmentShader"];
    
    // Configure a pipeline descriptor that is used to create a pipeline state
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
    
    pipelineStateDescriptor.label                           = @"Pick Pipeline";
    pipelineStateDescriptor.vertexFunction                  = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = pickTexture.pixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatDepth32Float;
    
    pickPipelineState = [device newRenderPipelineStateWithDescriptor: pipelineStateDescriptor
                                                               error: &error];
    if (!pickPipelineState)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

// Return a crytographically secure random number
-(uint64)random64
{
    uint64_t    value = 0;
    int         i;
    
   for (i = 0 ; i < sizeof(value); i++)
    {
        value <<= 8;
        value |= fgetc(randomDevice);
    }
    
    return value;
}

// Relay text to StrawBoss

- (void)report: (nonnull NSString *)text
{
    NSDictionary    *userInfo;
    
    userInfo = [NSDictionary dictionaryWithObject: text
                                           forKey: REPORT ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: REPORT
                                                        object: self
                                                      userInfo: userInfo];
}
@end
