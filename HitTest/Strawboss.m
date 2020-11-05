//
//  Strawboss.m
//  HitTest
//
//  Created by Bruce D MacKenzie on 10/21/20.
//

#import "Strawboss.h"
#import "HT_AppDefs.h"

@interface Strawboss ()

@property (strong)  IBOutlet NSWindow   *window;
@property (weak)    IBOutlet NSTextView *logView;
@end

@implementation Strawboss
{
    NSLock          *queueLock;
    NSMutableArray  *reportQueue;
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

@end
