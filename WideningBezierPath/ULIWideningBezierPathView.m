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
	NSBezierPath	*	originalPath = [NSBezierPath bezierPath];
	[originalPath moveToPoint: start];
	[originalPath curveToPoint: end
       controlPoint1: cp1
       controlPoint2: cp2];
	NSBezierPath	*	flatPath = [originalPath bezierPathByFlatteningPath];
	NSPoint				lastEndcapStart = NSZeroPoint,
						lastEndcapEnd = NSZeroPoint;
	CGFloat				segmentStartWidth = startWidth;
	CGFloat				segmentEndWidth = startWidth;
	NSPoint				startPoint = NSZeroPoint;
	NSInteger			numElems = flatPath.elementCount;
	for( NSInteger x = 0; x < numElems; x++ )
	{
		NSPoint				controlPoints[3] = {0};
		NSBezierPathElement elem = [flatPath elementAtIndex: x associatedPoints: controlPoints];
		if( elem == NSMoveToBezierPathElement )
		{
			startPoint = controlPoints[0];
			segmentStartWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) *x));
		}
		else if( elem == NSLineToBezierPathElement )
		{
			segmentEndWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) * x));
			NSPoint	endPoint = controlPoints[0];
			NSPoint	startDist = { endPoint.x -startPoint.x, startPoint.y -endPoint.y };
			NSPoint	orthogonalStartDist = { -startDist.y, startDist.x };
			CGFloat	orthogonalStartDistLen = sqrt(orthogonalStartDist.x*orthogonalStartDist.x +orthogonalStartDist.y*orthogonalStartDist.y);
			CGFloat	startDistScaleFactor = orthogonalStartDistLen / (segmentStartWidth /2);
			NSPoint	halfStartEndcapDist = { orthogonalStartDist.x / startDistScaleFactor, orthogonalStartDist.y / startDistScaleFactor };

			// Now that we know how far one half of the line is away from the center in offsets on the X/Y axes, we can calculate the start & end points of the start's end cap:
			if( x == 1 )
			{
				lastEndcapStart = startPoint,
				lastEndcapEnd = startPoint;
				lastEndcapStart.x -= halfStartEndcapDist.x;
				lastEndcapStart.y -= halfStartEndcapDist.y;
				lastEndcapEnd.x += halfStartEndcapDist.x;
				lastEndcapEnd.y += halfStartEndcapDist.y;
			}
			
			// And the end's end cap:
			NSPoint	endEndcapStart = endPoint,
					endEndcapEnd = endPoint;
			endEndcapStart.x -= halfStartEndcapDist.x;
			endEndcapStart.y -= halfStartEndcapDist.y;
			endEndcapEnd.x += halfStartEndcapDist.x;
			endEndcapEnd.y += halfStartEndcapDist.y;
			
			NSBezierPath	*	segmentPath = [NSBezierPath bezierPath];
			[segmentPath moveToPoint: lastEndcapStart];
			[segmentPath lineToPoint: lastEndcapEnd];
			[segmentPath lineToPoint: endEndcapEnd];
			[segmentPath lineToPoint: endEndcapStart];
			[segmentPath lineToPoint: lastEndcapStart];
			
			[NSColor.purpleColor set];
			[segmentPath fill];
			
			lastEndcapStart = endEndcapStart;
			lastEndcapEnd = endEndcapEnd;
			startPoint = endPoint;
			segmentStartWidth = segmentEndWidth;
		}
	}
	
	// --- Draw the Quartz path that this should correspond to, for comparison:
	[NSColor.blackColor set];
	[originalPath setLineWidth: 1];
	[originalPath stroke];
	
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
