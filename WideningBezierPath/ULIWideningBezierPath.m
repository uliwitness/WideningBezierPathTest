//
//  ULIWideningBezierPath.m
//  WideningBezierPath
//
//  Created by Uli Kusterer on 2014-03-09.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "ULIWideningBezierPath.h"

@interface ULIWideningBezierPath ()
{
	NSBezierPath	*	actualPath;
	CGMutablePathRef	actualCGPath;
	CGFloat			*	lineSizeArray;
}

@end


@implementation ULIWideningBezierPath

-(void)	dealloc
{
	if( lineSizeArray )
	{
		free( lineSizeArray );
	}
	[actualPath release];
	CGPathRelease(actualCGPath);
	
	[super dealloc];
}


-(void)	uli_appendPoint: (NSPoint)inPoint toList: (NSPointArray*)pointArray withCounter: (NSInteger*)numPoints
{
	(*numPoints) ++;
	
	if( *pointArray == NULL )
		*pointArray = malloc( sizeof(NSPoint) );
	else
	{
		void*	newArray = realloc( *pointArray, (*numPoints) * sizeof(NSPoint) );
		NSAssert( newArray != NULL, @"Can't append additional points." );
		*pointArray = newArray;
	}
	
	(*pointArray)[(*numPoints)-1] = inPoint;
}


-(void)	uli_addPointsForStrokeOfLineFrom: (NSPoint)start toPoint: (NSPoint)end toDownArray: (NSPointArray*)downPoints downCount: (NSInteger*)numDownPoints upArray: (NSPointArray*)upPoints upCount: (NSInteger*)numUpPoints startWidth: (CGFloat)segmentStartWidth endWidth: (CGFloat)segmentEndWidth
{
	NSPoint	endPoint = end;
	NSPoint	startDist = { endPoint.x -start.x, start.y -endPoint.y };
	NSPoint	orthogonalStartDist = { -startDist.y, startDist.x };
	CGFloat	orthogonalStartDistLen = sqrt(orthogonalStartDist.x*orthogonalStartDist.x +orthogonalStartDist.y*orthogonalStartDist.y);
	CGFloat	startDistScaleFactor = orthogonalStartDistLen / (segmentStartWidth /2);
	NSPoint	halfStartEndcapDist = { orthogonalStartDist.x / startDistScaleFactor, orthogonalStartDist.y / startDistScaleFactor };
	
	// Now that we know how far one half of the line is away from the center in offsets on the X/Y axes, we can calculate the start & end points of the end's end cap:
	NSPoint	endEndcapStart = endPoint,
			endEndcapEnd = endPoint;
	endEndcapStart.x -= halfStartEndcapDist.x;
	endEndcapStart.y += halfStartEndcapDist.y;
	endEndcapEnd.x += halfStartEndcapDist.x;
	endEndcapEnd.y -= halfStartEndcapDist.y;
	
	[self uli_appendPoint: endEndcapEnd toList: downPoints withCounter: numDownPoints];
	[self uli_appendPoint: endEndcapStart toList: upPoints withCounter: numUpPoints];
}


-(void)	uli_addPointsForBezierPath: (NSBezierPath*)path toDownArray: (NSPointArray*)downPoints downCount: (NSInteger*)numDownPoints upArray: (NSPointArray*)upPoints upCount: (NSInteger*)numUpPoints startWidth: (CGFloat)startWidth endWidth: (CGFloat)endWidth lastPoint: (NSPoint*)lastPoint
{
	NSLog( @"line width = %f, %f", startWidth, endWidth );
	
	NSBezierPath	*	flatPath = [path bezierPathByFlatteningPath];
	NSInteger			numElems = flatPath.elementCount;
	for( NSInteger x = 0; x < numElems; x++ )
	{
		NSPoint				controlPoints[3] = {{0}};
		NSBezierPathElement elem = [flatPath elementAtIndex: x associatedPoints: controlPoints];
		CGFloat				segmentStartWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) *x));
		CGFloat				segmentEndWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) * x));
		
		if( elem == NSMoveToBezierPathElement )
		{
			segmentStartWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) *x));
			[self uli_addPointsForStrokeOfLineFrom: controlPoints[1] toPoint: controlPoints[0] toDownArray: downPoints downCount: numDownPoints upArray: upPoints upCount: numUpPoints startWidth: segmentStartWidth endWidth: segmentStartWidth];
			*lastPoint = controlPoints[0];
			NSLog( @"segmentWidth = %f, %f", segmentStartWidth, segmentEndWidth );
		}
		else if( elem == NSLineToBezierPathElement )
		{
			segmentEndWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) * x));
			[self uli_addPointsForStrokeOfLineFrom: *lastPoint toPoint: controlPoints[0] toDownArray: downPoints downCount: numDownPoints upArray: upPoints upCount: numUpPoints startWidth: segmentStartWidth endWidth: segmentEndWidth];
			NSLog( @"segmentWidth(2) = %f, %f", segmentStartWidth, segmentEndWidth );
			
			*lastPoint = controlPoints[0];
			segmentStartWidth = segmentEndWidth;
		}
	}
	NSLog(@"");
}


