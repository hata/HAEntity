//
//  HABaseEntityTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#include <limits.h>
#import "HABaseEntityTest.h"
#import "HABaseEntity.h"
#import "HATableEntity.h"
#import "HATableEntityMigration.h"



@interface HATestDataMock : HATableEntity {
@private
    NSInteger integerProp;
    NSUInteger uintegerProp;
    long longProp;
    long long longlongProp;
    char charProp;
    short shortProp;

    unsigned char ucharProp;
    unsigned short ushortProp;
    unsigned int uintProp;
    unsigned long ulongProp;
    unsigned long long ulonglongProp;
    
    float floatProp;
    double doubleProp;
    
    bool boolProp;
    
    NSString* stringProp;
    NSDate* dateProp;
    NSData* dataProp;
}

@property NSInteger integerProp;
@property NSUInteger uintegerProp;

@property long longProp;
@property long long longlongProp;

@property char charProp;
@property short shortProp;

@property unsigned char ucharProp;
@property unsigned short ushortProp;
@property unsigned int uintProp;
@property unsigned long ulongProp;
@property unsigned long long ulonglongProp;

@property float floatProp;
@property double doubleProp;

@property bool boolProp;

@property NSString* stringProp;
@property NSDate* dateProp;
@property NSData* dataProp;

@end

@implementation HATestDataMock

@synthesize integerProp;
@synthesize uintegerProp;

@synthesize longProp;
@synthesize longlongProp;

@synthesize charProp;
@synthesize shortProp;

@synthesize ucharProp;
@synthesize ushortProp;
@synthesize uintProp;
@synthesize ulongProp;
@synthesize ulonglongProp;

@synthesize floatProp;
@synthesize doubleProp;

@synthesize boolProp;

@synthesize stringProp;
@synthesize dateProp;
@synthesize dataProp;


+ (NSString*) tableName
{
    return @"test_data";
}

@end


@interface HATestSample1 : HATableEntity {
@private
    NSInteger numValue;
}

+ (NSString*) tableName;

@property NSInteger numValue;

@end

@implementation HATestSample1

@synthesize numValue;

+ (NSString*)tableName
{
    return @"test_table1";
}

@end

@interface HATestSample2 : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
}

+ (NSString*) tableName;

@property NSInteger numValue;
@property NSString* stringValue;
@end

@implementation HATestSample2

@synthesize numValue;
@synthesize stringValue;

+ (NSString*)tableName
{
    return @"test_table1";
}

@end




@interface HATestSample3 : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
    
}

+ (NSString*) tableName;

@property NSInteger numValue;
@property NSString* stringValue;

+ (BOOL) isMethodsCalled;

@end

@implementation HATestSample3

static BOOL unprepareIsCalled = FALSE;


@synthesize numValue;
@synthesize stringValue;

+ (NSString*)tableName
{
    return @"test_table3";
}

+ (void) unprepareEntity:(FMDatabase*)database
{
    unprepareIsCalled = TRUE;
}

+ (BOOL) isMethodsCalled
{
    return unprepareIsCalled;
}


@end



@interface HATestSample4 : HATableEntity {
@private
    NSNumber* numberValue;
}

+ (NSString*) tableName;

@property NSNumber* numberValue;

@end

@implementation HATestSample4

@dynamic numberValue;

+ (NSString*)tableName
{
    return @"test_table4";
}

+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName
{
    return [NSString stringWithFormat:@"%@C", propertyName];
}

+ (NSString*) convertColumnToPropertyName:(NSString*) columnName
{
    return [NSString stringWithFormat:@"%@P", columnName];
}
@end





#pragma mark -
#pragma mark HABaseEntityTest

@implementation HABaseEntityTest

- (void)setUp
{
    [super setUp];

    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HABaseEntityTest.sqlite"];
    [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses:[HATestDataMock class], [HATestSample1 class], [HATestSample3 class], nil];
    [[HAEntityManager instance] up:2 migratings:migration, nil];
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instance] remove];
    
    NSError* error;
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:dbFilePath]) {
        [manager removeItemAtPath:dbFilePath error:&error];
    }
    if (error) {
        NSLog(@"Delete test file error %@", error);
    }
    
    [super tearDown];
}



