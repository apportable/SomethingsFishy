//
//  ColorTrackingGLView.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "ColorTrackingGLView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>


// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
    UNIFORM_INPUTCOLOR,
    UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@implementation ColorTrackingGLView {
    NSMutableArray *observers;
}

#pragma mark -
#pragma mark Initialization and teardown

// Override the class method to return the OpenGL layer, as opposed to the normal CALayer
+ (Class) layerClass 
{
	return [CAEAGLLayer class];
}


- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
        observers = [[NSMutableArray alloc] init];
		// Do OpenGL Core Animation layer setup
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		// Set scaling to account for Retina display	
//		if ([self respondsToSelector:@selector(setContentScaleFactor:)])
//		{
//			self.contentScaleFactor = [[UIScreen mainScreen] scale];
//		}
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffers]) 
		{
            self = nil;
			return nil;
		}
        
        NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
        
        [currentDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithFloat:0.89f], @"thresholdColorR",
                                           [NSNumber numberWithFloat:0.78f], @"thresholdColorG",
                                           [NSNumber numberWithFloat:0.0f], @"thresholdColorB",
                                           [NSNumber numberWithFloat:0.7], @"thresholdSensitivity",
                                           nil]];
        
        thresholdColor[0] = [currentDefaults floatForKey:@"thresholdColorR"];
        thresholdColor[1] = [currentDefaults floatForKey:@"thresholdColorG"];
        thresholdColor[2] = [currentDefaults floatForKey:@"thresholdColorB"];
        displayMode = PASSTHROUGH_VIDEO;
        // Custom initialization
        thresholdSensitivity = [currentDefaults floatForKey:@"thresholdSensitivity"];
        
        rawPositionPixels = (GLubyte *) calloc(self.glWidth * self.glHeight * 4, sizeof(GLubyte));
        
        [self loadVertexShader:@"DirectDisplayShader" fragmentShader:@"DirectDisplayShader" forProgram:&directDisplayProgram];
        [self loadVertexShader:@"ThresholdShader" fragmentShader:@"ThresholdShader" forProgram:&thresholdProgram];
        [self loadVertexShader:@"PositionShader" fragmentShader:@"PositionShader" forProgram:&positionProgram];
        
        // Set up the toolbar at the bottom of the screen
        UISegmentedControl *displayModeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Video", nil), NSLocalizedString(@"Threshold", nil), NSLocalizedString(@"Position", nil), NSLocalizedString(@"Track", nil), nil]];
        displayModeControl.selectedSegmentIndex = 0;
        [displayModeControl addTarget:self action:@selector(handleSwitchOfDisplayMode:) forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:displayModeControl];
        displayModeControl.frame = CGRectMake(0.0f, 5.0f, 300.0f, 30.0f);
        
        NSArray *theToolbarItems = [NSArray arrayWithObjects:item, nil];
        
        UIToolbar *lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 44.0f, frame.size.width, 44.0f)];
        lowerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        lowerToolbar.tintColor = [UIColor blackColor];
        
        [lowerToolbar setItems:theToolbarItems];
        
        [self addSubview:lowerToolbar];
        
        // Create the tracking dot
        trackingDot = [[CALayer alloc] init];
        trackingDot.bounds = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
        trackingDot.cornerRadius = 20.0f;
        trackingDot.backgroundColor = [[UIColor blueColor] CGColor];
        
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position",
                                           nil];
        
        trackingDot.actions = newActions;
        
        [self.layer addSublayer:trackingDot];
        trackingDot.position = CGPointMake(100.0f, 100.0f);
        trackingDot.opacity = 0.0f;
        
        camera = [[ColorTrackingCamera alloc] init];
        camera.delegate = self;
        [self cameraHasConnected];
		
        // Initialization code
    }
    return self;
}


- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
{
    GLuint vertexShader, fragShader;
    
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer])
    {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer)
        {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    // Release vertex and fragment shaders.
    if (vertexShader)
    {
        glDeleteShader(vertexShader);
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
    }
    
    return TRUE;
}

