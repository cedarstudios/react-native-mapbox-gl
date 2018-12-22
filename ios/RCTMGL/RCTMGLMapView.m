//
//  RCTMGLMapView.m
//  RCTMGL
//
//  Created by Nick Italiano on 8/23/17.
//  Copyright © 2017 Mapbox Inc. All rights reserved.
//

#import "RCTMGLMapView.h"
#import "CameraUpdateQueue.h"
#import "RCTMGLUtils.h"
#import "RNMBImageUtils.h"
#import "UIView+React.h"

@interface RCTMGLMapView()

@property (nonatomic, strong) UIImage *cedarmapsLogo;

@end

@implementation RCTMGLMapView

static double const DEG2RAD = M_PI / 180;
static double const LAT_MAX = 85.051128779806604;
static double const TILE_SIZE = 256;
static double const EARTH_RADIUS_M = 6378137;
static double const M2PI = M_PI * 2;

@synthesize cedarmapsLogo = _cedarmapsLogo;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _cameraUpdateQueue = [[CameraUpdateQueue alloc] init];
        _sources = [[NSMutableArray alloc] init];
        _pointAnnotations = [[NSMutableArray alloc] init];
        _reactSubviews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)invalidate
{
    if (_reactSubviews.count == 0) {
        return;
    }
    for (int i = 0; i < _reactSubviews.count; i++) {
        [self removeFromMap:_reactSubviews[i]];
    }
}

- (void) addToMap:(id<RCTComponent>)subview
{
    if ([subview isKindOfClass:[RCTMGLSource class]]) {
        RCTMGLSource *source = (RCTMGLSource*)subview;
        source.map = self;
        [_sources addObject:(RCTMGLSource*)subview];
    } else if ([subview isKindOfClass:[RCTMGLLight class]]) {
        RCTMGLLight *light = (RCTMGLLight*)subview;
        _light = light;
        _light.map = self;
    } else if ([subview isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *pointAnnotation = (RCTMGLPointAnnotation *)subview;
        pointAnnotation.map = self;
        [_pointAnnotations addObject:pointAnnotation];
    } else {
        NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];

        for (int i = 0; i < childSubviews.count; i++) {
            [self addToMap:childSubviews[i]];
        }
    }
}

