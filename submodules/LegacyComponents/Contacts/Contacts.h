#import <Foundation/Foundation.h>

typedef NSInteger CNContactFormatterStyle;
#define CNContactFormatterStyleFullName 0

@interface CNPhoneNumber : NSObject
+ (instancetype)phoneNumberWithStringValue:(NSString *)stringValue;
- (instancetype)initWithStringValue:(NSString *)stringValue;
@property (nonatomic, copy) NSString *stringValue;
@end

@interface CNLabeledValue : NSObject
+ (instancetype)labeledValueWithLabel:(NSString *)label value:(id)value;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, retain) id value;
@end

@interface CNMutablePostalAddress : NSObject
@property (nonatomic, copy) NSString *street;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *postalCode;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *ISOCountryCode;
@end

@interface CNMutableContact : NSObject
@property (nonatomic, copy) NSString *givenName;
@property (nonatomic, copy) NSString *familyName;
@property (nonatomic, copy) NSArray *phoneNumbers;
@property (nonatomic, copy) NSArray *postalAddresses;
@end

@interface CNContactVCardSerialization : NSObject
+ (NSData *)dataWithContacts:(NSArray *)contacts error:(NSError **)error;
@end

@interface CNContactFormatter : NSObject
+ (NSString *)stringFromContact:(CNMutableContact *)contact style:(CNContactFormatterStyle)style;
@end
