//
//  UIView+TUSignal.m
//
//  Created by Jason on 2020/3/16.
//

#import "UIView+TUSignal.h"
#import <objc/message.h>

typedef void(^DeallocBlock)(void);
@interface TUOrignalObject : NSObject
@property(nonatomic,copy)DeallocBlock block;
-(instancetype)initWithBlock:(DeallocBlock)block;
@end
@implementation TUOrignalObject
-(instancetype)initWithBlock:(DeallocBlock)block{
    if (self = [super init]) {
        self.block = block;
    }
    return self;
}
-(void)dealloc{
    self.block ? self.block():nil;
}
@end

@interface UIView ()
@property(nonatomic,assign,getter=isTrigger)BOOL trigger;
@property(nonatomic,assign)NSIndexPath *innerIndexPath;
@property(nonatomic,weak)UITableView *tableView;
@property(nonatomic,weak)UICollectionView *collectionView;
@property(nonatomic,weak)NSObject *targetObject;
@property(nonatomic,strong)NSString *repeatedSignalName;
@property(nonatomic,weak)UIViewController *tu_ViewController;
@property(nonatomic,assign,getter=isAchieve)BOOL achieve;
@end

static NSString const *haveSignal = @"TUSignal_";
static UIControlEvents allEventControls = -1;
@implementation UIView (TUSignal)
-(void)setAchieve:(BOOL)achieve{
    objc_setAssociatedObject(self, @selector(isAchieve), @(achieve), OBJC_ASSOCIATION_ASSIGN);
}

-(BOOL)isAchieve{
    return [objc_getAssociatedObject(self, @selector(isAchieve)) boolValue];
}

-(void)setAllControlEvents:(UIControlEvents)allControlEvents{
    if ([self isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)self;
        if (self.isAchieve) {
            if (allControlEvents != allEventControls) {
                [control removeTarget:self action:@selector(didEvent:) forControlEvents:allControlEvents];
                [control addTarget:self action:@selector(didEvent:) forControlEvents:allControlEvents];
            }
        }else{
            self.achieve = YES;
            [control addTarget:self action:@selector(didEvent:) forControlEvents:allControlEvents];
        }
    }
    
    objc_setAssociatedObject(self, @selector(allControlEvents), @(allControlEvents), OBJC_ASSOCIATION_ASSIGN);
}

-(UIControlEvents)allControlEvents{
    return [objc_getAssociatedObject(self, @selector(allControlEvents)) integerValue];
}

-(void)setClickSingalName:(NSString *)clickSingalName{
    objc_setAssociatedObject(self, @selector(clickSingalName), clickSingalName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.userInteractionEnabled = YES;
    if ([self isKindOfClass:[UIControl class]]) {
        if (!self.isAchieve) {
            UIControl *control = (UIControl *)self;
            self.achieve = YES;
            allEventControls = [self eventControlWithInstance:self];
            [control addTarget:self action:@selector(didEvent:) forControlEvents:allEventControls];
        }
    }
}

#warning code here
#pragma did action
-(void)didEvent:(UIControl *)control{
    if (self.clickSingalName == nil) {
        NSString *name = [self dymaicSignalName];
        if (name.length <= 0) {
            self.clickSingalName = name;
        }else{
            self.clickSingalName = name;
        }
    }
    if (self.clickSingalName.length <= 0) {
        return;
    }
    [self sendSignal];
}


static BOOL forceRefreshTU = NO;
-(void)sendSignal{
    if (self.repeatedSignalName.length <= 0) {
        self.clickSingalName = [haveSignal stringByAppendingString:self.clickSingalName];
        self.clickSingalName = [NSString stringWithFormat:@"%@:",self.clickSingalName];
        self.repeatedSignalName = self.clickSingalName;
    }
    if (self.repeatedSignalName.length <= 0) {
        return;
    }
    void(*action)(id,SEL,id) = (void(*)(id,SEL,id))objc_msgSend;
    if (forceRefreshTU) {
        self.tu_ViewController = nil;
        forceRefreshTU = NO;
    }
    if (!self.tu_ViewController) {
        [self getViewControllerFromCurrentView];
    }
    SEL selector = NSSelectorFromString(self.repeatedSignalName);
    if ([self.targetObject respondsToSelector:selector]) {
        action(self.targetObject,selector,self);
        return;
    }
    
    if (self.tableView && self.indexPath) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
        if (cell && [cell respondsToSelector:selector]) {
            action(cell,selector,self);
            return;
        }
    }
    if (self.collectionView && self.indexPath) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.indexPath];
        if (cell && [cell respondsToSelector:selector]) {
            action(cell,selector,self);
            return;
        }
    }
    
    if ([self.tu_ViewController respondsToSelector:selector]) {
        action(self.tu_ViewController,selector,self);
    }
}

