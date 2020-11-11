//
//  TupleFormatter.m
//  Play_Tonic
//
//  Created by Bruce D MacKenzie on 9/27/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "TupleFormatter.h"

@implementation TupleFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    float       a,b,c;
    NSString    *result;
    
    result = @"0.0, 0.0, 0.0";
    
    if([obj isKindOfClass: [NSArray class]])
    {
        if( [obj count] == 3)
        {
            a = [[obj objectAtIndex: 0] floatValue];
            b = [[obj objectAtIndex: 1] floatValue];
            c = [[obj objectAtIndex: 2] floatValue];
            
            result = [NSString stringWithFormat: @"%0.3f, %0.3f, %0.3f",a,b,c];
        }
    }
    
    return  result;
}

- (BOOL)getObjectValue:(out id  _Nullable *)obj
             forString:(NSString *)string
      errorDescription:(out NSString * _Nullable *)error
{
    NSArray     *substrings;
    
    substrings = [string componentsSeparatedByString: @","];
    
    if( [substrings count] != 3 )
    {
        return NO;
    }
    
    *obj = substrings;
    
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString * _Nullable *)newString
            errorDescription:(NSString * _Nullable *)error
{
    return YES;
}

@end
