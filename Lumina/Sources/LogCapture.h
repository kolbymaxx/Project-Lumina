#import <Foundation/Foundation.h>

@interface LogCapture : NSObject
+ (instancetype)shared;
- (void)startRedirectingToFile;
- (NSString *)drainFileContents;
@end