- (void)testSelectPrefixForHATestSample1
{
    NSString* select = [NSString stringWithFormat:@"SELECT rowid, numValue FROM %@", [HATestSample1 tableName]];
    STAssertEqualObjects(select, [HATestSample1 selectPrefix], @"Verify SELECT prefix.");
}

- (void)testSelectPrefixForHATestSample3
{
    NSString* select = [NSString stringWithFormat:@"SELECT rowid, numValue, stringValue FROM %@", [HATestSample3 tableName]];
    STAssertEqualObjects(select, [HATestSample3 selectPrefix], @"Verify SELECT prefix.");
}


- (void)testColumnNamesForHATestSample1
{
    NSArray* columnNames = [HATestSample1 columnNames];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue", names, @"Verify columns");
}

- (void)testColumnNamesForHATestSample3
{
    NSArray* columnNames = [HATestSample3 columnNames];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue,stringValue", names, @"Verify columns");
}

- (void)testColumnNamesForHATestSample4
{
    NSArray* columnNames = [HATestSample4 columnNames];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numberValueC", names, @"Verify columns for dynamic property");
}


- (void)testColumnNamesAndTypes
{
    NSMutableArray* columnNames = [NSMutableArray new];
    NSMutableArray* columnTypes = [NSMutableArray new];

    NSMutableArray* correctNames = [NSMutableArray new];
    NSMutableArray* correctTypes = [NSMutableArray new];
    
    [correctNames addObject:@"integerProp"];
    [correctNames addObject:@"uintegerProp"];
    [correctNames addObject:@"longProp"];
    [correctNames addObject:@"longlongProp"];
    [correctNames addObject:@"charProp"];
    [correctNames addObject:@"shortProp"];
    [correctNames addObject:@"ucharProp"];
    [correctNames addObject:@"ushortProp"];
    [correctNames addObject:@"uintProp"];
    [correctNames addObject:@"ulongProp"];
    [correctNames addObject:@"ulonglongProp"];
    [correctNames addObject:@"floatProp"];
    [correctNames addObject:@"doubleProp"];
    [correctNames addObject:@"boolProp"];
    [correctNames addObject:@"stringProp"];
    [correctNames addObject:@"dateProp"];
    [correctNames addObject:@"dataProp"];

    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"REAL"];
    [correctTypes addObject:@"REAL"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"TEXT"];
    [correctTypes addObject:@"NUMERIC"];
    [correctTypes addObject:@"NONE"];

    
    [HATestDataMock columns:columnNames columnTypes:columnTypes];
    
    [columnNames isEqualToArray:correctNames];
    [columnTypes isEqualToArray:correctTypes];
    
}


- (void)testPropertyNamesForHATestSample1
{
    NSArray* propertyNames = [HATestSample1 propertyNames];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue", names, @"Verify columns");
}

- (void)testPropertyNamesForHATestSample3
{
    NSArray* propertyNames = [HATestSample3 propertyNames];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue,stringValue", names, @"Verify columns");
}

- (void)testPropertyNamesForHATestSample4
{
    NSArray* propertyNames = [HATestSample4 propertyNames];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numberValue", names, @"Verify columns for dynamic property");
}



