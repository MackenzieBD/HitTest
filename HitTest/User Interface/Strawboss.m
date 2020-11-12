//
//  Strawboss.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/21/20.
//

#import "Strawboss.h"
#import "HT_AppDefs.h"
#import "Lighting.h"

#define SB_LIGHTING @"SB Lighting"

@interface Strawboss ()

@property (strong)  IBOutlet NSWindow       *window;
@property (weak)    IBOutlet NSTextView     *logView;
@property (weak)    IBOutlet NSToolbar      *theToolbar;
@property (weak)    IBOutlet NSButton       *lightingButton;
@property (weak)    IBOutlet Lighting      *lightingPanel;
@end

@implementation Strawboss
{
    NSLock          *queueLock;
    NSMutableArray  *reportQueue;
    NSToolbarItem   *lightingToolbarItem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set up thread safe output to the log view
    
    queueLock = [[NSLock alloc] init];
    reportQueue = [[NSMutableArray alloc] init];
    
    
    [NSTimer scheduledTimerWithTimeInterval: 0.1
                                     target: self
                                   selector: @selector(honeyDo:)
                                   userInfo: nil
                                    repeats: YES ];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(processReport:)
                                                 name: REPORT
                                               object:  nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(lightingReport:)
                                                 name: REPORT_LIGHTING
                                               object:  nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (void)honeyDo: (NSTimer *)timer
{
    NSString            *comment;
    NSMutableString     *logViewText;
    
    // Output any outstanding comments to the log view
    
    while( (comment = [self nextComment]) != nil )
    {
        logViewText = [[[self logView] textStorage] mutableString];
        [logViewText appendString: comment ];
        
        if( [logViewText length] > 1 )
            [[self logView] scrollRangeToVisible: NSMakeRange( [logViewText length] - 1 , 1 ) ];
    }
}

-(void)lightingReport: (NSNotification *)note;
{
    [queueLock lock];
    [reportQueue addObject: [[self lightingPanel] description]];
    [queueLock unlock];
}

- (NSString *)nextComment
{
    NSString    *newComment = nil;
    
    [queueLock lock];
    if( [reportQueue count] > 0)
    {
        newComment = [reportQueue objectAtIndex: 0];
        [reportQueue removeObjectAtIndex: 0];
    }
    [queueLock unlock];
    
    return newComment;
}

// Queue text items for handling on the main thread

-(void)processReport: (NSNotification *)note
{
    NSString    *text;
    
    text = [[note userInfo] objectForKey: REPORT ];
    
    if( text != nil )
    {
        [queueLock lock];
        [reportQueue addObject: text];
        [queueLock unlock];
    }
}

-(IBAction)showLightingPanel:(id)sender
{
    [[self lightingPanel] showLightingPanel];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
            
    if( [itemIdentifier isEqualToString: SB_LIGHTING] )
        return [self toolbarItemLighting];
    
    return nil;
}
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            SB_LIGHTING,
            nil];
}

- (NSToolbarItem *)toolbarItemLighting
{
    if( lightingToolbarItem == nil)
    {
        lightingToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: SB_LIGHTING];
        [lightingToolbarItem setLabel: @"Lighting"];
        [lightingToolbarItem setPaletteLabel: @"Lighting"];
        [lightingToolbarItem setToolTip: @"Show Lighting Panel"];
        [lightingToolbarItem setTarget: self];
        [lightingToolbarItem setAction: @selector( showLightingPanel: ) ];
        [lightingToolbarItem setView: [self lightingButton]];
    }
    
    return [lightingToolbarItem copy];
}

-(id)toolbarViewForIdentifier: (NSString *)ident
{
    NSArray         *items;
    NSToolbarItem   *item;
    
    items = [[self theToolbar] visibleItems];
    
    for( item in items)
    {
        if( [[item itemIdentifier] isEqualToString: ident] )
        {
            return [item view];
        }
    }
    return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarAllowedItemIdentifiers: toolbar];
}


@end