- (void)drawFrame
{
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureVertices[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        0.0f,  0.0f,
    };
    
    /*	static const GLfloat passthroughTextureVertices[] = {
     0.0f, 0.0f,
     1.0f, 0.0f,
     0.0f,  1.0f,
     1.0f,  1.0f,
     };
     */
    //    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    //    glClear(GL_COLOR_BUFFER_BIT);
    
    // Use shader program.
    switch (displayMode)
    {
        case PASSTHROUGH_VIDEO:
        {
            [self setDisplayFramebuffer];
            glUseProgram(directDisplayProgram);
        }; break;
        case SIMPLE_THRESHOLDING:
        {
            [self setDisplayFramebuffer];
            glUseProgram(thresholdProgram);
        }; break;
        case POSITION_THRESHOLDING:
        {
            [self setDisplayFramebuffer];
            glUseProgram(positionProgram);
        }; break;
        case OBJECT_TRACKING:
        {
            [self setPositionThresholdFramebuffer];
            glUseProgram(positionProgram);
        }; break;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
    
    // Update uniform values
    glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);
    glUniform4f(uniforms[UNIFORM_INPUTCOLOR], thresholdColor[0], thresholdColor[1], thresholdColor[2], 1.0f);
    glUniform1f(uniforms[UNIFORM_THRESHOLD], thresholdSensitivity);
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if (displayMode == OBJECT_TRACKING)
    {
        //		glGenerateMipmap(GL_TEXTURE_2D);
        
        // Grab the current position of the object from the offscreen framebuffer
        glReadPixels(0, 0, self.glWidth, self.glHeight, GL_RGBA, GL_UNSIGNED_BYTE, rawPositionPixels);
        CGPoint currentTrackingLocation = [self centroidFromTexture:rawPositionPixels];
        
        if (isnan(currentTrackingLocation.x)|| isnan(currentTrackingLocation.y)) {
            trackingDot.opacity = 0;
        } else {
            trackingDot.opacity = 1;
            trackingDot.position = CGPointMake(currentTrackingLocation.x * self.bounds.size.width, currentTrackingLocation.y * self.bounds.size.height);
        }
        
        [self setDisplayFramebuffer];
        glUseProgram(directDisplayProgram);
        
        // Grab the previously rendered texture and feed that into the next level of processing
        //		glActiveTexture(GL_TEXTURE0);
        //		glBindTexture(GL_TEXTURE_2D, glView.positionRenderTexture);
        //		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
        //		glEnableVertexAttribArray(ATTRIB_VERTEX);
        //		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, passthroughTextureVertices);
        //		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    else
    {
    }
    
    [self presentFramebuffer];
}

#pragma mark -
#pragma mark OpenGL drawing

- (GLuint)glHeight {
    return 720/2;
}

- (GLuint)glWidth {
    return 1280/2;
}


- (BOOL)createFramebuffers
{	
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);

	// Onscreen framebuffer object
	glGenFramebuffers(1, &viewFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	glGenRenderbuffers(1, &viewRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);
	
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"Failure with framebuffer generation");
		return NO;
	}
	
	// Offscreen position framebuffer object
	glGenFramebuffers(1, &positionFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, positionFramebuffer);

	glGenRenderbuffers(1, &positionRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, positionRenderbuffer);
	
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (GLuint)self.glWidth,  (GLuint)self.glHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, positionRenderbuffer);	
    

	// Offscreen position framebuffer texture target
	glGenTextures(1, &positionRenderTexture);
    glBindTexture(GL_TEXTURE_2D, positionRenderTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	//GL_NEAREST_MIPMAP_NEAREST

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLuint)self.glWidth, (GLuint)self.glHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FBO_WIDTH, FBO_HEIGHT, 0, GL_RGBA, GL_FLOAT, 0);

	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, positionRenderTexture, 0);
//	NSLog(@"GL error15: %d", glGetError());
	
	
	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"Incomplete FBO: %d", status);
        exit(1);
    }
	
	
	
	return YES;
}

- (void)destroyFramebuffer;
{	
	if (viewFramebuffer)
	{
		glDeleteFramebuffers(1, &viewFramebuffer);
		viewFramebuffer = 0;
	}
	
	if (viewRenderbuffer)
	{
		glDeleteRenderbuffers(1, &viewRenderbuffer);
		viewRenderbuffer = 0;
	}
}