- (void)testPropertyNamesAndTypes
{
    NSMutableArray* propertyNames = [NSMutableArray new];
    NSMutableArray* propertyTypes = [NSMutableArray new];
    
    NSMutableArray* correctNames = [NSMutableArray new];
    NSMutableArray* correctTypes = [NSMutableArray new];
    
    [correctNames addObject:@"integerProp"];
    [correctNames addObject:@"uintegerProp"];
    [correctNames addObject:@"longProp"];
    [correctNames addObject:@"longlongProp"];
    [correctNames addObject:@"charProp"];
    [correctNames addObject:@"shortProp"];
    [correctNames addObject:@"ucharProp"];
    [correctNames addObject:@"ushortProp"];
    [correctNames addObject:@"uintProp"];
    [correctNames addObject:@"ulongProp"];
    [correctNames addObject:@"ulonglongProp"];
    [correctNames addObject:@"floatProp"];
    [correctNames addObject:@"doubleProp"];
    [correctNames addObject:@"boolProp"];
    [correctNames addObject:@"stringProp"];
    [correctNames addObject:@"dateProp"];
    [correctNames addObject:@"dataProp"];

    [correctTypes addObject:@"i"];
    [correctTypes addObject:@"I"];
    [correctTypes addObject:@"l"];
    [correctTypes addObject:@"q"];
    [correctTypes addObject:@"c"];
    [correctTypes addObject:@"s"];
    [correctTypes addObject:@"C"];
    [correctTypes addObject:@"S"];
    [correctTypes addObject:@"I"];
    [correctTypes addObject:@"L"];
    [correctTypes addObject:@"Q"];
    [correctTypes addObject:@"f"];
    [correctTypes addObject:@"d"];
    [correctTypes addObject:@"B"];
    [correctTypes addObject:@"NSString"];
    [correctTypes addObject:@"NSDate"];
    [correctTypes addObject:@"NSData"];
    
    [HATestDataMock columns:propertyNames columnTypes:propertyTypes];
    
    [propertyNames isEqualToArray:correctNames];
    [propertyTypes isEqualToArray:correctTypes];
    
}

- (void)testWhere
{
    HATestSample3* sample3 = [HATestSample3 new];
    sample3.numValue = 1;
    sample3.stringValue = @"foo";
    [sample3 save];
    
    sample3 = [HATestSample3 new];
    sample3.numValue = 2;
    sample3.stringValue = @"bar";
    [sample3 save];
    
    NSUInteger correctResult = 2;
    NSArray* entities = [HATestSample3 where:nil];
    STAssertEquals(correctResult, entities.count, @"Verify all entities are returned.");
    
    NSInteger count = 0;
    for (HATestSample3* sample in entities) {
        if (sample.numValue == 1) {
            STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
            count+=1;
        }
        if (sample.numValue == 2) {
            STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
            count+=2;
        }
    }
    
    // prepareEntity is called when creating table. So
    STAssertEquals(3, count, @"Verify prepareEntity and unprepareEntity is called.");
}


- (void)testConvertPropertyToColumnType
{
    NSInteger integerProp = -1;
    NSUInteger uintegerProp = 1;
    
    long longProp = 2;
    long long longlongProp = 3;
    
    char charProp = 4;
    short shortProp = 5;
    
    unsigned char ucharProp = 6;
    unsigned short ushortProp = 7;
    unsigned int uintProp = 8;
    unsigned long ulongProp = 9;
    unsigned long long ulonglongProp = 10;
    
    float floatProp = 11.5f;
    double doubleProp = 12.5f;
    
    bool boolProp = TRUE;
    
    
    NSDate* date = [NSDate new];
    NSData* bytes = [[NSMutableData alloc] initWithBytes:"abc" length:(strlen("abc") + 1)];
    
    HATestDataMock* data = [HATestDataMock new];
    
    data.integerProp = integerProp;
    data.uintegerProp = uintegerProp;
    
    data.longProp = longProp;
    data.longlongProp = longlongProp;
    
    data.charProp = charProp;
    data.shortProp = shortProp;
    
    data.ucharProp = ucharProp;
    data.ushortProp = ushortProp;
    data.uintProp = uintProp;
    data.ulongProp = ulongProp;
    data.ulonglongProp = ulonglongProp;
    
    data.floatProp = floatProp;
    data.doubleProp = doubleProp;
    
    data.boolProp = boolProp;
    
    data.stringProp = @"stringTest";
    data.dateProp = date;
    data.dataProp = bytes;
    
    
    [data save];
    NSInteger rowid = data.rowid;
    
    data = [HATestDataMock find:rowid];
    
    STAssertEquals(integerProp, data.integerProp, @"Verify property.");
    STAssertEquals(uintegerProp, data.uintegerProp, @"Verify property.");
    STAssertEquals(longProp, data.longProp, @"Verify property.");
    STAssertEquals(longlongProp, data.longlongProp, @"Verify property.");
    STAssertEquals(charProp, data.charProp, @"Verify property.");
    STAssertEquals(shortProp, data.shortProp, @"Verify property.");
    STAssertEquals(ucharProp, data.ucharProp, @"Verify property.");
    STAssertEquals(ushortProp, data.ushortProp, @"Verify property.");
    STAssertEquals(uintProp, data.uintProp, @"Verify property.");
    STAssertEquals(ulongProp, data.ulongProp, @"Verify property.");
    STAssertEquals(ulonglongProp, data.ulonglongProp, @"Verify property.");
    STAssertEquals(floatProp, data.floatProp, @"Verify property.");
    STAssertEquals(doubleProp, data.doubleProp, @"Verify property.");
    STAssertEquals(boolProp, data.boolProp, @"Verify property.");
    
    STAssertEqualObjects(@"stringTest", data.stringProp, @"Verify NSString property.");
    NSString* correctDate = [NSString stringWithFormat:@"%@", date];
    NSString* dataDate = [NSString stringWithFormat:@"%@", data.dateProp];
    STAssertEqualObjects(correctDate, dataDate, @"Verify NSDate property. %@ %@", correctDate, dataDate);
    
    NSString* correctData = [NSString stringWithCString: bytes.bytes encoding:NSASCIIStringEncoding];
    NSString* currentData = [NSString stringWithCString: data.dataProp.bytes encoding:NSASCIIStringEncoding];
    
    STAssertEqualObjects(correctData, currentData, @"Verify property.");
}

