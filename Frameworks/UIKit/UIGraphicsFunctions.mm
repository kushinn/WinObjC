//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#include "Starboard.h"
#include "UIKit/UIKit.h"
#include "CGContextInternal.h"

#define MAX_CONTEXT_DEPTH 128
__declspec(thread) CGContextRef _currentCGContext[MAX_CONTEXT_DEPTH];
__declspec(thread) int _currentCGContextDepth;

/**
 @Status Interoperable
*/
void UIGraphicsPushContext(CGContextRef context) {
    if (_currentCGContextDepth >= MAX_CONTEXT_DEPTH - 1) {
        assert(0);
        return;
    }

    CGContextRetain(context);
    _currentCGContext[++(_currentCGContextDepth)] = context;
}

/**
 @Status Interoperable
*/
void UIGraphicsPopContext() {
    if (_currentCGContextDepth <= 0) {
        assert(0);
        return;
    }
    CGContextRelease(_currentCGContext[_currentCGContextDepth]);
    _currentCGContext[_currentCGContextDepth] = nullptr;
    _currentCGContextDepth--;
}

/**
 @Status Interoperable
*/
CGContextRef UIGraphicsGetCurrentContext() {
    return _currentCGContext[_currentCGContextDepth];
}

/**
 @Status Caveat
 @Notes opaque parameter not supported
*/
void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, float scale) {
    if (scale == 0.0f) {
        scale = GetCACompositor()->screenScale();
    }
    CGContextRef newCtx = CGBitmapContextCreate32((int)(size.width * scale), (int)(size.height * scale));
    newCtx->scale = scale;
    CGContextTranslateCTM(newCtx, 0.0f, size.height * scale);
    CGContextScaleCTM(newCtx, scale, scale);
    CGContextScaleCTM(newCtx, 1.0f, -1.0f);

    UIGraphicsPushContext(newCtx);
}

/**
 @Status Interoperable
*/
void UIGraphicsBeginImageContext(CGSize size) {
    UIGraphicsBeginImageContextWithOptions(size, FALSE, 1.0f);
}

/**
 @Status Interoperable
*/
UIImage* UIGraphicsGetImageFromCurrentImageContext() {
    id ret = [UIImage imageWithCGImage:CGBitmapContextGetImage(UIGraphicsGetCurrentContext())
                                 scale:UIGraphicsGetCurrentContext()->scale
                           orientation:UIImageOrientationUp];

    return ret;
}

/**
 @Status Interoperable
*/
void UIGraphicsEndImageContext() {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIGraphicsPopContext();
    CGContextRelease(ctx);
}

/**
 @Status Interoperable
*/
void UIRectFill(CGRect rect) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextFillRect(ctx, rect);
}

/**
 @Status Stub
*/
void UIRectFrame(CGRect rect) {
    UNIMPLEMENTED();
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextFillRect(ctx, rect);
    EbrDebugLog("UIRectFrame not supported\n");
}

/**
 @Status Interoperable
*/
void UIRectClip(CGRect clip) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextClipToRect(ctx, clip);
}

/**
 @Status Interoperable
*/
void UIRectFillUsingBlendMode(CGRect rect, CGBlendMode mode) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGBlendMode oldBlend = CGContextGetBlendMode(ctx);
    CGContextSetBlendMode(ctx, mode);
    CGContextFillRect(ctx, rect);
    CGContextSetBlendMode(ctx, oldBlend);
}

/**
 @Status Interoperable
*/
NSString* NSStringFromCGPoint(CGPoint p) {
    return [NSString stringWithFormat:@"{%f,%f}", p.x, p.y];
}

/**
 @Status Interoperable
*/
NSString* NSStringFromCGSize(CGSize s) {
    return [NSString stringWithFormat:@"{%f,%f}", s.width, s.height];
}

/**
 @Status Interoperable
*/
NSString* NSStringFromCGRect(CGRect r) {
    return [NSString stringWithFormat:@"{{%f, %f}, {%f, %f}}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}