-(void)	uli_addPointsForStrokeOfPathElement: (NSBezierPathElement)inElem points: (NSPointArray)points startLineWidth: (CGFloat)startWidth endLineWidth: (CGFloat)endWidth toDownArray: (NSPointArray*)downPoints downCount: (NSInteger*)numDownPoints upArray: (NSPointArray*)upPoints upCount: (NSInteger*)numUpPoints lastPoint: (NSPoint*)lastPoint
{
	switch( inElem )
	{
		case NSMoveToBezierPathElement:
//			[self uli_addPointsForStrokeOfLineFrom: *lastPoint toPoint: points[0] toDownArray: downPoints downCount: numDownPoints upArray: upPoints upCount: numUpPoints startWidth: startWidth endWidth: endWidth];
			*lastPoint = points[0];
			break;
		
		case NSLineToBezierPathElement:
			[self uli_addPointsForStrokeOfLineFrom: *lastPoint toPoint: points[0] toDownArray: downPoints downCount: numDownPoints upArray: upPoints upCount: numUpPoints startWidth: startWidth endWidth: endWidth];
			*lastPoint = points[0];
			break;
		
		case NSCurveToBezierPathElement:
		{
			NSBezierPath*	currSegment = [NSBezierPath bezierPath];
			[currSegment moveToPoint: *lastPoint];
			[currSegment curveToPoint: points[2] controlPoint1: points[0] controlPoint2: points[1]];
			[self uli_addPointsForBezierPath: currSegment toDownArray: downPoints downCount: numDownPoints upArray: upPoints upCount: numUpPoints startWidth: startWidth endWidth: endWidth lastPoint: lastPoint];
			*lastPoint = points[2];
			break;
		}
		
		case NSClosePathBezierPathElement:
			// +++ Add line back to start?
			break;
	}
}


-(NSBezierPath*)	uli_pathForStroke
{
	for( NSInteger x = 0; x < actualPath.elementCount; x++ )
	{
		NSLog( @"lineWidth = %f", lineSizeArray[x] );
	}
	NSLog( @"" );
	
	NSPointArray	downPoints = NULL;
	NSInteger		numDownPoints = 0;
	NSPointArray	upPoints = NULL;
	NSInteger		numUpPoints = 0;
	CGFloat			lastLineWidth = lineSizeArray[0];
	NSPoint			lastPoint = NSZeroPoint;
	
	NSInteger		numElems = actualPath.elementCount;
	for( NSInteger x = 0; x < numElems; x++ )
	{
		NSPoint				controlPoints[3] = {{0}};
		NSBezierPathElement elem = [actualPath elementAtIndex: x associatedPoints: controlPoints];
		
		[self uli_addPointsForStrokeOfPathElement: elem points: controlPoints startLineWidth: lastLineWidth endLineWidth: lineSizeArray[x] toDownArray: &downPoints downCount: &numDownPoints upArray: &upPoints upCount: &numUpPoints lastPoint: &lastPoint];
		lastLineWidth = lineSizeArray[x];
	}
	
	NSBezierPath	*strokePath = [NSBezierPath bezierPath];
	// Start cap of line:
	[strokePath moveToPoint: upPoints[0]];
	[strokePath lineToPoint: downPoints[0]];
	for( NSInteger x = 1; x < numDownPoints; x++ )
		[strokePath lineToPoint: downPoints[x]];
	for( NSInteger x = (numUpPoints -1); x > -1; x-- )
		[strokePath lineToPoint: upPoints[x]];
	
	if( downPoints )
		free(downPoints);
	if( upPoints )
		free(upPoints);
	
	return strokePath;
}


