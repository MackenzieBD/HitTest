//
//  MetalView.m
//  Play_Tonic
//
//  Created by Bruce D MacKenzie on 9/20/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "MetalView.h"
#import "HT_Renderer.h"

@implementation MetalView

-(BOOL)acceptsFirstResponder
{
    return NO;
}

-(BOOL)canBecomeKeyView
{
    return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    return [(HT_Renderer *)[self delegate] performKeyEquivalent: event];
}

@end
