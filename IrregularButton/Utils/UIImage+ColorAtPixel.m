//
//  UIImage+ColorAtPixel.m
//  IrregularButton
//
//  Created by wayfor on 2018/6/21.
//  Copyright © 2018年 LIUSON. All rights reserved.
//

#import "UIImage+ColorAtPixel.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation UIImage (ColorAtPixel)

- (UIColor *)colorAtPixel:(CGPoint)point{
    //判断一个CGPoint 是否包含在另一个UIView的CGRect里面,常用与测试给定的对象之间是否又重叠
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), point)) {
        return nil;
    }
    
    //创建一个1x1像素字节数组和位图上下文来绘制像素。
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = self.CGImage;
    NSUInteger width = self.size.width;
    NSUInteger height = self.size.height;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };

    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);

    //在位图上下文中画出我们感兴趣的像素
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    //Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}


@end
