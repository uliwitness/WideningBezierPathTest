//
//  ULIWideningBezierPathView.h
//  WideningBezierPath
//
//  Created by Uli Kusterer on 2014-03-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ULIWideningBezierPathView : NSView
{
	NSPoint		start;
	NSPoint		end;
	NSPoint		cp1;
	NSPoint		cp2;
	CGFloat		startWidth;
	CGFloat		endWidth;
}

@end
