//
//  MCParallaxLayer.m
//  Parallax
//
//  Created by Miguel Angel Friginal on 9/7/11.
//  Copyright 2011 Mystery Coconut, LLC. All rights reserved.
//

#import "MCParallaxLayer.h"
#import <QuartzCore/CATransaction.h>
#import <Foundation/NSException.h>


@interface MCParallaxLayer() {
    // For these to work the project needs to be compiled with LLVM.
    // If you need GCC just get the instance vars out to the header file & mark them as @private
    CALayer **tiles;
    uint numTiles;
    uint tilesWide;
    uint tilesHigh;
    BOOL initialized;
    TileCoords prevOriginTileCoords;
    CGPoint scrollLeftover;
}

- (CGPoint)tileCoordsToPoint:(TileCoords)coords;
- (TileCoords)pointToTileCoords:(CGPoint)pt;
- (void)repositionAllTiles;

@end


@implementation MCParallaxLayer

@synthesize scrollMultiplier, provider, tileSize, horizontal, tag;

#pragma mark -
#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) 
    {
        initialized = NO;
        scrollMultiplier = 1.0f;
        horizontal = NO;
        self.anchorPoint = CGPointZero;
    }
    return self;
}


- (id)initWithBounds:(CGRect)theBounds tileSize:(CGSize)theTileSize provider:(id<MCParallaxLayerContentProvider>)theProvider isHorizontal:(BOOL)isHorizontal opaque:(BOOL)isOpaque tag:(uint)theTag;
{
    self = [self init];
    if (self)
    {
        horizontal = isHorizontal;
        tag = theTag;
        self.bounds = theBounds;
        self.provider = theProvider;
        self.opaque = isOpaque;
        self.tileSize = theTileSize;
    }
    return self;
}


- (void)setTileSize:(CGSize)size;
{
    if (tiles)
    {
        for(int i=0; i<numTiles; ++i)
        {
            [tiles[i] removeFromSuperlayer];
            [tiles[i] release];
        }
        free(tiles); tiles = nil;
    }
    
    tileSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
    tilesWide = ceilf(self.bounds.size.width / tileSize.width) + 2;
    tilesHigh = ceilf(self.bounds.size.height / tileSize.height);
    if (!horizontal) 
        tilesHigh += 2;
    numTiles = tilesWide * tilesHigh; // overflow waiting to happen :P
    tiles = calloc(sizeof(CALayer*), numTiles);
    
    CGImageRef img = [provider atlasFor:self];
    for (int i=0; i<numTiles; ++i) 
    {
        tiles[i] = [[CALayer layer] retain];
        tiles[i].anchorPoint = CGPointZero;
        tiles[i].bounds = CGRectMake(0, 0, tileSize.width, tileSize.height);
        tiles[i].contents = (id)img;
        tiles[i].opaque = self.opaque;
        
        [self addSublayer:tiles[i]];
    }
}


- (void)setProvider:(id<MCParallaxLayerContentProvider>)newProvider;
{
    provider = newProvider;
    
    if (tiles)
    {
        CGImageRef img = [provider atlasFor:self];
        for (int i=0; i<numTiles; ++i) 
        {
            tiles[i].contents = (id)img;
        }
    }
}


- (void)dealloc
{
    if (tiles)
    {
        for(int i = 0; i < numTiles; ++i)
            [tiles[i] release];
        free(tiles);
    }
    
    [super dealloc];
}


#pragma mark -
#pragma mark TileCoords to CGPoints and viceversa

- (CGPoint)tileCoordsToPoint:(TileCoords)coords;
{
    return CGPointMake((float)coords.x * tileSize.width, (float)coords.y * tileSize.height);
}


- (TileCoords)pointToTileCoords:(CGPoint)pt;
{
    return (TileCoords){ (int)floorf(0.5f + pt.x/tileSize.width), (int)floorf(0.5f + pt.y/tileSize.height) };
}


#pragma mark -
#pragma mark Scrolling

- (void)scrollTiles:(CGPoint)diff;
{
    scrollLeftover.x += diff.x * scrollMultiplier;
    scrollLeftover.y += diff.y * scrollMultiplier;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGRect currentBounds = self.bounds;
    
    self.bounds = CGRectMake(floorf(currentBounds.origin.x + scrollLeftover.x), floorf(currentBounds.origin.y +  scrollLeftover.y), currentBounds.size.width, currentBounds.size.height);
    
    [CATransaction commit];

    scrollLeftover.x -= floorf(scrollLeftover.x);
    scrollLeftover.y -= floorf(scrollLeftover.y);
}


- (void)repositionAllTiles;
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    prevOriginTileCoords = [self pointToTileCoords:self.bounds.origin];
    prevOriginTileCoords.x -= 1;
    if (!horizontal)
        prevOriginTileCoords.y -= 1;        
    
    for (int i = 0; i < numTiles; ++i) {
        const TileCoords coords = (TileCoords){ prevOriginTileCoords.x + i % tilesWide, prevOriginTileCoords.y + i / tilesWide };
        tiles[i].position = [self tileCoordsToPoint:coords];
        tiles[i].contentsRect = [provider tileAt:coords for:self];
    }
    
    initialized = YES;

    [CATransaction commit];
}


// layoutSublayers is called after [CATransaction commit] -> CALayoutIfNeeded because the change in the properties (position, bounds, etc.) of sublayers!
- (void)layoutSublayers;
{
    if (!initialized) 
    {
        [self repositionAllTiles];
        return;
    }
    
    const TileCoords pos = [self pointToTileCoords:self.bounds.origin];
    TileCoords topLeftTile = { pos.x - 1, pos.y - 1 };
    if (horizontal)
        topLeftTile.y = pos.y;
    
    int xDir = topLeftTile.x - prevOriginTileCoords.x; // 1 = new col to the right; 0 = no change; -1 = new col to the left
    int yDir = topLeftTile.y - prevOriginTileCoords.y; // 1 = new row at bottom; 0 = no change; -1 = new row at top
    
    NSAssert(xDir <= 1 && xDir >= -1 && yDir <= 1 && yDir >= -1, @"Scrolling too fast");
    
    if (xDir == 0 && yDir == 0)
        return;
    
    prevOriginTileCoords = topLeftTile;
    
    int affectedColumn, affectedRow;
    float xDiff, yDiff;
    
    xDiff = (float)xDir * tilesWide * tileSize.width;
    affectedColumn = (xDir == 1) ? topLeftTile.x - 1 : topLeftTile.x + tilesWide;
    yDiff = (float)yDir * tilesHigh * tileSize.height;
    affectedRow = (yDir == 1) ? topLeftTile.y - 1 : topLeftTile.y + tilesHigh;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    TileCoords tilePos;
    for (int i = 0; i < numTiles; ++i)
    {
        BOOL changed = NO;
        tilePos = [self pointToTileCoords:tiles[i].position];
        
        if (xDir && tilePos.x == affectedColumn)
        {
            tiles[i].position = CGPointMake(tiles[i].position.x + xDiff, tiles[i].position.y);
            changed = YES;
        }
        
        if (yDir && tilePos.y == affectedRow)
        {
            tiles[i].position = CGPointMake(tiles[i].position.x, tiles[i].position.y + yDiff);
            changed = YES;
        }
        
        if (changed)
            tiles[i].contentsRect = [provider tileAt:tilePos for:self];
    }
    
    [CATransaction commit];
}


@end
