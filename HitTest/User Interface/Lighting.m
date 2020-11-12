//
//  Lighting.m
//  Play_Tonic
//
//  Created by Bruce D MacKenzie on 9/27/19.
//  Copyright © 2019 Bruce MacKenzie. All rights reserved.
//

#import "Lighting.h"
#import "LightDefs.h"
#import "HT_AppDefs.h"


@interface Lighting ()

@property (weak) IBOutlet NSWindow *mainWindow;
@property (weak) IBOutlet NSTextField *ambient;
@property (weak) IBOutlet NSTextField *position;
@property (weak) IBOutlet NSTextField *color;
@property (weak) IBOutlet NSTextField *atten0;
@property (weak) IBOutlet NSTextField *atten1;
@property (weak) IBOutlet NSTextField *atten2;
@property (weak) IBOutlet NSTextField *shine;
@property (weak) IBOutlet NSTextField *strength;
@property (weak) IBOutlet NSNumberFormatter *numFormatter;


@end

@implementation Lighting
{
    NSDictionary *revertParameters;
}

-(IBAction)apply: (id)sender
{
    NSDictionary    *result,
                    *info;
    
    result = [self currentValues];
    
    info = [NSDictionary dictionaryWithObject: result forKey: LIGHTING ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: LIGHTING
                                                        object: self
                                                      userInfo: info];
}

-(NSDictionary *)currentValues
{
    NSDictionary    *result;
    
    result = [NSDictionary dictionaryWithObjectsAndKeys:
            [[self ambient] objectValue],   LT_AMBIENT,
            [[self position] objectValue],  LT_POSITION,
            [[self color] objectValue],     LT_LAMP_COLOR,
            [[self atten0] objectValue] ,   LT_ATTEN0,
            [[self atten1] objectValue] ,   LT_ATTEN1,
            [[self atten2] objectValue] ,   LT_ATTEN2,
            [[self shine] objectValue] ,    LT_SHININESS,
            [[self strength] objectValue],  LT_STRENGTH,
            nil];
    
    return result;
}

-(IBAction)ok:(id)sender
{
    [self apply: nil];
    
    [[self mainWindow] endSheet: [[self view] window] ];
    
}

-(IBAction)validateTuple:(id)sender
{
    id  objValue;
    
    objValue = [sender objectValue];
    [sender setObjectValue: objValue];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self numFormatter] setUsesSignificantDigits: YES];
    [[self numFormatter] setMinimumFractionDigits: 4];
    
    [self setToDefaults: self];
}

-(IBAction)revert:(id)sender
{
    [self setDialogFields: revertParameters];
    [self apply: self];
}

-(void)showLightingPanel
{
    revertParameters = [self currentValues];
    
    [[self mainWindow] beginSheet: [[self view] window]
                completionHandler: ^(NSModalResponse returnCode) {}];
}

-(void)setDialogFields: (NSDictionary *)values
{
     [[self ambient] setObjectValue:    [values objectForKey: LT_AMBIENT]];
     [[self position] setObjectValue:   [values objectForKey: LT_POSITION]];
     [[self color] setObjectValue:      [values objectForKey: LT_LAMP_COLOR]];
     [[self atten0] setObjectValue:     [values objectForKey: LT_ATTEN0]];
     [[self atten1] setObjectValue:     [values objectForKey: LT_ATTEN1]];
     [[self atten2] setObjectValue:     [values objectForKey: LT_ATTEN2]];
     [[self shine] setObjectValue:      [values objectForKey: LT_SHININESS]];
     [[self strength] setObjectValue:   [values objectForKey: LT_STRENGTH]];
}

// Set the dialog fields to default values defined in LightDefs.h

-(IBAction)setToDefaults:(id)sender
{
    NSDictionary    *result;
    
    result = [NSDictionary dictionaryWithObjectsAndKeys:
            [DEF_AMBIENT componentsSeparatedByString: @","],        LT_AMBIENT,
            [DEF_POSITION componentsSeparatedByString: @","],       LT_POSITION,
            [DEF_LAMP_COLOR componentsSeparatedByString: @","],     LT_LAMP_COLOR,
            [NSNumber numberWithFloat:[DEF_ATTEN0 floatValue]],     LT_ATTEN0,
            [NSNumber numberWithFloat:[DEF_ATTEN1 floatValue]],     LT_ATTEN1,
            [NSNumber numberWithFloat:[DEF_ATTEN2 floatValue]],     LT_ATTEN2,
            [NSNumber numberWithFloat:[DEF_SHININESS floatValue]],  LT_SHININESS,
            [NSNumber numberWithFloat:[DEF_STRENGTH floatValue]],   LT_STRENGTH,
            nil];
    
    [self setDialogFields: result];
    
}

-(NSString *)description
{
    NSDictionary    *fields;
    NSMutableString *result;
    
    result = [NSMutableString stringWithString: @"\nLighting Report\n\n"];
    fields = [self currentValues];
    
    [result appendFormat: @"      Ambient(r,g,b) \t%@\n", [[self ambient] stringValue]];
    [result appendFormat: @"Lamp Position(x,y,z) \t%@\n", [[self position] stringValue]];
    [result appendFormat: @"   Lamp Color(r,g,b) \t%@\n", [[self color] stringValue]];
    [result appendFormat: @"       Attenuation_0 \t%@\n", [fields objectForKey: LT_ATTEN0]];
    [result appendFormat: @"       Attenuation_1 \t%@\n", [fields objectForKey: LT_ATTEN1]];
    [result appendFormat: @"       Attenuation_2 \t%@\n", [fields objectForKey: LT_ATTEN2]];
    [result appendFormat: @"           Shininess \t%@\n", [fields objectForKey: LT_SHININESS]];
    [result appendFormat: @"            Strength \t%@\n", [fields objectForKey: LT_STRENGTH]];
    
    
    return result;
}

@end
