//
//  ShapedButton.m
//  IrregularButton
//
//  Created by wayfor on 2018/6/21.
//  Copyright © 2018年 LIUSON. All rights reserved.
//

#import "ShapedButton.h"
#import "UIImage+ColorAtPixel.h"

@interface UIImageView (PointConversionCategory)

@property (nonatomic, readonly) CGAffineTransform viewToImageTransform;
@property (nonatomic, readonly) CGAffineTransform imageToViewTransform;


@end

@implementation UIImageView (PointConversionCategory)


-(CGAffineTransform) viewToImageTransform {
    UIViewContentMode contentMode = self.contentMode;
    
    if (!self.image || self.frame.size.width == 0 || self.frame.size.height == 0 ||
        (contentMode != UIViewContentModeScaleToFill && contentMode != UIViewContentModeScaleAspectFill && contentMode != UIViewContentModeScaleAspectFit)) {
        return CGAffineTransformIdentity;
    }
    
    
    // the width and height ratios
    CGFloat rWidth = self.image.size.width/self.frame.size.width;
    CGFloat rHeight = self.image.size.height/self.frame.size.height;
    
    //图像是否按宽度缩放
    BOOL imageWiderThanView = rWidth > rHeight;
    
    if (contentMode == UIViewContentModeScaleAspectFit || contentMode == UIViewContentModeScaleAspectFill) {
        
        CGFloat ratio = ((imageWiderThanView && contentMode == UIViewContentModeScaleAspectFit) || (!imageWiderThanView && contentMode == UIViewContentModeScaleAspectFill)) ? rWidth : rHeight;
        
        CGFloat xOffset = (self.image.size.width-(self.frame.size.width*ratio))*0.5;
        
        CGFloat yOffset = (self.image.size.height-(self.frame.size.height*ratio))*0.5;
        
        //CGAffineTransformConcat 通过两个已经存在的放射矩阵生成一个新的矩阵t' = t1 * t2
        //带Make 创建一个仿射矩阵 CGAffineTransformMakeScale  设置缩放 CGAffineTransformMakeTranslation  设置偏移
        return CGAffineTransformConcat(CGAffineTransformMakeScale(ratio, ratio), CGAffineTransformMakeTranslation(xOffset, yOffset));
        
    }else{
        
        return CGAffineTransformMakeScale(rWidth, rHeight);
    }
}

-(CGAffineTransform) imageToViewTransform {
    //CGAffineTransformInvert 反向的仿射矩阵比如（x，y）通过矩阵t得到了（x',y'）那么通过这个函数生成的t'作用与（x',y'）就能得到原始的(x,y)
    return CGAffineTransformInvert(self.viewToImageTransform);
}

@end


@interface ShapedButton()

@property (nonatomic, assign) CGPoint previousTouchPoint;
@property (nonatomic, assign) BOOL previousTouchHitTestResponse;
@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, strong) UIImage *buttonBackground;


- (void)updateImageCacheForCurrentState;
- (void)resetHitTestCache;

@end

@implementation ShapedButton


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];
}

#pragma mark - HIt testing
- (BOOL)isAlphaVisibleAtPoint:(CGPoint)point forImage:(UIImage *)image
{
    //包含内容模式的图像缩放校正
    point.x = point.x - self.imageView.frame.origin.x;
    point.y = point.y - self.imageView.frame.origin.y;
    
    //CGPointApplyAffineTransform 得到新的点
    CGPoint pt = CGPointApplyAffineTransform(point, self.imageView.viewToImageTransform);
    point = pt;
    NSLog(@"pt%@",NSStringFromCGPoint(pt));
    
    UIColor *pixelColor = [image colorAtPixel:point];
    NSLog(@"pixelColor%@",pixelColor);

    CGFloat alpha = 0.0;

    //根据图片的颜色进行alpha通道判断，确定是否相应
    //判断两个UIColor对象的颜色或者透明度是否相等
    //得到颜色值和透明度值
    if ([pixelColor respondsToSelector:@selector(getRed:green:blue:alpha:)])
    {
        // available from iOS 5.0
        NSLog(@"alpha one %.2f",alpha);

        [pixelColor getRed:NULL green:NULL blue:NULL alpha:&alpha];
        NSLog(@"true=%@",[pixelColor getRed:NULL green:NULL blue:NULL alpha:&alpha] ? @"YES" : @"NO");
        NSLog(@"alpha two%.2f",alpha);

    }
    else
    {
        // for iOS < 5.0
        // In iOS 6.1 this code is not working in release mode, it works only in debug
        // CGColorGetAlpha always return 0.
        CGColorRef cgPixelColor = [pixelColor CGColor];
        alpha = CGColorGetAlpha(cgPixelColor);
    }
    NSLog(@"alpha last %.2f",alpha);

    return alpha >= kAlphaVisibleThreshold;
    
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    
    //重写 判断，是否点击了我们想要的区域，是的话就返回YES，否则返回NO
    BOOL superResult = [super pointInside:point withEvent:event];
    NSLog(@"--superResult=%d",superResult);

    if (!superResult) {
        return superResult;
    }
    
    if (CGPointEqualToPoint(point, self.previousTouchPoint)) {
        return self.previousTouchHitTestResponse;
    }else{
        self.previousTouchPoint = point;
    }
    
    BOOL response = NO;
    if (self.buttonImage == nil && self.buttonBackground == nil) {
        response = YES;
        
    }else if (self.buttonImage != nil && self.buttonBackground == nil) {
        response = [self isAlphaVisibleAtPoint:point forImage:self.buttonImage];
    }else if (self.buttonImage == nil && self.buttonBackground != nil) {
        response = [self isAlphaVisibleAtPoint:point forImage:self.buttonBackground];
    }else {
        if ([self isAlphaVisibleAtPoint:point forImage:self.buttonImage]) {
            response = YES;
        } else {
            response = [self isAlphaVisibleAtPoint:point forImage:self.buttonBackground];
        }
    }
    
    self.previousTouchHitTestResponse = response;
    NSLog(@"--response=%d",response);
    return response;
    
    
    
}

#pragma mark - Accessors
-(void)setImage:(UIImage *)image forState:(UIControlState)state{
    [super setImage:image forState:state];
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];

}

-(void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state{
    [super setBackgroundImage:image forState:state];
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];

}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateImageCacheForCurrentState];

}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateImageCacheForCurrentState];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateImageCacheForCurrentState];
}

#pragma mark - Helper methods
- (void)updateImageCacheForCurrentState
{
    _buttonBackground = [self currentBackgroundImage];
    _buttonImage = [self currentImage];
}

- (void)resetHitTestCache
{
    self.previousTouchPoint = CGPointMake(CGFLOAT_MIN, CGFLOAT_MIN);
    self.previousTouchHitTestResponse = NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
