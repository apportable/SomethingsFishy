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
    UIImageView *netLeftView;
    UIImageView *netRightView;
    
    ChipmunkSpace *_space;
    
    ChipmunkCircleShape *_ballShape;
    ChipmunkBody *_ballBody;
    
    ChipmunkCircleShape *_fishShape;
    ChipmunkBody *_fishBody;
    
    ChipmunkPolyShape *_rightNetLeftPoleShape;
    ChipmunkBody *_rightNetLeftPoleBody;
    ChipmunkPolyShape *_rightNetRightPoleShape;
    ChipmunkBody *_rightNetRightPoleBody;
    
    ChipmunkPolyShape *_leftNetLeftPoleShape;
    ChipmunkBody *_leftNetLeftPoleBody;
    ChipmunkPolyShape *_leftNetRightPoleShape;
    ChipmunkBody *_leftNetRightPoleBody;
    
    ChipmunkPolyShape *_leftGoalLineShape;
    ChipmunkPolyShape *_rightGoalLineShape;
    ChipmunkBody *_leftGoalLineBody;
    ChipmunkBody *_rightGoalLineBody;
    
    CGPoint _lastFishPosition;
    CGPoint _currentFirstPosition;
    CGFloat _currentSpeed;
    
    NSUInteger _leftScore;
    NSUInteger _rightScore;
    
    UILabel *_leftScoreLabel;
    UILabel *_rightScoreLabel;
    
    float xVelocityOnGoal;
}

@end

static NSString *borderType = @"borderType";

static NSString *actorType = @"fishType";

