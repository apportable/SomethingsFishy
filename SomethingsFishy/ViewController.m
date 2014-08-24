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
}

@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    
    UIImageView *seaBed = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sea-Bed"]];
    
    [seaBed setFrame:CGRectMake(0, (screen.size.height-(margin+10)), screen.size.width, margin+10)];
    
    [[self view] addSubview:fishView];
    [[self view] addSubview:seaBed];
    
}

@end
