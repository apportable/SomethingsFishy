#import <XCTest/XCTest.h>

#include "ObjectiveChipmunk/ObjectiveChipmunk.h"
#include "ChipmunkAutoGeometry.h"

@interface MiscTest : XCTestCase {}
@end

@implementation MiscTest

-(void)testSlerp {
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(1.0), 1.0);
		cpVect c = a;
		cpVect v = cpvslerp(a, b, 0.0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(1.0), 1.0);
		cpVect c = b;
		cpVect v = cpvslerp(a, b, 1.0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(1.0), 1.0);
		cpVect c = cpvmult(cpvforangle(0.5), 1.0);
		cpVect v = cpvslerp(a, b, 0.5);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(-1.0), 1.0);
		cpVect b = cpvmult(cpvforangle( 1.0), 1.0);
		cpVect c = cpvmult(cpvforangle( 0.0), 1.0);
		cpVect v = cpvslerp(a, b, 0.5);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 2.0);
		cpVect c = cpvadd(cpvmult(a, cpfcos(M_PI/4.0)), cpvmult(b, cpfsin(M_PI/4.0)));
		cpVect v = cpvslerp(a, b, 0.5);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = a;
		cpVect c = a;
		cpVect v = cpvslerp(a, b, 0.5);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	// TODO should it handle this?
//	{
//		cpVect a = cpv( 1.0, 0.01);
//		cpVect b = cpv(-1.0, 0.0);
//		cpVect v = cpvslerp(a, b, 0.5);
//		GHAssertLessThan(cpvdot(a, v), (cpFloat)1e-5, nil);
//		GHAssertLessThan(cpvdot(b, v), (cpFloat)1e-5, nil);
//		GHAssertLessThan(cpvlength(v) - 1.0, (cpFloat)1e-5, nil);
//	}
	
	// Slerp const
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 1.0);
		cpVect c = cpvadd(cpvmult(a, cpfcos(M_PI/4.0)), cpvmult(b, cpfsin(M_PI/4.0)));
		cpVect v = cpvslerpconst(a, b, M_PI/4.0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 1.0);
		cpVect c = b;
		cpVect v = cpvslerpconst(a, b, M_PI/2.0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 1.0);
		cpVect c = b;
		cpVect v = cpvslerpconst(a, b, INFINITY);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 1.0);
		cpVect c = a;
		cpVect v = cpvslerpconst(a, b, 0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
	
	{
		cpVect a = cpvmult(cpvforangle(0.0), 1.0);
		cpVect b = cpvmult(cpvforangle(M_PI/2.0), 1.0);
		cpVect c = cpvmult(cpvforangle(M_PI/4.0), 1.0);
		cpVect v = cpvslerpconst(a, b, M_PI/4.0);
		XCTAssert(cpvdist(v, c) < 1e-5, @"");
	}
}

-(void)testImageSamplerLA
{
	{
		NSBundle *bundle = [NSBundle bundleForClass:self.class];
		CGImageRef image = [ChipmunkImageSampler loadImage:[bundle URLForResource:@"TestImageLA" withExtension:@"png"]];
		ChipmunkAbstractSampler *sampler = [[ChipmunkImageSampler alloc] initWithImage:image isMask:TRUE contextWidth:0 contextHeight:0];
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 0.5)], (cpFloat)0.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 3.5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(3.5, 0.5)], (cpFloat)1.0, 1e-5, @"");
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(2.0 - 1e-5, 0.5)], (cpFloat)0.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(2.0 + 1e-5, 0.5)], (cpFloat)1.0, 1e-5, @"");
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 2.0 - 1e-5)], (cpFloat)0.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 2.0 + 1e-5)], (cpFloat)1.0, 1e-5, @"");
		
		[sampler release];
	}
	
	{
		NSBundle *bundle = [NSBundle bundleForClass:self.class];
		CGImageRef image = [ChipmunkImageSampler loadImage:[bundle URLForResource:@"TestImageLA" withExtension:@"png"]];
		ChipmunkAbstractSampler *sampler = [[ChipmunkImageSampler alloc] initWithImage:image isMask:FALSE contextWidth:0 contextHeight:0];
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 0.5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(0.5, 3.5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(3.5, 0.5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(3.5, 3.5)], (cpFloat)0.0, 1e-5, @"");
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(2.0 - 1e-5, 3.5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(2.0 + 1e-5, 3.5)], (cpFloat)0.0, 1e-5, @"");
		
		XCTAssertEqualWithAccuracy([sampler sample:cpv(3.5, 2.0 - 1e-5)], (cpFloat)1.0, 1e-5, @"");
		XCTAssertEqualWithAccuracy([sampler sample:cpv(3.5, 2.0 + 1e-5)], (cpFloat)0.0, 1e-5, @"");
		
		[sampler release];
	}
}

-(void)testMultiGrabSort
{
	ChipmunkSpace *space = [[ChipmunkSpace alloc] init];
	ChipmunkMultiGrab *multiGrab = [[ChipmunkMultiGrab alloc] initForSpace:space withSmoothing:0.0 withGrabForce:1.0];
	
	ChipmunkBody *body = [space add:[ChipmunkBody bodyWithMass:1.0 andMoment:1.0]];
	ChipmunkShape *big = [space add:[ChipmunkCircleShape circleWithBody:body radius:10.0 offset:cpvzero]];
	ChipmunkShape *small = [space add:[ChipmunkCircleShape circleWithBody:body radius:5.0 offset:cpvzero]];
	
	// Used for the custom sorting orders.
	big.userData = @0;
	small.userData = @1;
	
	ChipmunkGrab *grab1 = [multiGrab beginLocation:cpvzero];
	XCTAssertEqual(grab1.grabbedShape, big, @"Should have grabbed 'big' since it has the largest penetration depth.");
	
	multiGrab.grabSort = ^(ChipmunkShape *shape, cpFloat depth){
		NSNumber *n = shape.userData;
		return (cpFloat)n.floatValue;
	};
	
	// Should grab small since it's sorting order will be the largest;
	ChipmunkGrab *grab2 = [multiGrab beginLocation:cpvzero];
	XCTAssertEqual(grab2.grabbedShape, small, @"Should have grabbed 'small' since it has the highest custom sort value.");
	
	[multiGrab release];
	[space release];
}

@end