static NSString *leftGoalLineType = @"leftGoalLineType";
static NSString *rightGoalLineType = @"rightGoalLineType";
static NSString *ballType = @"ballType";

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
    CGPoint ballPoint = CGPointMake(_ballBody.position.x, _ballBody.position.y);
    soccerballView.center = CGPointMake(_ballBody.position.x, _ballBody.position.y);
    _lastFishPosition = _currentFirstPosition;
    
    
    if (CGRectContainsPoint(netLeftView.frame,ballPoint)) {
        [self leftSideScored];
    } else if (CGRectContainsPoint(netRightView.frame,ballPoint)) {
        [self rightSideScored];
    }

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
    
    UIImage *netLeftImage = [UIImage imageNamed:@"Soccer_net_left"];
    UIImage *netRightImage = [UIImage imageNamed:@"Soccer_net_right"];
    
    soccerballView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"soccerball"]];
    netLeftView = [[UIImageView alloc] initWithImage:netLeftImage];
    netRightView = [[UIImageView alloc] initWithImage:netRightImage];
    
    soccerballView.frame = CGRectMake(screen.size.width/2, screen.size.height/2, 100, 100);
    netLeftView.frame = CGRectMake(0, screen.size.height/2 - 100, 100, 200);
    netRightView.frame = CGRectMake(screen.size.width - 100, screen.size.height/2 - 100, 100, 200);
    
    _rightScore = 0;
    _leftScore = 0;
    
    _leftScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    _leftScoreLabel.text = @"0";
    _leftScoreLabel.font = [UIFont fontWithName:@"Times" size:50.0f];
    _leftScoreLabel.textColor = [UIColor whiteColor];
    
    _rightScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(screen.size.width-100, 100, 100, 100)];
    _rightScoreLabel.text = @"0";
    _rightScoreLabel.font = [UIFont fontWithName:@"Times" size:50.0f];
    _rightScoreLabel.textColor = [UIColor whiteColor];

    
    [[self view] addSubview:_rightScoreLabel];
    [[self view] addSubview:_leftScoreLabel];
    
    
    [[self view] addSubview:soccerballView];
    [[self view] addSubview:netLeftView];
    [[self view] addSubview:netRightView];
    
    _space = [[ChipmunkHastySpace alloc] init];
    _space.damping = 0.7;
    [_space addBounds:cpBBNew(screen.origin.x, screen.origin.y+margin, screen.size.width, screen.size.height-margin) thickness:2000.0f elasticity:1.0f friction:1.0f filter:CP_SHAPE_FILTER_ALL collisionType:borderType];
    
    cpFloat ballMoment = cpMomentForCircle(1.0f, 0, 50, cpvzero);
    
    _ballBody = [ChipmunkBody bodyWithMass:1.0f andMoment:ballMoment];
    _ballBody.position = cpv(screen.size.width/2, screen.size.height/2);
    
    _ballShape = [[ChipmunkCircleShape alloc] initWithBody:_ballBody radius:50 offset:cpvzero];
    _ballShape.friction = 0.2f;
    _ballShape.elasticity = 1.0f;
    _ballShape.userData = soccerballView;
    
    _fishBody = [ChipmunkBody kinematicBody];
    //_fishBody.type = CP_BODY_TYPE_STATIC;
    
    _fishShape = [[ChipmunkCircleShape alloc] initWithBody:_fishBody radius:50 offset:cpvzero];
    _fishShape.elasticity = 0.0f;
    _fishShape.friction = 1.0f;

    
    //soccer nets
    /*_leftNetLeftPoleBody = [ChipmunkBody staticBody];
    _leftNetRightPoleBody = [ChipmunkBody staticBody];
    _rightNetLeftPoleBody = [ChipmunkBody staticBody];
    _rightNetRightPoleBody = [ChipmunkBody staticBody];
    
    cpFloat lineMoment = cpMomentForBox(0, 20, 260);
    //_leftGoalLineBody = [ChipmunkBody bodyWithMass:0.0f andMoment:lineMoment];
    //_rightGoalLineBody = [ChipmunkBody bodyWithMass:0.0f andMoment:lineMoment];
    
    _leftNetLeftPoleBody.position = cpv(0, screen.size.height/2.0f + 80.0f); // I am so sorry for these hardcoded values.
    _leftNetRightPoleBody.position = cpv(0, screen.size.height/2.0f - 100.0f);
    _rightNetLeftPoleBody.position = cpv(screen.size.width-100.0f, screen.size.height/2.0f + 100.0f);
    _rightNetRightPoleBody.position = cpv(screen.size.width-100.0f, screen.size.height/2.0f - 100.0f);

    _leftGoalLineBody.position = cpv(130.0f, screen.size.height/2.0f + 75.0f);
    _rightGoalLineBody.position = cpv(screen.size.width - 170, screen.size.height/2.0f + 75.0f);
    
    _leftNetLeftPoleShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_leftNetLeftPoleBody width:150 height:20 radius:0.0f];
    _leftNetRightPoleShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_leftNetRightPoleBody width:150 height:20 radius:0.0f];
    _rightNetLeftPoleShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_rightNetLeftPoleBody width:150 height:20 radius:0.0f];
    _rightNetRightPoleShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_rightNetRightPoleBody width:150 height:20 radius:0.0f];
    _leftGoalLineShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_leftGoalLineBody width:20 height:150 radius:0.0f];
    _rightGoalLineShape = [[ChipmunkPolyShape alloc] initBoxWithBody:_rightGoalLineBody width:20 height:150 radius:0.0f];
    
    
    _leftNetLeftPoleShape.friction = 0.2f;
    _leftNetLeftPoleShape.elasticity = 1.0f;
    _leftNetLeftPoleShape.userData = netLeftView;
    _leftNetRightPoleShape.friction = 0.2f;
    _leftNetRightPoleShape.elasticity = 1.0f;
    _leftNetRightPoleShape.userData = netLeftView;

    _rightNetLeftPoleShape.friction = 0.2f;
    _rightNetLeftPoleShape.elasticity = 1.0f;
    _rightNetLeftPoleShape.userData = netRightView;
    _rightNetRightPoleShape.friction = 0.2f;
    _rightNetRightPoleShape.elasticity = 1.0f;
    _rightNetRightPoleShape.userData = netRightView;
    
    _leftGoalLineShape.friction = 0.0f;
    _leftGoalLineShape.elasticity = 0.0f;
    _leftGoalLineShape.userData = netLeftView;
    _rightGoalLineShape.friction = 0.0f;
    _rightGoalLineShape.elasticity = 0.0f;
    _rightGoalLineShape.userData = netRightView;
    */
    
    [_space add:_ballShape];
    [_space add:_ballBody];
    [_space add:_fishShape];
    [_space add:_fishBody];

    /*
    [_space add:_leftNetLeftPoleShape];
    [_space add:_leftNetLeftPoleBody];
    [_space add:_leftNetRightPoleShape];
    [_space add:_leftNetRightPoleBody];
    [_space add:_rightNetLeftPoleShape];
    [_space add:_rightNetLeftPoleBody];
    [_space add:_rightNetRightPoleShape];
    [_space add:_rightNetRightPoleBody];
    [_space add:_leftGoalLineShape];
    [_space add:_leftGoalLineBody];
    [_space add:_rightGoalLineShape];
    [_space add:_rightGoalLineBody];
    
    [_space addCollisionHandler:self typeA:ballType typeB:leftGoalLineType begin:@selector(ballTouchesGoalLine:inSpace:) preSolve:NULL postSolve:NULL separate:@selector(ballCrossedLeftGoalAccordingToArbiter:inSpace:)];
    [_space addCollisionHandler:self typeA:ballType typeB:rightGoalLineType begin:@selector(ballTouchesGoalLine:inSpace:) preSolve:NULL postSolve:NULL separate:@selector(ballCrossedRightGoalAccordingToArbiter:inSpace:)];
     */
    
    //_space.gravity = cpvmult(cpv(0, 1), 300.0f);
    
}

