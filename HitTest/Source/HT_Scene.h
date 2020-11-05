//
//  HT_Scene.h
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/22/20.
//

#import <Foundation/Foundation.h>

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface HT_Scene : NSObject

-(instancetype)initWithDevice: (id<MTLDevice>)d;

- (void)drawableSizeWillChange:(CGSize)size;

-(void)drawScene: (id<MTLRenderCommandEncoder>)renderEncoder;

-(void)hitTest: (NSPoint)clipPoint
  commandQueue: (id<MTLCommandQueue>)queue;


@end

NS_ASSUME_NONNULL_END
