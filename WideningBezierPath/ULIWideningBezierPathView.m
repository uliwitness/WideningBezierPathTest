//
//  ULIWideningBezierPathView.m
//  WideningBezierPath
//
//  Created by Uli Kusterer on 2014-03-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "ULIWideningBezierPathView.h"

@implementation ULIWideningBezierPathView

-(id)	initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if( self )
	{
		start = (NSPoint){ 100, 100 };
		end = (NSPoint){ 500, 500 };
		cp1 = (NSPoint){ 250, 100 };
		cp2 = (NSPoint){ 500, 250 };
		startWidth = 8;
		endWidth = 32;
	}
	return self;
}
-(id)	initWithFrame: (NSRect)box
{
	self = [super initWithFrame: box];
	if( self )
	{
		start = (NSPoint){ 100, 100 };
		end = (NSPoint){ 500, 500 };
		cp1 = (NSPoint){ 250, 100 };
		cp2 = (NSPoint){ 500, 250 };
		startWidth = 8;
		endWidth = 32;
	}
	return self;
}


#define CONTROL_POINT_WIDTH		8


-(void)	drawRect: (NSRect)dirtyRect
{
	// Draw variable-width path as a shape:
	
	NSBezierPath	*	segmentPath = [NSBezierPath bezierPath];
	[segmentPath moveToPoint: NSMakePoint( start.x, start.y -(startWidth / 2) )];
	[segmentPath lineToPoint: NSMakePoint( start.x, start.y +(startWidth / 2) )];
	[segmentPath curveToPoint: NSMakePoint( end.x -(endWidth / 2), end.y ) controlPoint1: cp1 controlPoint2: cp2];
	[segmentPath lineToPoint: NSMakePoint( end.x +(endWidth / 2), end.y )];
	[segmentPath curveToPoint: NSMakePoint( start.x, start.y -(startWidth / 2) ) controlPoint1: cp2 controlPoint2: cp1];
	
	[NSColor.purpleColor set];
	[segmentPath fill];
	
	// Draw Quartz path this should correspond to for comparison:
	NSBezierPath	*	originalPath = [NSBezierPath bezierPath];
	[originalPath moveToPoint: start];
	[originalPath curveToPoint: end
       controlPoint1: cp1
       controlPoint2: cp2];
	
	[NSColor.blackColor set];
	[originalPath setLineWidth: 1];
	[originalPath stroke];
	
	// Draw control points:
	[NSColor.greenColor set];
	[[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(cp1.x -(CONTROL_POINT_WIDTH /2), cp1.y -(CONTROL_POINT_WIDTH /2), CONTROL_POINT_WIDTH, CONTROL_POINT_WIDTH)] fill];
	[NSBezierPath fillRect: NSMakeRect(cp2.x -(CONTROL_POINT_WIDTH /2), cp2.y -(CONTROL_POINT_WIDTH /2), CONTROL_POINT_WIDTH, CONTROL_POINT_WIDTH)];
}


-(void)	mouseDown: (NSEvent *)theEvent
{
	NSPoint	cp = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	if( [theEvent modifierFlags] & NSAlternateKeyMask )
		cp2 = cp;
	else
		cp1 = cp;
	[self setNeedsDisplay: YES];
}


-(void)	mouseDragged: (NSEvent *)theEvent
{
	[self mouseDown: theEvent];
}

@end
