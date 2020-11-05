//
//  HT_Textures.h
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/24/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import <MetalKit/MetalKit.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HT_Textures : NSObject


- (instancetype)initWithMTLDevice: (id<MTLDevice>)mtlDevice;

-(NSArray *)textureNames;

-(id<MTLTexture>)textureNamed: (NSString *)name;

@end

NS_ASSUME_NONNULL_END
