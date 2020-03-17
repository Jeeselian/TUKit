//
//  TUSignal.h
//  Pods
//
//  Created by GFB on 2020/3/16.
//

#ifndef TUSignal_h
#define TUSignal_h
#import "UIView+TUSignal.h"
#import "UIApplication+TUSignal.h"
#undef Click_TUSignal
#define Click_TUSignal(SignalName) \
-(void)TUSignal_##SignalName:(id)object

#endif /* TUSignal_h */
