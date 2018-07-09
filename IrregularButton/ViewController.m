//
//  ViewController.m
//  IrregularButton
//
//  Created by wayfor on 2018/6/21.
//  Copyright © 2018年 LIUSON. All rights reserved.
//

#import "ViewController.h"
#import "NewButtonView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIView *view = [[NSBundle mainBundle] loadNibNamed:@"NewButtonView" owner:nil options:nil].lastObject;
    view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    
    
    
    
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