- (void)ballTouchesGoalLine:(cpArbiter *)arbiter inSpace:(ChipmunkSpace *)space
{
    xVelocityOnGoal = _ballBody.velocity.x;
}
- (void)ballCrossedLeftGoalAccordingToArbiter:(cpArbiter *)arbiter inSpace:(ChipmunkSpace *)space
{
    if (_ballBody.velocity.x * xVelocityOnGoal >= 0.0f) // they are the same sign, this was no mere bounce
    {
        [self rightSideScored];
    }
    xVelocityOnGoal = 0.0f;
}

- (void)ballCrossedRightGoalAccordingToArbiter:(cpArbiter *)arbiter inSpace:(ChipmunkSpace *)space
{
    if (_ballBody.velocity.x * xVelocityOnGoal >= 0.0f) // they are the same sign, this was no mere bounce
    {
        [self leftSideScored];
    }
    xVelocityOnGoal = 0.0f;
}

- (void)leftSideScored
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _leftScore++;
        _leftScoreLabel.text = [[NSString alloc] initWithFormat:@"%zu", _leftScore];
        [_space remove:_ballBody];
        [_space remove:_ballShape];
        
        CGRect screen = [[UIScreen mainScreen] bounds];
        _ballBody.position = cpv(screen.size.width/2, screen.size.height/2);
        _ballBody.velocity = cpvzero;
        [_space add:_ballBody];
        [_space add:_ballShape];
        soccerballView.frame = CGRectMake(screen.size.width/2, screen.size.height/2, 50, 50);

    });
}

- (void)rightSideScored
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _rightScore++;
        _rightScoreLabel.text = [[NSString alloc] initWithFormat:@"%zu", _rightScore];
        [_space remove:_ballBody];
        [_space remove:_ballShape];
        
        CGRect screen = [[UIScreen mainScreen] bounds];
        _ballBody.position = cpv(screen.size.width/2, screen.size.height/2);
        _ballBody.velocity = cpvzero;
        [_space add:_ballBody];
        [_space add:_ballShape];
        soccerballView.frame = CGRectMake(screen.size.width/2, screen.size.height/2, 50, 50);
        
    });
}


-(void)trackingPositionChanged:(CGPoint)point {
    _currentFirstPosition = CGPointMake(point.x * fishView.bounds.size.width, (point.y * fishView.bounds.size.height) + fishView.frame.origin.y);
    
    _currentSpeed = hypotf(_lastFishPosition.x - _currentFirstPosition.x, _lastFishPosition.y - _currentFirstPosition.y);
    
}


@end
