//
//  HT_Textures.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/24/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "HT_Textures.h"

@implementation HT_Textures
{
    NSDictionary    *textureDictionary;
    NSArray         *textureNames;
}

- (instancetype)initWithMTLDevice: (id<MTLDevice>)mtlDevice
{
    NSString            *name;
    NSMutableDictionary *textDict;
    NSMutableArray      *imageNames;
    NSURL               *item;
    NSMutableArray      *paths;
    id<MTLTexture>      mtlTexture;
    MTKTextureLoader    *textureLoader;
    NSError             *error;
    
    self = [super init];
    
    if( self != nil)
    {
        textureLoader = [[MTKTextureLoader alloc] initWithDevice: mtlDevice];
        
        imageNames = [NSMutableArray array];
        textDict = [NSMutableDictionary dictionary];
        
        paths = [NSMutableArray arrayWithArray: [[NSBundle mainBundle ] URLsForResourcesWithExtension: @"tif"
                                                                                        subdirectory: nil]];
        
        [paths addObjectsFromArray: [[NSBundle mainBundle ] URLsForResourcesWithExtension: @"jpg"
                                                                             subdirectory: nil]];
        
        for( item in paths )
        {
            name = [item lastPathComponent];
            name = [name substringToIndex: [name rangeOfString: @"."].location];
            
            mtlTexture = [textureLoader newTextureWithContentsOfURL: item
                                                            options: nil
                                                              error: &error];
            
            if( error == nil)
            {
                [imageNames addObject: name];
                [textDict setObject: mtlTexture forKey: name];
            }
            else
                NSLog( @"Failed to Load: %@", name );
            
        }
        
        textureNames = [imageNames sortedArrayUsingSelector: @selector( compare:)];
        textureDictionary = [NSDictionary dictionaryWithDictionary: textDict];
    }
    
    return self;
}

-(NSArray *)textureNames
{
    return textureNames;
}

-(id<MTLTexture>)textureNamed: (NSString *)name
{
    return [textureDictionary objectForKey: name];
}

@end