- (void)setDisplayFramebuffer;
{
    if (context)
    {
//        [EAGLContext setCurrentContext:context];
        
        if (!viewFramebuffer)
		{
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
        
        glViewport(0, 0, backingWidth, backingHeight);
    }
}

- (void)setPositionThresholdFramebuffer;
{
    if (context)
    {
		//        [EAGLContext setCurrentContext:context];
        
        if (!positionFramebuffer)
		{
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, positionFramebuffer);
        
        glViewport(0, 0, (GLuint)self.glWidth, (GLuint)self.glHeight);
    }
}

- (BOOL)presentFramebuffer;
{
    BOOL success = FALSE;
    
    if (context)
    {
  //      [EAGLContext setCurrentContext:context];
        
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
        
        success = [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}

#pragma mark -
#pragma mark Accessors

@synthesize positionRenderTexture;

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

#pragma mark -
#pragma mark Display mode switching

- (void)handleSwitchOfDisplayMode:(id)sender;
{
    displayMode = (ColorTrackingDisplayMode)[sender selectedSegmentIndex];
    
    if (displayMode == OBJECT_TRACKING)
    {
        trackingDot.opacity = 1.0f;
    }
    else
    {
        trackingDot.opacity = 0.0f;
    }
}

#pragma mark -
#pragma mark Image processing

- (CGPoint)centroidFromTexture:(GLubyte *)pixels
{
    CGFloat currentXTotal = 0.0f, currentYTotal = 0.0f, currentPixelTotal = 0.0f;
    int width = self.glWidth;
    int height = self.glHeight;
    for (NSUInteger currentPixel = 0; currentPixel < (width * height); currentPixel++)
    {
        currentYTotal += (CGFloat)pixels[currentPixel * 4] / 255.0f;
        currentXTotal += (CGFloat)pixels[(currentPixel * 4) + 1] / 255.0f;
        currentPixelTotal += (CGFloat)pixels[(currentPixel * 4) + 3] / 255.0f;
    }
    
    return CGPointMake(1.0f - (currentXTotal / currentPixelTotal), currentYTotal / currentPixelTotal);
}

#pragma mark -
#pragma mark ColorTrackingCameraDelegate methods

- (void)cameraHasConnected;
{
    //	NSLog(@"Connected to camera");
    /*	camera.videoPreviewLayer.frame = self.view.bounds;
     [self.view.layer addSublayer:camera.videoPreviewLayer];*/
}


- (void)processNewCameraFrame:(CVImageBufferRef)cameraFrame;
{
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    size_t bufferHeight = CVPixelBufferGetHeight(cameraFrame);
    size_t bufferWidth = CVPixelBufferGetWidth(cameraFrame);
    
    //NSLog(@"%zu %zu",bufferHeight, bufferWidth);
    
    
    /*
     * rotationConstant:   0 -- rotate 0 degrees (simply copy the data from src to dest)
     *             1 -- rotate 90 degrees counterclockwise
     *             2 -- rotate 180 degress
     *             3 -- rotate 270 degrees counterclockwise
     */
    
    uint8_t rotationConstant = 1;
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
    size_t currSize = bytesPerRow*bufferHeight*sizeof(unsigned char);
    size_t bytesPerRowOut = 4*bufferHeight*sizeof(unsigned char);
    
    unsigned char *outBuff = (unsigned char*)malloc(currSize);
    
    vImage_Buffer ibuff = { CVPixelBufferGetBaseAddress(cameraFrame), bufferHeight, bufferWidth, bytesPerRow};
    vImage_Buffer ubuff = { outBuff, bufferWidth, bufferHeight, bytesPerRowOut};
    
    uint8_t bgColor[4] = {0, 0, 0, 0};
    vImage_Error err= vImageRotate90_ARGB8888 (&ibuff, &ubuff, rotationConstant, bgColor, 0);
    if (err != kvImageNoError) NSLog(@"%ld", err);
    
    
    if (shouldReplaceThresholdColor)
    {
        // Extract a color at the touch point from the raw camera data
        int scaledVideoPointX = round((self.bounds.size.width - currentTouchPoint.x) * (CGFloat)bufferWidth / self.bounds.size.width);
        int scaledVideoPointY = round(currentTouchPoint.y * (CGFloat)bufferHeight / self.bounds.size.height);
        
        unsigned char *rowBase = outBuff;
        size_t bytesPerRow = 4*bufferHeight*sizeof(unsigned char);
        unsigned char *pixel = rowBase + (scaledVideoPointX * bytesPerRow) + (scaledVideoPointY * 4);
        
        thresholdColor[0] = (float)pixel[2] / 255.0;
        thresholdColor[1] = (float)pixel[1] / 255.0;
        thresholdColor[2] = (float)pixel[0] / 255.0;
        
        [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[0] forKey:@"thresholdColorR"];
        [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[1] forKey:@"thresholdColorG"];
        [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[2] forKey:@"thresholdColorB"];
        
        shouldReplaceThresholdColor = NO;
    }
    
    // Create a new texture from the camera frame data, display that using the shaders
    glGenTextures(1, &videoFrameTexture);
    glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // Using BGRA extension to pull in video frame data directly
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)bufferHeight, (GLsizei)bufferWidth, 0, GL_BGRA, GL_UNSIGNED_BYTE, outBuff);
    
    free(outBuff);
    [self drawFrame];
    
    glDeleteTextures(1, &videoFrameTexture);
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}


#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    currentTouchPoint = [[touches anyObject] locationInView:self];
    shouldReplaceThresholdColor = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
    CGPoint movedPoint = [[touches anyObject] locationInView:self];
    CGFloat distanceMoved = sqrt( (movedPoint.x - currentTouchPoint.x) * (movedPoint.x - currentTouchPoint.x) + (movedPoint.y - currentTouchPoint.y) * (movedPoint.y - currentTouchPoint.y) );
    
    thresholdSensitivity = distanceMoved / 160.0f;
    [[NSUserDefaults standardUserDefaults] setFloat:thresholdSensitivity forKey:@"thresholdSensitivity"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}


- (void)addTrackingObserver:(id<ColorTrackingObserver>)observer {
    [observers addObject:observer];
}
- (void)removeTrackingObserver:(id<ColorTrackingObserver>)observer {
    [observers removeObject:observer];
}

@end
