//
//  MCParallaxLayer.h
//  Parallax
//
//  Created by Miguel Angel Friginal on 9/7/11.
//  Copyright 2011 Mystery Coconut, LLC. All rights reserved.
//

#include <QuartzCore/CALayer.h>

typedef struct {
    int x;
    int y;
} TileCoords;


@class MCParallaxLayer;


@protocol MCParallaxLayerContentProvider <NSObject>

- (CGImageRef)atlasFor:(MCParallaxLayer*)sender;
- (CGRect)tileAt:(TileCoords)pos for:(MCParallaxLayer*)sender;

@end


@interface MCParallaxLayer : CALayer {
    CGSize tileSize; // in points
    float scrollMultiplier;
    id<MCParallaxLayerContentProvider> provider;
    BOOL horizontal;
    uint tag;
}

@property (nonatomic, weak) id<MCParallaxLayerContentProvider> provider;
@property (nonatomic) float scrollMultiplier;
@property (nonatomic) CGSize tileSize;
@property (nonatomic, getter = isHorizontal) BOOL horizontal;
@property (nonatomic) uint tag;

- (id)initWithBounds:(CGRect)theBounds tileSize:(CGSize)theTileSize provider:(id<MCParallaxLayerContentProvider>)theProvider isHorizontal:(BOOL)isHorizontal opaque:(BOOL)isOpaque tag:(uint)theTag;
- (void)scrollTiles:(CGPoint)diff;

@end