- (void) removeFromMap:(id<RCTComponent>)subview
{
    if ([subview isKindOfClass:[RCTMGLSource class]]) {
        RCTMGLSource *source = (RCTMGLSource*)subview;
        source.map = nil;
        [_sources removeObject:source];
    } else if ([subview isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *pointAnnotation = (RCTMGLPointAnnotation *)subview;
        pointAnnotation.map = nil;
        [_pointAnnotations removeObject:pointAnnotation];
    } else {
        NSArray<id<RCTComponent>> *childSubViews = [subview reactSubviews];
        
        for (int i = 0; i < childSubViews.count; i++) {
            [self removeFromMap:childSubViews[i]];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex {
    [self addToMap:subview];
    [_reactSubviews insertObject:(UIView *)subview atIndex:(NSUInteger) atIndex];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)removeReactSubview:(id<RCTComponent>)subview {
    // similarly, when the children are being removed we have to do the appropriate
    // underlying mapview action here.
    [self removeFromMap:subview];
    [_reactSubviews removeObject:(UIView *)subview];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (NSArray<id<RCTComponent>> *)reactSubviews {
    return _reactSubviews;
}
#pragma clang diagnostic pop

- (UIImage *)cedarmapsLogo {
    if (!_cedarmapsLogo) {
        NSString *base64Logo = @"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);";
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Logo options: NSDataBase64DecodingIgnoreUnknownCharacters];
        _cedarmapsLogo = [UIImage imageWithData:data];
    }
    return _cedarmapsLogo;
}

- (void)setReactZoomEnabled:(BOOL)reactZoomEnabled
{
    _reactZoomEnabled = reactZoomEnabled;
    self.zoomEnabled = _reactZoomEnabled;
}

- (void)setReactScrollEnabled:(BOOL)reactScrollEnabled
{
    _reactScrollEnabled = reactScrollEnabled;
    self.scrollEnabled = _reactScrollEnabled;
}

- (void)setReactPitchEnabled:(BOOL)reactPitchEnabled
{
    _reactPitchEnabled = reactPitchEnabled;
    self.pitchEnabled = _reactPitchEnabled;
}

- (void)setReactRotateEnabled:(BOOL)reactRotateEnabled
{
    _reactRotateEnabled = reactRotateEnabled;
    self.rotateEnabled = _reactRotateEnabled;
}

- (void)setReactAttributionEnabled:(BOOL)reactAttributionEnabled
{
    _reactAttributionEnabled = reactAttributionEnabled;
    self.attributionButton.hidden = !_reactAttributionEnabled;
}

- (void)setReactLogoEnabled:(BOOL)reactLogoEnabled
{
    _reactLogoEnabled = reactLogoEnabled;
    self.logoView.hidden = !_reactLogoEnabled;
}

- (void)setReactCompassEnabled:(BOOL)reactCompassEnabled
{
    _reactCompassEnabled = reactCompassEnabled;
    self.compassView.hidden = !_reactCompassEnabled;
}

- (void)setReactShowUserLocation:(BOOL)reactShowUserLocation
{
    _reactShowUserLocation = reactShowUserLocation;
    self.showsUserLocation = _reactShowUserLocation;
}

- (void)setReactCenterCoordinate:(NSString *)reactCenterCoordinate
{
    _reactCenterCoordinate = reactCenterCoordinate;
    [self _updateCameraIfNeeded:YES];
}

- (void)setReactContentInset:(NSArray<NSNumber *> *)reactContentInset
{
    CGFloat top = 0.0f, right = 0.0f, left = 0.0f, bottom = 0.0f;
    
    if (reactContentInset.count == 4) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[1] floatValue];
        bottom = [reactContentInset[2] floatValue];
        left = [reactContentInset[3] floatValue];
    } else if (reactContentInset.count == 2) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[1] floatValue];
        bottom = [reactContentInset[0] floatValue];
        left = [reactContentInset[1] floatValue];
    } else if (reactContentInset.count == 1) {
        top = [reactContentInset[0] floatValue];
        right = [reactContentInset[0] floatValue];
        bottom = [reactContentInset[0] floatValue];
        left = [reactContentInset[0] floatValue];
    }
    
    self.contentInset = UIEdgeInsetsMake(top, left, bottom, right);
}

- (void)setReactStyleURL:(NSString *)reactStyleURL
{
    _reactStyleURL = reactStyleURL;
    [self _removeAllSourcesFromMap];
    self.styleURL = [self _getStyleURLFromKey:_reactStyleURL];
    
    self.attributionButton.alpha = 0;
    self.logoView.image = self.cedarmapsLogo;
    
    [self.logoView setTranslatesAutoresizingMaskIntoConstraints: NO];
    [[self.logoView.widthAnchor constraintEqualToConstant:80.0] setActive:YES];
    [[self.logoView.heightAnchor constraintEqualToConstant:21.0] setActive:YES];
}

- (void)setHeading:(double)heading
{
    _heading = heading;
    [self _updateCameraIfNeeded:NO];
}

- (void)setPitch:(double)pitch
{
    _pitch = pitch;
    [self _updateCameraIfNeeded:NO];
}

- (void)setReactZoomLevel:(double)reactZoomLevel
{
    _reactZoomLevel = reactZoomLevel;
    self.zoomLevel = _reactZoomLevel;
}

- (void)setReactMinZoomLevel:(double)reactMinZoomLevel
{
    _reactMinZoomLevel = reactMinZoomLevel;
    self.minimumZoomLevel = _reactMinZoomLevel;
}

- (void)setReactMaxZoomLevel:(double)reactMaxZoomLevel
{
    _reactMaxZoomLevel = reactMaxZoomLevel;
    self.maximumZoomLevel = reactMaxZoomLevel;
}

- (void)setReactUserTrackingMode:(int)reactUserTrackingMode
{
    _reactUserTrackingMode = reactUserTrackingMode;
    [self setUserTrackingMode:_reactUserTrackingMode animated:NO];
    self.showsUserHeadingIndicator = (NSUInteger)_reactUserTrackingMode == MGLUserTrackingModeFollowWithHeading;
}

- (void)setReactUserLocationVerticalAlignment:(int)reactUserLocationVerticalAlignment
{
    _reactUserLocationVerticalAlignment = reactUserLocationVerticalAlignment;
    self.userLocationVerticalAlignment = reactUserLocationVerticalAlignment;
}

#pragma mark - methods

