// Copyright 2020-2026 The Defold Foundation
// Copyright 2014-2020 King
// Copyright 2009-2014 Ragnar Svensson, Christian Murray
// Licensed under the Defold License version 1.0 (the "License"); you may not use
// this file except in compliance with the License.
//
// You may obtain a copy of the License, together with FAQs at
// https://www.defold.com/license
//
// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#import "ViewController.h"
#import "SceneDelegate.h"
#include "native.h"
#include "internal.h"

#import "MetalView.h"
#import "EAGLView.h"

extern int g_IsReboot;
extern UIWindow* g_ApplicationWindow;
static int g_view_type = NATIVE_NO_API;

#if TARGET_OS_TV
// Menu on the remote: tvOS goes home on it (as Apple asks of an app's first screen) unless the app handles it.
// With dmNativeSetMenuIsBack(1) it is the back key instead.
static int              g_MenuIsBack = 0;
// The presses handled as keys, so that their end is handled the same way as their start
static NSMutableSet*    g_KeyPresses = nil;

static int GetPressKey(UIPress* press)
{
    switch (press.type)
    {
        case UIPressTypeUpArrow:    return NATIVE_KEY_UP;
        case UIPressTypeDownArrow:  return NATIVE_KEY_DOWN;
        case UIPressTypeLeftArrow:  return NATIVE_KEY_LEFT;
        case UIPressTypeRightArrow: return NATIVE_KEY_RIGHT;
        case UIPressTypeSelect:     return NATIVE_KEY_ENTER;
        case UIPressTypeMenu:       return g_MenuIsBack ? NATIVE_KEY_BACK : -1;
        default:                    return -1;
    }
}

void dmNativeSetMenuIsBack(int on)
{
    g_MenuIsBack = on;
}
#endif

@implementation ViewController

@synthesize baseView;

#if !TARGET_OS_TV
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIWindow* window = self.viewIfLoaded.window;
    // A full-screen presentation detaches the root view from the game window.
    if (!window)
        window = g_ApplicationWindow;
    return dmNativeGetiOSSupportedInterfaceOrientations(window);
}
#endif

- (void)dealloc
{
    [baseView release];
    [super dealloc];
}

- (void)createView:(BOOL)recreate
{
    CGRect bounds = self.view.bounds;
    cachedViewSize = bounds.size;

    BaseView* oldBaseView = baseView;
    BaseView* newBaseView = 0;
    if (g_view_type == NATIVE_NO_API)
    {
        newBaseView = [MetalView createView: bounds recreate:recreate];
    }
    else
    {
        newBaseView = [EAGLView createView: bounds recreate:recreate];
    }

    if (!newBaseView)
    {
        return;
    }

    if (oldBaseView != newBaseView)
    {
        // A scheduled CADisplayLink retains its target, so removing the old view is not enough.
        [oldBaseView invalidateDisplayLink];
        [oldBaseView removeFromSuperview];
    }
    self.baseView = newBaseView;

    [[self view] insertSubview:baseView atIndex:0];
    [baseView setCurrentContext];
    [baseView startDisplayLink];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;

    dmNativeWin.viewController = self;

    [self createView:FALSE];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (dmNativeWin.clientAPI == NATIVE_OPENGL_API)
    {
        // According to Apple glFinish() should be called here (Comment moved from AppDelegate applicationWillResignActive)
        glFinish();
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // A 180-degree rotation can move reserved regions without changing size or insets.
        // Notify during event polling after UIKit has finished updating the geometry.
        self.baseView.safeAreaChanged = YES;
    }];
}

#if !TARGET_OS_TV
- (BOOL)shouldUpdateViewFrame
{
    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation orientation = device.orientation;
    bool update_parent_frame = false;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            update_parent_frame = true;
            break;
        case UIDeviceOrientationLandscapeRight:
            update_parent_frame = true;
            break;
        case UIDeviceOrientationPortrait:
            update_parent_frame = true;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            update_parent_frame = true;
            break;
        default:
            break;
    }
    return update_parent_frame;
}

- (CGSize)getIntendedViewSize
{
    CGSize result;
    CGRect parent_bounds = self.view.bounds;

    if (0 != g_IsReboot) {
        parent_bounds.size = cachedViewSize;
    }
    bool flipBounds = false;
    if (dmNativeWin.portrait) {
        flipBounds = parent_bounds.size.width > parent_bounds.size.height;
    } else {
        flipBounds = parent_bounds.size.width < parent_bounds.size.height;
    }
    if (flipBounds) {
        result.width = parent_bounds.size.height;
        result.height = parent_bounds.size.width;
    } else {
        result = parent_bounds.size;
    }
    return result;
}

- (CGPoint)getIntendedFrameOrigin:(CGSize)size
{
    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation orientation = device.orientation;
    CGPoint origin;
    origin.x = 0.0f;
    origin.y = 0.0f;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            break;
        case UIDeviceOrientationLandscapeRight:
            origin.x = -(size.width - size.height);
            origin.y = size.width - size.height;

            if (g_IsReboot && cachedViewSize.width != size.width) {
                origin.x = 0.0f;
                origin.y = 0.0f;
            }
            break;
        case UIDeviceOrientationPortrait:
            if (g_IsReboot && cachedViewSize.width != size.width) {
                origin.x = -(size.width - size.height);
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (g_IsReboot && cachedViewSize.width != size.width) {
                origin.y = (size.width - size.height);
            }
            break;
        default:
            break;
    }
    return origin;
}
#endif