-(void)getViewControllerFromCurrentView{
    UIResponder *nextResponder = self.nextResponder;
    while (nextResponder != nil) {
        if ([nextResponder isKindOfClass:[UINavigationController class]]) {
            self.tu_ViewController = nil;
            break;
        }
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            self.tu_ViewController = (UIViewController *)nextResponder;
            break;
        }else if ([nextResponder isKindOfClass:[UITableViewCell class]]||
                  [nextResponder isKindOfClass:[UICollectionViewCell class]]){
            self.innerIndexPath = [self indexPathForCellWithId:nextResponder];
        }
        nextResponder = nextResponder.nextResponder;
    }
}

#pragma -mark indexPathFromCellWithId
-(NSIndexPath *)indexPathForCellWithId:(id)subViews{
    NSIndexPath *indexPath;
    if ([subViews isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)subViews;
        if (@available(iOS 11.0,*)) {
            UITableView *tableView = (UITableView *)cell.superview;
            indexPath = [tableView indexPathForCell:cell];
            self.tableView = tableView;
        }
    }else{
        UICollectionViewCell *cell = (UICollectionViewCell *)subViews;
        UICollectionView *collectionView = (UICollectionView *)cell.superview;
        indexPath = [collectionView indexPathForCell:cell];
        self.collectionView = collectionView;
    }
    return indexPath;
}

#pragma mark- touch events handle
-(NSString *)nameWithInstance:(id)instance responder:(UIResponder *)responder{
    unsigned int numIvars = 0;
    NSString *key = nil;
    Ivar *ivars = class_copyIvarList([responder class], &numIvars);
    for (int i = 0; i < numIvars; i++) {
        Ivar thisIvar = ivars[i];
        const char *type = ivar_getTypeEncoding(thisIvar);
        NSString *stringType = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        if (![stringType hasPrefix:@"@"] || ![object_getIvar(responder, thisIvar) isKindOfClass:[UIView class]]) {
            continue;
        }
        
        if ((object_getIvar(responder, thisIvar) == instance)) {
            key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
            break;
        }else{
            key = @"";
        }
    }
    
    free(ivars);
    return key;
}

-(NSString *)dymaicSignalName{
    NSString *name = @"";
    if ([self isKindOfClass:[UITableViewCell class]]||
        [self isKindOfClass:[UICollectionViewCell class]]||
        [self isKindOfClass:NSClassFromString(@"UITableViewWrapperView")]||
        [NSStringFromClass([self class]) isEqualToString:@"UITableViewCellContentView"]||
        [NSStringFromClass([self class]) isEqualToString:@"UICollectionViewCellContentView"]) {
        return name;
    }
    
    UIResponder *nexResponder = self.nextResponder;
    while (nexResponder != nil) {
        if ([nexResponder isKindOfClass:[UINavigationController class]]) {
            self.tu_ViewController = nil;
            break;
        }
        if ([nexResponder isKindOfClass:[UIViewController class]]) {
            self.tu_ViewController = (UIViewController *)nexResponder;
            name = [self nameWithInstance:self responder:nexResponder];
            if (name.length > 0) {
                name = [name substringFromIndex:1];
                return name;
            }
            break;
        }
        if ([nexResponder isKindOfClass:NSClassFromString(@"UIKeyboardCandidateBarCell")]||
            [nexResponder isKindOfClass:NSClassFromString(@"PUPhotosGridCell")]) {
            return name;
        }
        name = [self nameWithInstance:self responder:nexResponder];
        if (name.length > 0) {
            name = [name substringFromIndex:1];
            NSString *selectorString = [haveSignal stringByAppendingString:name];
            selectorString = [NSString stringWithFormat:@"%@:",selectorString];
            if ([nexResponder respondsToSelector:NSSelectorFromString(selectorString)]) {
                self.enforceTarget(nexResponder);
            }
            return name;
        }
        nexResponder = nexResponder.nextResponder;
    }
    return name;
}

#pragma mark enforce to target
-(UIView *(^)(NSObject *))enforceTarget{
    __weak typeof(self)weakSelf = self;
    return ^(NSObject *target){
        __weak typeof(target)weakTarget = target;
        weakSelf.targetObject = weakTarget;
        return weakSelf;
    };
}

-(void)setEnforceTarget:(UIView * _Nonnull (^)(NSObject * _Nonnull))enforceTarget{
    objc_setAssociatedObject(self, @selector(enforceTarget), enforceTarget, OBJC_ASSOCIATION_ASSIGN);
}


-(void)setControlEvents:(UIView * _Nonnull (^)(UIControlEvents))controlEvents{
    objc_setAssociatedObject(self, @selector(controlEvents), controlEvents, OBJC_ASSOCIATION_ASSIGN);
}
-(UIView *(^)(UIControlEvents))controlEvents{
    __weak typeof(self)weakSelf = self;
    return ^(UIControlEvents event){
        weakSelf.allControlEvents = event;
        return weakSelf;
    };
}


-(void)TUTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.clickSingalName.length <= 0) {
        NSString *name = [self dymaicSignalName];
        if (name.length > 0) {
            self.clickSingalName = name;
            UITouch *touch = [touches anyObject];
            CGPoint point = [touch locationInView:self];
            self.trigger = [self pointInside:point withEvent:event];
            if (self.isTrigger && ![self isKindOfClass:[UIControl class]]) {
                [self sendSignal];
            }
        }
    }else{
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        self.trigger = [self pointInside:point withEvent:event];
        if (self.isTrigger && ![self isKindOfClass:[UIControl class]]) {
            [self sendSignal];
        }
    }
}

