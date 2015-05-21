// light@huohua.tv
#import "NSString+HHKit.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (HHKit)

- (NSString *)trim
{
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    return [self stringByTrimmingCharactersInSet:set];
}

- (NSString *)md5
{
    const char      *concat_str = [self UTF8String];
    unsigned char   result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(concat_str, (CC_LONG)strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    
    for (int i = 0; i < 16; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    
    return [hash lowercaseString];
}

- (NSString *)stringByUppercaseFirstLetter
{
    NSString *firstLetter = [self substringToIndex:1];
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[firstLetter uppercaseString]];
}

- (NSString *)stringByEncodeURIComponent
{
    NSString *s = [self copy];
    s = [s stringByReplacingOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    return s;
}

- (NSString *)stringByDecodeURIComponent
{
    NSString *s = [self copy];
    s = [s stringByReplacingOccurrencesOfString:@"%3F" withString:@"?" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@"%3D" withString:@"=" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@"%3A" withString:@":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    s = [s stringByReplacingOccurrencesOfString:@"%2F" withString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, s.length)];
    return s;
}

@end