- (NSString *)takeSnap:(BOOL)writeToDisk
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return writeToDisk ? [RNMBImageUtils createTempFile:snapshot] : [RNMBImageUtils createBase64:snapshot];
}

- (CLLocationDistance)getMetersPerPixelAtLatitude:(double)latitude withZoom:(double)zoomLevel
{
    double constrainedZoom = [[RCTMGLUtils clamp:[NSNumber numberWithDouble:zoomLevel]
                                             min:[NSNumber numberWithDouble:self.minimumZoomLevel]
                                             max:[NSNumber numberWithDouble:self.maximumZoomLevel]] doubleValue];
    
    double constrainedLatitude = [[RCTMGLUtils clamp:[NSNumber numberWithDouble:latitude]
                                                 min:[NSNumber numberWithDouble:-LAT_MAX]
                                                 max:[NSNumber numberWithDouble:LAT_MAX]] doubleValue];
    
    double constrainedScale = pow(2.0, constrainedZoom);
    return cos(constrainedLatitude * DEG2RAD) * M2PI * EARTH_RADIUS_M / (constrainedScale * TILE_SIZE);
}

- (CLLocationDistance)altitudeFromZoom:(double)zoomLevel
{
    CLLocationDistance metersPerPixel = [self getMetersPerPixelAtLatitude:self.camera.centerCoordinate.latitude withZoom:zoomLevel];
    CLLocationDistance metersTall = metersPerPixel * self.frame.size.height;
    CLLocationDistance altitude = metersTall / 2 / tan(MGLRadiansFromDegrees(30) / 2.0);
    return altitude * sin(M_PI_2 - MGLRadiansFromDegrees(self.camera.pitch)) / sin(M_PI_2);
}

- (RCTMGLPointAnnotation*)getRCTPointAnnotation:(MGLPointAnnotation *)mglAnnotation
{
    for (int i = 0; i < _pointAnnotations.count; i++) {
        RCTMGLPointAnnotation *rctAnnotation = _pointAnnotations[i];
        if (rctAnnotation.annotation == mglAnnotation) {
            return rctAnnotation;
        }
    }
    return nil;
}

- (NSArray<RCTMGLSource *> *)getAllTouchableSources
{
    NSMutableArray<RCTMGLSource *> *touchableSources = [[NSMutableArray alloc] init];
    
    for (RCTMGLSource *source in _sources) {
        if (source.hasPressListener) {
            [touchableSources addObject:source];
        }
    }
    
    return touchableSources;
}

- (RCTMGLSource *)getTouchableSourceWithHighestZIndex:(NSArray<RCTMGLSource *> *)touchableSources
{
    if (touchableSources == nil || touchableSources.count == 0) {
        return nil;
    }
    
    if (touchableSources.count == 1) {
        return touchableSources[0];
    }
    
    NSMutableDictionary<NSString *, RCTMGLSource *> *layerToSoureDict = [[NSMutableDictionary alloc] init];
    for (RCTMGLSource *touchableSource in touchableSources) {
        NSArray<NSString *> *layerIDs = [touchableSource getLayerIDs];
        
        for (NSString *layerID in layerIDs) {
            layerToSoureDict[layerID] = touchableSource;
        }
    }
    
    NSArray<MGLStyleLayer *> *layers = self.style.layers;
    for (int i = (int)layers.count - 1; i >= 0; i--) {
        MGLStyleLayer *layer = layers[i];
        
        RCTMGLSource *source = layerToSoureDict[layer.identifier];
        if (source != nil) {
            return source;
        }
    }
    
    return nil;
}

- (NSURL*)_getStyleURLFromKey:(NSString *)styleURL
{
    return [NSURL URLWithString:styleURL];
}

- (void)_updateCameraIfNeeded:(BOOL)shouldUpdateCenterCoord
{
    if (shouldUpdateCenterCoord) {
        [self setCenterCoordinate:[RCTMGLUtils fromFeature:_reactCenterCoordinate] animated:_animated];
    } else {
        MGLMapCamera *camera = [self.camera copy];
        camera.pitch = _pitch;
        camera.heading = _heading;
        [self setCamera:camera animated:_animated];
    }
}

- (void)_removeAllSourcesFromMap
{
    if (self.style == nil || _sources.count == 0) {
        return;
    }
    for (RCTMGLSource *source in _sources) {
        source.map = nil;
    }
}

@end
