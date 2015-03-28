//
//  ULIWideningBezierPath.h
//  WideningBezierPath
//
//  Created by Uli Kusterer on 2014-03-09.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ULIWideningBezierPath : NSObject

-(NSBezierPath*)	pathForFill;
-(NSBezierPath*)	pathForStroke;		// An NSBezierPath describing the outline of this path with varying line widths. This is the thing you want to draw.
-(CGPathRef)		CGPathForFill;
-(CGPathRef)		CGPathForStroke;	// A CGPathRef describing the outline of this path with varying line widths. This is the thing you want to draw.

// Path construction.

- (void)moveToPoint:(NSPoint)point lineWidth: (CGFloat)width;
- (void)lineToPoint:(NSPoint)point lineWidth: (CGFloat)width;
- (void)curveToPoint:(NSPoint)endPoint
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2
	   lineWidth: (CGFloat)width;
- (void)closePath;

- (void)removeAllPoints;

// Relative path construction.

- (void)relativeMoveToPoint:(NSPoint)point lineWidth: (CGFloat)width;
- (void)relativeLineToPoint:(NSPoint)point lineWidth: (CGFloat)width;
- (void)relativeCurveToPoint:(NSPoint)endPoint
	       controlPoint1:(NSPoint)controlPoint1
	       controlPoint2:(NSPoint)controlPoint2
		   lineWidth: (CGFloat)width;

@end
