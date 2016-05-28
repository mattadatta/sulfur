/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

#import <UIKit/UIKit.h>

@protocol ConfigurableStoryboardDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ConfigurableStoryboard : UIStoryboard

+ (ConfigurableStoryboard *)storyboardWithName:(NSString *)name
                                        bundle:(nullable NSBundle *)storyboardBundleOrNil
                                      delegate:(id<ConfigurableStoryboardDelegate>)delegate;

@property (nonatomic, readonly) id<ConfigurableStoryboardDelegate> delegate;

@end

@protocol ConfigurableStoryboardDelegate <NSObject>

- (void)configureViewController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