-(CGPathRef)	uli_CGPathForStroke
{
	for( NSInteger x = 0; x < actualPath.elementCount; x++ )
	{
		NSLog( @"lineWidth = %f", lineSizeArray[x] );
	}
	NSLog( @"" );
	
	NSPointArray	downPoints = NULL;
	NSInteger		numDownPoints = 0;
	NSPointArray	upPoints = NULL;
	NSInteger		numUpPoints = 0;
	CGFloat			lastLineWidth = lineSizeArray[0];
	NSPoint			lastPoint = NSZeroPoint;
	
	NSInteger		numElems = actualPath.elementCount;
	for( NSInteger x = 0; x < numElems; x++ )
	{
		NSPoint				controlPoints[3] = {{0}};
		NSBezierPathElement elem = [actualPath elementAtIndex: x associatedPoints: controlPoints];
		
		[self uli_addPointsForStrokeOfPathElement: elem points: controlPoints startLineWidth: lastLineWidth endLineWidth: lineSizeArray[x] toDownArray: &downPoints downCount: &numDownPoints upArray: &upPoints upCount: &numUpPoints lastPoint: &lastPoint];
		lastLineWidth = lineSizeArray[x];
	}
	
	CGMutablePathRef	strokePath = CGPathCreateMutable();
	[(id)strokePath autorelease];
	
	// Start cap of line:
	CGPathMoveToPoint( strokePath, NULL, upPoints[0].x, upPoints[0].y );
	CGPathAddLineToPoint( strokePath, NULL, downPoints[0].x, downPoints[0].y );
	for( NSInteger x = 1; x < numDownPoints; x++ )
		CGPathAddLineToPoint( strokePath, NULL, downPoints[x].x, downPoints[x].y );
	for( NSInteger x = (numUpPoints -1); x > -1; x-- )
		CGPathAddLineToPoint( strokePath, NULL, upPoints[x].x, upPoints[x].y );
	
	if( downPoints )
		free(downPoints);
	if( upPoints )
		free(upPoints);
	
	return strokePath;
}


-(CGPathRef)	CGPathForFill
{
	return actualCGPath;
}


-(CGPathRef)	CGPathForStroke
{
	return [self uli_CGPathForStroke];
}


-(NSBezierPath*)	pathForFill
{
	return actualPath;
}


-(NSBezierPath*)	pathForStroke
{
	if( actualPath.elementCount == 0 )
		return actualPath;
	
	return [self uli_pathForStroke];
	
	// Generate a shape that corresponds to the outline of this path:
//	NSBezierPath	*	flatPath = [actualPath bezierPathByFlatteningPath];
//	NSPoint				lastEndcapStart = NSZeroPoint,
//						lastEndcapEnd = NSZeroPoint;
//	CGFloat				segmentStartWidth = lineSizeArray[0];
//	CGFloat				segmentEndWidth = lineSizeArray[0];
//	NSPoint				startPoint = NSZeroPoint;
//	NSInteger			numElems = flatPath.elementCount;
//	NSBezierPath*		wideningPath = [NSBezierPath bezierPath];
//	NSPoint	*			backPoints = (NSPoint*) calloc(sizeof(NSPoint),numElems);
//	for( NSInteger flatElementIndex = 0; flatElementIndex < numElems; flatElementIndex++ )
//	{
//		NSPoint				controlPoints[3] = {0};
//		NSBezierPathElement elem = [flatPath elementAtIndex: flatElementIndex associatedPoints: controlPoints];
//		if( elem == NSMoveToBezierPathElement )
//		{
//			startPoint = controlPoints[0];
//			segmentStartWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) *flatElementIndex));
//		}
//		else if( elem == NSLineToBezierPathElement )
//		{
//			segmentEndWidth = startWidth +((endWidth -startWidth) *((1.0 / numElems) * flatElementIndex));
//			NSPoint	endPoint = controlPoints[0];
//			NSPoint	startDist = { endPoint.x -startPoint.x, startPoint.y -endPoint.y };
//			NSPoint	orthogonalStartDist = { -startDist.y, startDist.x };
//			CGFloat	orthogonalStartDistLen = sqrt(orthogonalStartDist.x*orthogonalStartDist.x +orthogonalStartDist.y*orthogonalStartDist.y);
//			CGFloat	startDistScaleFactor = orthogonalStartDistLen / (segmentStartWidth /2);
//			NSPoint	halfStartEndcapDist = { orthogonalStartDist.x / startDistScaleFactor, orthogonalStartDist.y / startDistScaleFactor };
//
//			// Now that we know how far one half of the line is away from the center in offsets on the X/Y axes, we can calculate the start & end points of the start's end cap:
//			if( flatElementIndex == 1 )
//			{
//				lastEndcapStart = startPoint,
//				lastEndcapEnd = startPoint;
//				lastEndcapStart.x -= halfStartEndcapDist.x;
//				lastEndcapStart.y += halfStartEndcapDist.y;
//				lastEndcapEnd.x += halfStartEndcapDist.x;
//				lastEndcapEnd.y -= halfStartEndcapDist.y;
//				[wideningPath moveToPoint: lastEndcapStart];
//				[wideningPath lineToPoint: lastEndcapEnd];
//			}
//			
//			// And the end's end cap:
//			NSPoint	endEndcapStart = endPoint,
//					endEndcapEnd = endPoint;
//			endEndcapStart.x -= halfStartEndcapDist.x;
//			endEndcapStart.y += halfStartEndcapDist.y;
//			endEndcapEnd.x += halfStartEndcapDist.x;
//			endEndcapEnd.y -= halfStartEndcapDist.y;
//			
//			[wideningPath lineToPoint: endEndcapEnd];
//			backPoints[flatElementIndex] = lastEndcapStart;
//			
//			lastEndcapStart = endEndcapStart;
//			lastEndcapEnd = endEndcapEnd;
//			startPoint = endPoint;
//			segmentStartWidth = segmentEndWidth;
//		}
//	}
//	
//	[wideningPath lineToPoint: lastEndcapStart];
//	
//	for( NSInteger x = numElems-1; x > 0; x-- )
//		[wideningPath lineToPoint: backPoints[x]];
//	free( backPoints );
//	backPoints = NULL;
//	
//	return wideningPath;
}


