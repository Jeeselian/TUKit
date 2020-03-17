//
//  UIView+TUSignal.h
//
//  Created by Jason on 2020/3/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (TUSignal)

@property(nonatomic,weak,readonly)UIViewController* viewController;

@property(nonatomic,copy)IBInspectable NSString *clickSingalName;

@property(nonatomic,assign)UIControlEvents allControlEvents;

@property(nonatomic,readonly)NSIndexPath *indexPath;

@property(nonatomic,assign)UIView *(^setSignalName)(NSString *signalName);

@property(nonatomic,assign)UIView *(^enforceTarget)(NSObject *target);

@property(nonatomic,assign)UIView *(^controlEvents)(UIControlEvents event);

-(void)forceRefresh;
@end

@interface NSObject (TUSignal)
-(void)sendSignal:(NSString *)signalName target:(NSObject *)target object:(id)object;
-(void)sendSignal:(NSString *)signalName target:(NSObject *)target;
@end

NS_ASSUME_NONNULL_END
