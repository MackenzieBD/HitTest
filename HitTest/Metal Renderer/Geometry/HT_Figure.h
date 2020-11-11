//
//  HT_Figure.h
//  HitTest
//
//  Created by Bruce D MacKenzie on 9/13/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#ifndef HT_Figure_h
#define HT_Figure_h

@protocol HT_Figure <NSObject>

-(NSData *)vertexData;

-(instancetype)initAsNode: (NSUInteger) node;


@end

#endif /* HT_Figure_h */
