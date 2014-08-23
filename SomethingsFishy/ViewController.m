//
//  ViewController.m
//  SomethingsFishy
//
//  Created by Zac Bowling on 8/23/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "ViewController.h"
#import "ColorTrackingGLView.h"

@interface ViewController ()

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
    self.view = [[ColorTrackingGLView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
}

@end
