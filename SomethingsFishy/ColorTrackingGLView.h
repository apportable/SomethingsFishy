//
//  ColorTrackingGLView.h
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "ColorTrackingCamera.h"


typedef enum { PASSTHROUGH_VIDEO, SIMPLE_THRESHOLDING, POSITION_THRESHOLDING, OBJECT_TRACKING} ColorTrackingDisplayMode;

@protocol ColorTrackingObserver <NSObject>

- (void)trackingPositionChanged:(CGPoint)point inFrame:(CGRect)frame;

@end

@interface ColorTrackingGLView : UIView <ColorTrackingCameraDelegate>
{
    ColorTrackingCamera *camera;
	/* The pixel dimensions of the backbuffer */
	GLint backingWidth, backingHeight;
	
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	GLuint positionRenderTexture;
	GLuint positionRenderbuffer, positionFramebuffer;
    
    CALayer *trackingDot;
    
    ColorTrackingDisplayMode displayMode;
    
    BOOL shouldReplaceThresholdColor;
    CGPoint currentTouchPoint;
    GLfloat thresholdSensitivity;
    GLfloat thresholdColor[3];
    
    GLuint directDisplayProgram, thresholdProgram, positionProgram;
    GLuint videoFrameTexture;
    
    GLubyte *rawPositionPixels;
}

@property(readonly) GLuint positionRenderTexture;

// OpenGL drawing
- (BOOL)createFramebuffers;
- (void)destroyFramebuffer;
- (void)setDisplayFramebuffer;
- (void)setPositionThresholdFramebuffer;
- (BOOL)presentFramebuffer;

- (void)addTrackingObserver:(id<ColorTrackingObserver>)observer;
- (void)removeTrackingObserver:(id<ColorTrackingObserver>)observer;

@end
