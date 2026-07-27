//
//  STPFormEncoder.m
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormEncoder.h"
#import "STPBankAccountParams.h"
#import "STPCardParams.h"

FOUNDATION_EXPORT NSString * STPPercentEscapedStringFromString(NSString *string);
FOUNDATION_EXPORT NSString * STPQueryStringFromParameters(NSDictionary *parameters);

@implementation STPFormEncoder

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    NSArray *parts = [input componentsSeparatedByString:@"_"];
    NSMutableString *camelCaseParam = [NSMutableString string];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        [camelCaseParam appendString:(idx == 0 ? part : [part capitalizedString])];
    }];
    
    return [camelCaseParam copy];
}

+ (NSData *)formEncodedDataForObject:(NSObject<STPFormEncodable> *)object {
    NSDictionary *keyPairs = [self keyPairDictionaryForObject:object];
    NSString *rootObjectName = [object.class rootObjectName];
    NSDictionary *dict = rootObjectName != nil ? @{ rootObjectName: keyPairs } : keyPairs;
    return [STPQueryStringFromParameters(dict) dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)keyPairDictionaryForObject:(NSObject<STPFormEncodable> *)object {
    NSMutableDictionary *keyPairs = [NSMutableDictionary dictionary];
    [[object.class propertyNamesToFormFieldNamesMapping] enumerateKeysAndObjectsUsingBlock:^(NSString * propertyName, NSString * formFieldName, __unused BOOL * stop) {
        id value = [self formEncodableValueForObject:[object valueForKey:propertyName]];
        if (value) {
            keyPairs[formFieldName] = value;
        }
    }];
    [object.additionalAPIParameters enumerateKeysAndObjectsUsingBlock:^(id additionalFieldName, id additionalFieldValue, __unused BOOL * stop) {
        id value = [self formEncodableValueForObject:additionalFieldValue];
        if (value) {
            keyPairs[additionalFieldName] = value;
        }
    }];
    return [keyPairs copy];
}

+ (id)formEncodableValueForObject:(NSObject *)object {
    if ([object conformsToProtocol:@protocol(STPFormEncodable)]) {
        return [self keyPairDictionaryForObject:(NSObject<STPFormEncodable>*)object];
    } else {
        return object;
    }
}

+ (NSString *)stringByURLEncoding:(NSString *)string {
    return STPPercentEscapedStringFromString(string);
}

+ (NSString *)queryStringFromParameters:(NSDictionary *)parameters {
    return STPQueryStringFromParameters(parameters);
}

@end


// This code is adapted from https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLRequestSerialization.m . The only modifications are to replace the AF namespace with the STP namespace to avoid collisions with apps that are using both Stripe and AFNetworking.
NSString * STPPercentEscapedStringFromString(NSString *string) {
    static NSString * const kSTPCharactersToEncode = @":/?#[]@!$&'()*+,;=";
    NSMutableString *escaped = [[NSMutableString alloc] init];
    static NSUInteger const batchSize = 50;
    NSUInteger index = 0;
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        NSString *substring = [string substringWithRange:range];
        CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)substring, NULL, (__bridge CFStringRef)kSTPCharactersToEncode, kCFStringEncodingUTF8);
        if (encoded != NULL) {
            [escaped appendString:(__bridge_transfer NSString *)encoded];
        }
        index += range.length;
    }
    return escaped;
}
#pragma mark -

@interface STPQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation STPQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _field = field;
    _value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return STPPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", STPPercentEscapedStringFromString([self.field description]), STPPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -

FOUNDATION_EXPORT NSArray * STPQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * STPQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * STPQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (STPQueryStringPair *pair in STPQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * STPQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return STPQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * STPQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    NSString *descriptionSelector = NSStringFromSelector(@selector(description));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:descriptionSelector ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[STPQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}
