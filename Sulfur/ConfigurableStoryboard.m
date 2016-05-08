/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

#import "ConfigurableStoryboard.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigurableStoryboard ()

@property (nonatomic, weak) id<ConfigurableStoryboardDelegate> delegate;

@end

@implementation ConfigurableStoryboard

+ (ConfigurableStoryboard *)storyboardWithName:(NSString *) name bundle:(nullable NSBundle *)storyboardBundleOrNil delegate:(id<ConfigurableStoryboardDelegate>)delegate {
    ConfigurableStoryboard *storyboard = (id) [super storyboardWithName:name bundle:storyboardBundleOrNil];
    storyboard.delegate = delegate;
    return storyboard;
}

- (UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier {
    UIViewController *viewController = [super instantiateViewControllerWithIdentifier:identifier];
    [self.delegate configureViewController:viewController];
    return viewController;
}

@end

NS_ASSUME_NONNULL_END
