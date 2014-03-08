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
	// --- Calculate start & endpoints for the lines that serve as end caps for our line shape:
	// Luckily, the slope at the start/end of a bezer curve is the slope of the line through that endpoint and its control point:
	// Calculate the distances of the end points:
	NSPoint	startDist = { start.x -cp1.x, start.y -cp1.y },
			endDist = { end.x -cp2.x, end.y -cp2.y };
	// Now calc the same for perpendicular lines to these (the end caps of our line's shape):
	NSPoint	orthogonalStartDist = { -startDist.y, startDist.x },
			orthogonalEndDist = { -endDist.y, endDist.x };
	// We know our lines go through start/end, and we know they should be startWidth/endWidth long:
	//	Now we need to calculate endpoints for such a line, using Pythagoras (a line
	//	could be seen as the hypothenuse of a right triangle, with startDist/endDist describing
	//	the triangle's other two sides):
	// First, find out how far apart our start/end point and corresponding control point really are:
	CGFloat	orthogonalStartDistLen = sqrt(orthogonalStartDist.x*orthogonalStartDist.x +orthogonalStartDist.y*orthogonalStartDist.y);
	CGFloat	orthogonalEndDistLen = sqrt(orthogonalEndDist.x*orthogonalEndDist.x +orthogonalEndDist.y*orthogonalEndDist.y);
	// Now, determine what we need to divide it by to get the desired length (startWidth /2), so we can calc top & bottom relative to middle:
	CGFloat	startDistScaleFactor = orthogonalStartDistLen / (startWidth /2);
	CGFloat	endDistScaleFactor = orthogonalEndDistLen / (endWidth /2);
	NSPoint	halfStartEndcapDist = { orthogonalStartDist.x / startDistScaleFactor, orthogonalStartDist.y / startDistScaleFactor };
	NSPoint	halfEndEndcapDist = { orthogonalEndDist.x / endDistScaleFactor, orthogonalEndDist.y / endDistScaleFactor };

	// Now that we know how far one half of the line is away from the center in offsets on the X/Y axes, we can calculate the start & end points of the start's end cap:
	NSPoint	startEndcapStart = start,
			startEndcapEnd = start;
	startEndcapStart.x -= halfStartEndcapDist.x;
	startEndcapStart.y -= halfStartEndcapDist.y;
	startEndcapEnd.x += halfStartEndcapDist.x;
	startEndcapEnd.y += halfStartEndcapDist.y;
	
	// And the end's end cap:
	NSPoint	endEndcapStart = end,
			endEndcapEnd = end;
	endEndcapStart.x -= halfEndEndcapDist.x;
	endEndcapStart.y -= halfEndEndcapDist.y;
	endEndcapEnd.x += halfEndEndcapDist.x;
	endEndcapEnd.y += halfEndEndcapDist.y;
		
	// --- Draw variable-width path as a shape:
	NSBezierPath	*	segmentPath = [NSBezierPath bezierPath];
	[segmentPath moveToPoint: startEndcapStart];
	[segmentPath lineToPoint: startEndcapEnd];
	[segmentPath curveToPoint: endEndcapEnd controlPoint1: cp1 controlPoint2: cp2];
	[segmentPath lineToPoint: endEndcapStart];
	[segmentPath curveToPoint: startEndcapStart controlPoint1: cp2 controlPoint2: cp1];
	
	[NSColor.purpleColor set];
	[segmentPath fill];
	
	// --- Draw Quartz path this should correspond to for comparison:
	NSBezierPath	*	originalPath = [NSBezierPath bezierPath];
	[originalPath moveToPoint: start];
	[originalPath curveToPoint: end
       controlPoint1: cp1
       controlPoint2: cp2];
	
	[NSColor.blackColor set];
	[originalPath setLineWidth: 1];
	[originalPath stroke];

	[NSColor.redColor set];
	[NSBezierPath strokeLineFromPoint: startEndcapStart toPoint: startEndcapEnd];

	[NSColor.redColor set];
	[NSBezierPath strokeLineFromPoint: endEndcapStart toPoint: endEndcapEnd];
	
	// --- Draw control points:
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
