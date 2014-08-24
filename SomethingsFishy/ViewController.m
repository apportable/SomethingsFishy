//
//  ViewController.m
//  SomethingsFishy
//
//  Created by Zac Bowling on 8/23/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "ViewController.h"
#import "ColorTrackingGLView.h"

@interface ViewController () {
    ColorTrackingGLView *fishView;
    UIImage *seabed;
    CALayer *fishLayer;
    MCParallaxLayer *seabedLayer;
    CADisplayLink *displayLink;
}

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self play];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    CGFloat height = screen.size.height;
    CGFloat width = screen.size.width;
    height = (720.0f/1280.0f)*width;
    
    CGFloat margin = (screen.size.height - height)/2;

    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    seabed = [UIImage imageNamed:@"Sea-Bed"];
    self.view.opaque = NO;
    
    fishLayer = fishView.layer;
    fishLayer.contentsRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    
    seabedLayer = [[MCParallaxLayer alloc] initWithBounds:CGRectMake(0, 0, screen.size.width, seabed.size.height/self.view.contentScaleFactor)
                                                 tileSize:CGSizeMake(seabed.size.width/self.view.contentScaleFactor, seabed.size.height/self.view.contentScaleFactor)
                                                 provider:self
                                             isHorizontal:YES
                                                   opaque:NO
                                                      tag:1];
    seabedLayer.position = CGPointMake(0, (screen.size.height-seabed.size.height/self.view.contentScaleFactor));
    seabedLayer.scrollMultiplier = 1.5f;
    [fishLayer addSublayer:seabedLayer];
    
    [CATransaction commit];

}

- (void)play;
{
    // CADisplayLink updates
    if (displayLink == nil)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
        [displayLink setFrameInterval:1];
    }
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


- (void)pause;
{
    [displayLink invalidate]; displayLink = nil;
}


#pragma mark -
#pragma mark Game Loop Update

- (void)update:(CADisplayLink*)sender;
{
    static const float floorSpeed = 90.0f; // pts/sec
    static const CFTimeInterval maxElapsedTime = 1 / 20.0f;
    static CFTimeInterval lastTimestamp = 0;
    
    const CFTimeInterval currentTime = CACurrentMediaTime();
    CFTimeInterval elapsedTime = currentTime - lastTimestamp;
    lastTimestamp = currentTime;
    
    if (elapsedTime > maxElapsedTime)
        elapsedTime = maxElapsedTime;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    const CGPoint diff = CGPointMake(floorSpeed*elapsedTime, 0);
    [seabedLayer scrollTiles:diff];
        
    [CATransaction commit];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    CGFloat height = screen.size.height;
    CGFloat width = screen.size.width;
    height = (720.0f/1280.0f)*width;
    
    CGFloat margin = (screen.size.height - height)/2;
    fishView = [[ColorTrackingGLView alloc] initWithFrame:CGRectMake(0,margin,width,height)];
    fishView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
//    UIImageView *seaBed = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sea-Bed"]];
    
//    [seaBed setFrame:CGRectMake(0, (screen.size.height-(margin+10)), screen.size.width, margin+10)];
    
    [[self view] addSubview:fishView];
//    [[self view] addSubview:seaBed];
    
//    UIView *seabedBackside = [seaBed copy];
//    [seabedBackside setFrame:CGRectMake(screen.size.width, (screen.size.height-(margin+10)), screen.size.width, margin+10)];
    
}

#pragma mark - ParallaxLayerProvider

- (CGImageRef)atlasFor:(MCParallaxLayer *)sender
{
    if (sender.tag == 1)
    {
        return seabed.CGImage;
    }
    return nil;
}

- (CGRect)tileAt:(TileCoords)pos for:(MCParallaxLayer *)sender
{
    return CGRectMake(0.0f, 0.0f, seabed.size.width/self.view.contentScaleFactor, seabed.size.height/self.view.contentScaleFactor);
}

@end
