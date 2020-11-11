//
//  HT_Renderer.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/21/20.
//

#import "HT_Renderer.h"

#import "AAPLMathUtilities.h"

#import "HT_AppDefs.h"
#import "HT_Scene.h"
#import "HT_Types.h"
#import "HT_Textures.h"


@interface HT_Renderer ()

@end

@implementation HT_Renderer
{
    HT_Scene                    *theScene;
    MTKView                     *metalView;
    id<MTLDevice>               ht_device;
    
    
    id <MTLSamplerState>        sampler;
    id<MTLRenderPipelineState>  ht_pipelineState;
    id<MTLCommandQueue>         ht_commandQueue;
    id<MTLDepthStencilState>    ht_depthState;
    
    CGSize                      viewportSize;
    NSLock                      *lock;
}


- (void)drawInMTKView:(MTKView *)view
{
    @autoreleasepool
    {
        [lock lock];
        id<MTLCommandBuffer> commandBuffer = [ht_commandQueue commandBuffer];
        commandBuffer.label = @"ViewCommandBuffer";
        
        MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        
        if( renderPassDescriptor != nil )
        {
            
            id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            
            renderEncoder.label = @"ViewRenderEncoder";
            [renderEncoder setCullMode: MTLCullModeBack];
            
            // Set the region of the drawable to which we'll draw.
            [renderEncoder setViewport:(MTLViewport){0.0, 0.0, viewportSize.width, viewportSize.height, 0.0, 1.0 }];
            
            [renderEncoder setRenderPipelineState: ht_pipelineState];
            
            [renderEncoder setFragmentSamplerState: sampler atIndex: HT_Texture_Index];
            
            [renderEncoder setDepthStencilState: ht_depthState];
            
            [theScene drawScene: renderEncoder];            
            
            [renderEncoder endEncoding];
            
            // Schedule a present once the framebuffer is complete using the current drawable
            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
        }
        [lock unlock];
    }
}

-(void)initDepthAndStencilState
{
    metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLDepthStencilDescriptor *depthStencilDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDesc.depthWriteEnabled = YES;
    ht_depthState = [ht_device newDepthStencilStateWithDescriptor:depthStencilDesc];
}



-(void)initThePipelineState
{
    NSError     *error = NULL;
    
    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [ht_device newDefaultLibrary];
    
    // Load the vertex function from the library
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexTexShader"];
    
    // Load the fragment function from the library
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentTexShader"];
    
    // Configure a pipeline descriptor that is used to create a pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    pipelineStateDescriptor.label                               = @"Textured Pipeline";
    pipelineStateDescriptor.vertexFunction                      = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                    = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat     = metalView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat          = MTLPixelFormatDepth32Float;
    
    ht_pipelineState = [ht_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
    if (!ht_pipelineState)
    {
        // Pipeline State creation could fail if we haven't properly set up our pipeline descriptor.
        //  If the Metal API validation is enabled, we can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode)
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

-(void)initSamplers
{
    // create MTLSamplerDescriptor

    MTLSamplerDescriptor *desc = [[MTLSamplerDescriptor alloc] init];

    desc.minFilter = MTLSamplerMinMagFilterLinear;

    desc.magFilter = MTLSamplerMinMagFilterLinear;

    desc.sAddressMode = MTLSamplerAddressModeMirrorRepeat;

    desc.tAddressMode = MTLSamplerAddressModeRepeat;

    //  all properties below have default values

    desc.mipFilter        = MTLSamplerMipFilterNotMipmapped;

    desc.maxAnisotropy    = 1U;

    desc.normalizedCoordinates = YES;

    desc.lodMinClamp      = 0.0f;

    desc.lodMaxClamp      = FLT_MAX;

    // create MTLSamplerState

    sampler = [ht_device newSamplerStateWithDescriptor:desc];
}

-(void)mouseDown:(NSEvent *)event
{
    NSPoint hitPoint;
    
    hitPoint = event.locationInWindow;
    hitPoint = [[self view] convertPoint: hitPoint fromView: nil];
    hitPoint.y = [[self view] bounds].size.height -  hitPoint.y;
    
    [self report: [NSString stringWithFormat: @"\nHit x: %d\ty: %d", (int)hitPoint.x , (int)hitPoint.y]];
    
    [lock lock];
    [theScene hitTest: hitPoint
         commandQueue: ht_commandQueue];
    [lock unlock];
    
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    viewportSize = size;
    [theScene drawableSizeWillChange: size];
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

- (void)viewDidLoad
{
    MTLClearColor   clearColor = {0.3 , 0.4 , 0.9 , 1.0};
    
    [super viewDidLoad];
    
    lock = [[NSLock alloc] init];
    
    metalView = (MTKView *)[self view];
    metalView.delegate = self;
    
    metalView.device = MTLCreateSystemDefaultDevice();
    ht_device = metalView.device;
    
    
    metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    metalView.clearColor = clearColor;
    
    [self initSamplers];
    
    [self initDepthAndStencilState];
    
    [self initThePipelineState];
    
    ht_commandQueue = [ht_device newCommandQueue];
    
    theScene = [[HT_Scene alloc] initWithDevice: ht_device];
    
    [self mtkView: metalView drawableSizeWillChange:[metalView drawableSize]];
}

@end
