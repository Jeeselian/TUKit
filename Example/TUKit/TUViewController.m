//
//  TUViewController.m
//  TUKit
//
//  Created by Jeeselian on 03/13/2020.
//  Copyright (c) 2020 Jeeselian. All rights reserved.
//

#import "TUViewController.h"

@interface TUViewController ()
@property (weak, nonatomic) IBOutlet UIView *testView;

@end

@implementation TUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
   // self.testView.clickSingalName = @"testView";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

Click_TUSignal(testView){
    NSLog(@"点击了testView");
}

@end

