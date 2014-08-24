// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#import "ObjectiveChipmunk/ObjectiveChipmunk.h"
#import "ChipmunkHastySpace.h"

#import "cpHastySpace.h"

@interface ChipmunkSpace()

-(id)initWithSpace:(cpSpace *)space;

@end


@implementation ChipmunkHastySpace

- (id)init {
	return [self initWithSpace:cpHastySpaceNew()];
}

-(void)freeSpace
{
	cpHastySpaceFree(_space);
}

- (void)step:(cpFloat)dt;
{
	cpHastySpaceStep(_space, dt);
}

-(NSUInteger)threads
{
	return cpHastySpaceGetThreads(_space);
}

-(void)setThreads:(NSUInteger)threads
{
	cpHastySpaceSetThreads(_space, threads);
}

@end