-(void)	uli_addLineWidth: (CGFloat)width
{
	if( !lineSizeArray )
	{
		lineSizeArray = malloc( sizeof(NSPoint) );
		lineSizeArray[0] = width;
	}
	else
	{
		void*	newArray = realloc( lineSizeArray, actualPath.elementCount * sizeof(NSPoint) );
		NSAssert( newArray != NULL, @"Couldn't add another line size." );
		lineSizeArray = newArray;
		lineSizeArray[actualPath.elementCount -1] = width;
	}
}


- (void)moveToPoint:(NSPoint)point lineWidth: (CGFloat)width
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath moveToPoint: point];
	CGPathMoveToPoint( actualCGPath, NULL, point.x, point.y );
	[self uli_addLineWidth: width];
}


- (void)lineToPoint:(NSPoint)point lineWidth: (CGFloat)width
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath lineToPoint: point];
	CGPathAddLineToPoint( actualCGPath, NULL, point.x, point.y );
	[self uli_addLineWidth: width];
}


- (void)curveToPoint:(NSPoint)endPoint
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2
	   lineWidth: (CGFloat)width
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath curveToPoint: endPoint controlPoint1: controlPoint1 controlPoint2: controlPoint2];
	CGPathAddCurveToPoint( actualCGPath, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y );
	[self uli_addLineWidth: width];
}


- (void)closePath
{
	[actualPath closePath];
	CGPathCloseSubpath( actualCGPath );
}


- (void)removeAllPoints
{
	if( lineSizeArray )
	{
		free( lineSizeArray );
		lineSizeArray = NULL;
	}
	[actualPath removeAllPoints];
	CGPathRelease( actualCGPath );
	actualCGPath = CGPathCreateMutable();
}


// Relative path construction.

- (void)relativeMoveToPoint:(NSPoint)point lineWidth: (CGFloat)width
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath relativeMoveToPoint: point];
	// +++ also update actualCGPath
	[self uli_addLineWidth: width];
}


- (void)relativeLineToPoint:(NSPoint)point lineWidth: (CGFloat)width;
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath relativeLineToPoint: point];
	// +++ also update actualCGPath
	[self uli_addLineWidth: width];
}


- (void)relativeCurveToPoint:(NSPoint)endPoint
	       controlPoint1:(NSPoint)controlPoint1
	       controlPoint2:(NSPoint)controlPoint2
		   lineWidth: (CGFloat)width
{
	if( !actualPath )
	{
		actualPath = [[NSBezierPath alloc] init];
		actualCGPath = CGPathCreateMutable();
	}
	[actualPath relativeCurveToPoint: endPoint controlPoint1: controlPoint1 controlPoint2: controlPoint2];
	// +++ also update actualCGPath
	[self uli_addLineWidth: width];
}

@end
