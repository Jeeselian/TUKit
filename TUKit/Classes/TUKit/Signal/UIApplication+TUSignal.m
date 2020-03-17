//
//  UIApplication+TUSignal.m
//  TUTest
//
//  Created by Jason on 2020/3/13.
//  Copyright © 2020 Jason. All rights reserved.
//   

#import "UIApplication+TUSignal.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation UIApplication (TUSignal)
+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL safeSel = @selector(sendEvent:);
        SEL unsafeSel = @selector(TUSignal_sendEvent:);
        Class myClass = [self class];
        Method safeMethod = class_getInstanceMethod(myClass, safeSel);
        Method unsafeMethod = class_getInstanceMethod(myClass, unsafeSel);
        method_exchangeImplementations(unsafeMethod, safeMethod);
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (void)TUSignal_sendEvent:(UIEvent *)event{
    NSSet *set = event.allTouches;
    NSArray *array = [set allObjects];
    UITouch *touchEvent = [array lastObject];
    UIView *view = [touchEvent view];
    if ([NSStringFromClass([view.superview class]) containsString:@"UISwitch"]){
        if (!(view.superview.superview.userInteractionEnabled == NO || view.superview.superview.hidden == YES || view.superview.superview.alpha <= 0.01)) {
            void(*action)(id,SEL,id,id) = (void(*)(id,SEL,id,id))objc_msgSend; action(view.superview.superview,@selector(TUTouchesEnded:withEvent:),set,event);
        }
    }
    
    if (touchEvent.phase == UITouchPhaseEnded) {
        CGPoint point = [touchEvent locationInView:view];
        UIView *fitview = [self hitTest:point withEvent:event withView:view];
        
        if (fitview) {
            void(*action)(id,SEL,id,id) = (void(*)(id,SEL,id,id))objc_msgSend;
            if ([NSStringFromClass([fitview class]) isEqualToString:@"_UITableViewHeaderFooterContentView"]) {
                action(fitview.superview,@selector(TUTouchesEnded:withEvent:),set,event);
            }else{
                action(fitview,@selector(TUTouchesEnded:withEvent:),set,event);
            }
        }
    }
    [self TUSignal_sendEvent:event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event withView:(UIView *)view{
    if (view.userInteractionEnabled == NO || view.hidden == YES || view.alpha <= 0.01)return nil;
    if ([view pointInside:point withEvent:event] == NO) return nil;
    if ([view isKindOfClass:[UIStepper class]]) return view;
    
    NSInteger count = view.subviews.count;
    for (NSInteger i = count - 1; i >= 0; i--) {
        UIView *sonView = view.subviews[i];
        CGPoint sonPoint = [view convertPoint:point toView:sonView];
        UIView *fitView = [sonView hitTest:sonPoint withEvent:event];
        if (fitView && !(fitView.userInteractionEnabled == NO || fitView.hidden == YES || fitView.alpha <= 0.01)) {
            return fitView;
        }
    }
    return view;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    
    return YES;
}
@end
