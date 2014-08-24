//
//  ViewController.m
//  SomethingsFishy
//
//  Created by Zac Bowling on 8/23/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "ViewController.h"
#import "ColorTrackingGLView.h"
#import "ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"

@interface ViewController () <ColorTrackingObserver> {
    ColorTrackingGLView *fishView;
    UIImage *seabed;
    CALayer *fishLayer;
    CADisplayLink *displayLink;
    UIImageView *soccerballView;
    
    ChipmunkSpace *_space;
    
    ChipmunkCircleShape *_ballShape;
    ChipmunkBody *_ballBody;
    
    ChipmunkCircleShape *_fishShape;
    ChipmunkBody *_fishBody;
    
    CGPoint _lastFishPosition;
    CGPoint _currentFirstPosition;
    CGFloat _currentSpeed;
}

@end

static NSString *borderType = @"borderType";

static NSString *actorType = @"ballType";

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self play];

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
    cpFloat dt = displayLink.duration*displayLink.frameInterval;
    
    _fishBody.velocity = cpvmult(cpvsub(cpv(_currentFirstPosition.x, _currentFirstPosition.y), _fishBody.position), 1.0f/dt);
    [_space step:dt];
    soccerballView.center = CGPointMake(_ballBody.position.x, _ballBody.position.y);
    _lastFishPosition = _currentFirstPosition;

    //[_fishBody applyForce:cpv(1,1) atWorldPoint:cpv(_currentFirstPosition.x, _currentFirstPosition.y)];

    [_space reindexShape:_fishShape];
    
    NSLog(@"f %f %f", _fishBody.position.x, _fishBody.position.y);
    NSLog(@"b %f %f", _ballBody.position.x, _ballBody.position.y);
    
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
    
    [fishView addTrackingObserver:self];
    [[self view] addSubview:fishView];
    
    
    soccerballView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"soccerball"]];
    
    soccerballView.frame = CGRectMake(200, 200, 100, 100);
    [[self view] addSubview:soccerballView];
    
    _space = [[ChipmunkHastySpace alloc] init];
    _space.damping = 0.7;
    [_space addBounds:cpBBNew(screen.origin.x, screen.origin.y+margin, screen.size.width, screen.size.height-margin) thickness:2000.0f elasticity:1.0f friction:1.0f filter:CP_SHAPE_FILTER_ALL collisionType:borderType];
    
    cpFloat moment = cpMomentForCircle(1.0f, 0, 50, cpvzero);
    
    _ballBody = [ChipmunkBody bodyWithMass:1.0f andMoment:moment];
    _ballBody.position = cpv(200, 200);
    
    _ballShape = [[ChipmunkCircleShape alloc] initWithBody:_ballBody radius:50 offset:cpvzero];
    _ballShape.friction = 0.2f;
    _ballShape.elasticity = 1.0f;
    _ballShape.userData = soccerballView;
    
    _fishBody = [[ChipmunkBody alloc] initWithMass:1.0f andMoment:moment];
    //_fishBody.type = CP_BODY_TYPE_STATIC;
    
    _fishShape = [[ChipmunkCircleShape alloc] initWithBody:_fishBody radius:50 offset:cpvzero];
    _fishShape.elasticity = 0.0f;
    _fishShape.friction = 1.0f;

    
    [_space add:_ballShape];
    [_space add:_ballBody];
    [_space add:_fishShape];
    [_space add:_fishBody];

    
    //_space.gravity = cpvmult(cpv(0, 1), 300.0f);
    
}

-(void)trackingPositionChanged:(CGPoint)point {
    _currentFirstPosition = CGPointMake(point.x * fishView.bounds.size.width, (point.y * fishView.bounds.size.height) + fishView.frame.origin.y);
    
    _currentSpeed = hypotf(_lastFishPosition.x - _currentFirstPosition.x, _lastFishPosition.y - _currentFirstPosition.y);
    
}


@end