- (void)viewDidAppear:(BOOL)animated
{
    [baseView setCurrentContext];

    [super viewDidAppear: animated];
}

#if !TARGET_OS_TV
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}
#else
// The remote's buttons (the Siri Remote, and a TV's own remote over HDMI-CEC or IR, which reaches tvOS only
// as presses) are keys. Presses that are not keys go on to tvOS.
- (void)pressesBegan:(NSSet<UIPress*>*)presses withEvent:(UIPressesEvent*)event
{
    if (!g_KeyPresses)
    {
        g_KeyPresses = [[NSMutableSet alloc] init];
    }
    NSMutableSet* other = [NSMutableSet set];
    for (UIPress* press in presses)
    {
        int key = GetPressKey(press);
        if (key < 0)
        {
            [other addObject:press];
            continue;
        }
        [g_KeyPresses addObject:press];
        dmNativeInputKey(key, NATIVE_PRESS);
    }
    if ([other count] > 0)
    {
        [super pressesBegan:other withEvent:event];
    }
}

- (void)endPresses:(NSSet<UIPress*>*)presses withEvent:(UIPressesEvent*)event cancelled:(BOOL)cancelled
{
    NSMutableSet* other = [NSMutableSet set];
    for (UIPress* press in presses)
    {
        if (![g_KeyPresses containsObject:press])
        {
            [other addObject:press];
            continue;
        }
        [g_KeyPresses removeObject:press];
        int key = GetPressKey(press);
        if (key < 0 && press.type == UIPressTypeMenu)
        {
            key = NATIVE_KEY_BACK; // Menu was made the back key while it was held
        }
        dmNativeInputKey(key, NATIVE_RELEASE);
    }
    if ([other count] > 0)
    {
        if (cancelled)
            [super pressesCancelled:other withEvent:event];
        else
            [super pressesEnded:other withEvent:event];
    }
}

- (void)pressesEnded:(NSSet<UIPress*>*)presses withEvent:(UIPressesEvent*)event
{
    [self endPresses:presses withEvent:event cancelled:NO];
}

- (void)pressesCancelled:(NSSet<UIPress*>*)presses withEvent:(UIPressesEvent*)event
{
    [self endPresses:presses withEvent:event cancelled:YES];
}
#endif

@end

static BOOL ViewTypeMatchesBaseView(int view_type, BaseView* view)
{
    if (!view)
    {
        return NO;
    }
    if (view_type == NATIVE_NO_API)
    {
        return [view isKindOfClass:[MetalView class]];
    }
    return [view isKindOfClass:[EAGLView class]];
}

void dmNativeOSSetViewType(int view_type)
{
    ViewController* viewController = (ViewController*) dmNativeWin.viewController;
    if (g_view_type == view_type &&
        (!viewController || ![viewController isViewLoaded] || ViewTypeMatchesBaseView(view_type, viewController.baseView)))
    {
        return;
    }

    g_view_type = view_type;

    if (viewController && [viewController isViewLoaded])
    {
        [viewController createView:FALSE];
    }
}

void dmNativeOSSetWindowBackgroundColor(unsigned int color)
{
    float r = (color & 0xff) / 255.0f;
    float g = ((color >> 8) & 0xff) / 255.0f;
    float b = ((color >> 16) & 0xff) / 255.0f;
    float a = 1.0f;
    UIViewController *viewController = (UIViewController*)dmNativeWin.viewController;
    viewController.view.backgroundColor = [[UIColor alloc]initWithRed:r green:g blue:b alpha:a];
}

float dmNativeOSGetDisplayScaleFactor()
{
    return 1.0f;
}

void* dmNativeOSAcquireAuxContext()
{
    if (dmNativeWin.clientAPI == NATIVE_NO_API)
    {
        dmNativeOSAcquireAuxContextVulkan();
    }
    else
    {
        dmNativeOSAcquireAuxContextOpenGL();
    }
    return 0;
}

void dmNativeOSUnacquireAuxContext(void* context)
{
    if (dmNativeWin.clientAPI == NATIVE_NO_API)
    {
        dmNativeOSUnacquireAuxContextVulkan(context);
    }
    else
    {
        dmNativeOSUnacquireAuxContextOpenGL(context);
    }
}

int dmNativeOSQueryAuxContext()
{
    if (dmNativeWin.clientAPI == NATIVE_NO_API)
    {
        return dmNativeOSQueryAuxContextVulkan();
    }
    else
    {
        return dmNativeOSQueryAuxContextOpenGL();
    }
}

int  dmNativeOSOpenWindow( int width, int height,
                              const Nativewndconfig *wndconfig,
                              const Nativefbconfig *fbconfig )
{
    dmNativeOSSetViewType(wndconfig->clientAPI);

    if (wndconfig->clientAPI == NATIVE_NO_API)
    {
        return dmNativeOSOpenWindowVulkan(width, height, wndconfig, fbconfig);
    }
    else
    {
        return dmNativeOSOpenWindowOpenGL(width, height, wndconfig, fbconfig);
    }
}
