#import "LogCapture.h"
#include <stdio.h>

@interface LogCapture ()
@property (nonatomic, copy) NSString *path;
@end

@implementation LogCapture

+ (instancetype)shared
{
    static LogCapture *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[LogCapture alloc] init]; });
    return s;
}

- (void)startRedirectingToFile
{
    self.path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"lumina-dsk.log"];
    [[NSFileManager defaultManager] createFileAtPath:self.path contents:nil attributes:nil];
    freopen(self.path.fileSystemRepresentation, "w+", stdout);
    freopen(self.path.fileSystemRepresentation, "a+", stderr);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
}

- (NSString *)drainFileContents
{
    if (!self.path) {
        return @"";
    }
    fflush(stdout);
    fflush(stderr);
    NSError *err = nil;
    NSString *s = [NSString stringWithContentsOfFile:self.path
                                            encoding:NSUTF8StringEncoding
                                               error:&err];
    return s ?: (err.localizedDescription ?: @"");
}

@end