- (void)testMaxPropertyValues
{
    NSInteger integerProp = INT_MAX;
    NSUInteger uintegerProp = UINT_MAX;
    
    long longProp = LONG_MAX;
    long long longlongProp = LLONG_MAX;
    
    char charProp = CHAR_MAX;
    short shortProp = SHRT_MAX;
    
    unsigned char ucharProp = UCHAR_MAX;
    unsigned short ushortProp = USHRT_MAX;
    unsigned int uintProp = UINT_MAX;
    unsigned long ulongProp = ULONG_MAX;
    unsigned long long ulonglongProp = ULLONG_MAX;
    
    float floatProp = FLT_MAX;
    double doubleProp = DBL_MAX;
    
    bool boolProp = TRUE;
    
    
    HATestDataMock* data = [HATestDataMock new];
    
    data.integerProp = integerProp;
    data.uintegerProp = uintegerProp;
    
    data.longProp = longProp;
    data.longlongProp = longlongProp;
    
    data.charProp = charProp;
    data.shortProp = shortProp;
    
    data.ucharProp = ucharProp;
    data.ushortProp = ushortProp;
    data.uintProp = uintProp;
    data.ulongProp = ulongProp;
    data.ulonglongProp = ulonglongProp;
    
    data.floatProp = floatProp;
    data.doubleProp = doubleProp;
    
    data.boolProp = boolProp;
    
    data.stringProp = @"";
    data.dateProp = [NSDate new];
    data.dataProp = [NSData new];
    
    
    [data save];
    NSInteger rowid = data.rowid;
    
    data = [HATestDataMock find:rowid];
    
    STAssertEquals(integerProp, data.integerProp, @"Verify property.");
    STAssertEquals(uintegerProp, data.uintegerProp, @"Verify property.");
    STAssertEquals(longProp, data.longProp, @"Verify property.");
    STAssertEquals(longlongProp, data.longlongProp, @"Verify property.");
    STAssertEquals(charProp, data.charProp, @"Verify property. %d %d", charProp, data.charProp);
    STAssertEquals(shortProp, data.shortProp, @"Verify property.");
    STAssertEquals(ucharProp, data.ucharProp, @"Verify property.");
    STAssertEquals(ushortProp, data.ushortProp, @"Verify property.");
    STAssertEquals(uintProp, data.uintProp, @"Verify property.");
    STAssertEquals(ulongProp, data.ulongProp, @"Verify property.");

    // TODO: Current CocoaPod doesn't have the correct method for this type.
#ifdef FMDB_UNSIGNED_LONG_LONG_INT_FOR_COLUMN
    STAssertEquals(ulonglongProp, data.ulonglongProp, @"Verify property.");
#endif
    
    STAssertEquals(floatProp, data.floatProp, @"Verify property.");
    STAssertEquals(doubleProp, data.doubleProp, @"Verify property.");
    STAssertEquals(boolProp, data.boolProp, @"Verify property.");
}