#pragma mark -confirgure allEventControls
-(UIControlEvents)eventControlWithInstance:(UIView *)instance{
    if (![instance isKindOfClass:[UIButton class]]) {
        if ([instance isKindOfClass:[UITextField class]]) {
            return UIControlEventEditingChanged;
        }else{
            return UIControlEventValueChanged;
        }
    }else{
        return UIControlEventTouchUpInside;
    }
    return -1;
}

#pragma -mark tu_viewController
-(void)setTu_ViewController:(UIViewController *)tu_ViewController{
    TUOrignalObject *ob = [[TUOrignalObject alloc] initWithBlock:^{
        objc_setAssociatedObject(self, @selector(tu_ViewController), nil, OBJC_ASSOCIATION_ASSIGN);
        if (tu_ViewController) {
            objc_setAssociatedObject(tu_ViewController, (__bridge const void*)(ob.block), ob, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }else{
            ob.block();
        }
        objc_setAssociatedObject(self , @selector(tu_ViewController), tu_ViewController, OBJC_ASSOCIATION_ASSIGN);
    }];
}

-(UIViewController *)tu_ViewController{
    return objc_getAssociatedObject(self, _cmd);
}

-(id)viewController{
    if (!self.tu_ViewController) {
        [self getViewControllerFromCurrentView];
    }
    return self.tu_ViewController;
}

-(void)setTrigger:(BOOL)trigger{
    objc_setAssociatedObject(self, @selector(isTrigger), [NSNumber numberWithBool:trigger], OBJC_ASSOCIATION_ASSIGN);
}

-(BOOL)isTrigger{
    return [objc_getAssociatedObject(self, @selector(isTrigger)) boolValue];
}

-(void)setInnerIndexPath:(NSIndexPath *)innerIndexPath{
     objc_setAssociatedObject(self, @selector(innerIndexPath), innerIndexPath, OBJC_ASSOCIATION_ASSIGN);
}

-(void)setRepeatedSignalName:(NSString *)repeatedSignalName{
    objc_setAssociatedObject(self, @selector(repeatedSignalName), repeatedSignalName, OBJC_ASSOCIATION_COPY);
}

-(NSString *)repeatedSignalName{
    return objc_getAssociatedObject(self, @selector(repeatedSignalName));
}

-(NSIndexPath *)innerIndexPath{
    return objc_getAssociatedObject(self, @selector(innerIndexPath));
}

-(NSIndexPath *)indexPath{
    return self.innerIndexPath;
}

-(void)setTableView:(UITableView *)tableView{
    TUOrignalObject *ob = [[TUOrignalObject alloc] initWithBlock:^{
        objc_setAssociatedObject(self, @selector(tableView), nil, OBJC_ASSOCIATION_ASSIGN);
    }];
    
    if (tableView) {
        objc_setAssociatedObject(tableView, (__bridge const void *)(ob.block), ob, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, @selector(tableView), tableView, OBJC_ASSOCIATION_ASSIGN);
}

-(UITableView *)tableView{
    return objc_getAssociatedObject(self, @selector(tableView));
}

-(void)setCollectionView:(UICollectionView *)collectionView{
   TUOrignalObject *ob = [[TUOrignalObject alloc] initWithBlock:^{
        objc_setAssociatedObject(self, @selector(collectionView), nil, OBJC_ASSOCIATION_ASSIGN);
    }];
    
    if (collectionView) {
        objc_setAssociatedObject(collectionView, (__bridge const void *)(ob.block), ob, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, @selector(collectionView), collectionView, OBJC_ASSOCIATION_ASSIGN);
}
-(UICollectionView *)collectionView{
    return objc_getAssociatedObject(self, @selector(collectionView));
}

-(void)setTargetObject:(NSObject *)targetObject{
    TUOrignalObject *ob = [[TUOrignalObject alloc] initWithBlock:^{
           objc_setAssociatedObject(self, @selector(targetObject), nil, OBJC_ASSOCIATION_ASSIGN);
       }];
       
       if (targetObject) {
           objc_setAssociatedObject(targetObject, (__bridge const void *)(ob.block), ob, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
       }
    objc_setAssociatedObject(self, @selector(targetObject), targetObject, OBJC_ASSOCIATION_ASSIGN);
}

-(NSObject *)targetObject{
    return objc_getAssociatedObject(self, @selector(targetObject));
}


#pragma mark - signal name
-(UIView *(^)(NSString *))setSignalName{
    __weak typeof(self)weakSelf = self;
    return ^(NSString *signalName){
        weakSelf.clickSingalName = signalName;
        return weakSelf;
    };
}

-(void)setSetSignalName:(UIView * _Nonnull (^)(NSString * _Nonnull))setSignalName{
    objc_setAssociatedObject(self, @selector(setSetSignalName:), setSignalName, OBJC_ASSOCIATION_ASSIGN);
}

@end