- (void)testMinPropertyValues
{
    NSInteger integerProp = INT_MIN;
    NSUInteger uintegerProp = 0;
    
    long longProp = LONG_MIN;
    long long longlongProp = LLONG_MIN;
    
    char charProp = CHAR_MIN;
    short shortProp = SHRT_MIN;
    
    unsigned char ucharProp = 0;
    unsigned short ushortProp = 0;
    unsigned int uintProp = 0;
    unsigned long ulongProp = 0;
    unsigned long long ulonglongProp = 0;
    
    float floatProp = FLT_MIN;
    double doubleProp = DBL_MIN;
    
    bool boolProp = FALSE;
    
    
    HATestDataMock* data = [HATestDataMock new];
    
    data.integerProp = integerProp;
    data.uintegerProp = uintegerProp;
    
    data.longProp = longProp;
    data.longlongProp = longlongProp;
    
    data.charProp = charProp;
    data.shortProp = shortProp;
    
    data.ucharProp = ucharProp;
    data.ushortProp = ushortProp;
    data.uintProp = uintProp;
    data.ulongProp = ulongProp;
    data.ulonglongProp = ulonglongProp;
    
    data.floatProp = floatProp;
    data.doubleProp = doubleProp;
    
    data.boolProp = boolProp;
    
    data.stringProp = @"";
    data.dateProp = [NSDate new];
    data.dataProp = [NSData new];
    
    
    [data save];
    NSInteger rowid = data.rowid;
    
    data = [HATestDataMock find:rowid];
    
    STAssertEquals(integerProp, data.integerProp, @"Verify property.");
    STAssertEquals(uintegerProp, data.uintegerProp, @"Verify property.");
    STAssertEquals(longProp, data.longProp, @"Verify property.");
    STAssertEquals(longlongProp, data.longlongProp, @"Verify property.");
    STAssertEquals(charProp, data.charProp, @"Verify property. %d %d", charProp, data.charProp);
    STAssertEquals(shortProp, data.shortProp, @"Verify property.");
    STAssertEquals(ucharProp, data.ucharProp, @"Verify property.");
    STAssertEquals(ushortProp, data.ushortProp, @"Verify property.");
    STAssertEquals(uintProp, data.uintProp, @"Verify property.");
    STAssertEquals(ulongProp, data.ulongProp, @"Verify property.");
    STAssertEquals(ulonglongProp, data.ulonglongProp, @"Verify property.");
    STAssertEquals(floatProp, data.floatProp, @"Verify property.");
    STAssertEquals(doubleProp, data.doubleProp, @"Verify property.");
    STAssertEquals(boolProp, data.boolProp, @"Verify property.");
}


- (void)testIgnoreNilProperty
{
    HATestDataMock* data = [HATestDataMock new];
    
    // Test insert.
    [data save];
    
    // Test Update.
    [data save];
}

- (void)testUpdateObject
{
    HATestDataMock* data = [HATestDataMock new];
    
    // Test insert.
    data.stringProp = @"foo";
    [data save];
    
    data = [HATestDataMock find:data.rowid];
    
    STAssertEqualObjects(@"foo", data.stringProp, @"Verify there is a data.");
    
    // Test Update.
    data = [HATestDataMock find:data.rowid];
    data.stringProp = nil;
    [data save];
    
    // Test null value can be set and return nil for the prop.
    data = [HATestDataMock find:data.rowid];
    
    STAssertNil(data.stringProp, @"Verify nil property");
}


@end
