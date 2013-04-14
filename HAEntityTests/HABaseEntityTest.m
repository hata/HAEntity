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


#define HA_DATA_ENTITY_DB_FILE_PATH @"/test2.sqlite"
#define HA_DATA_ENTITY_DB_FILE_PATH2 @"/test2b.sqlite"

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

+ (void) alterTable:(FMDatabase*)database
{
    [database executeUpdate:@"ALTER TABLE test_table1 ADD COLUMN stringValue TEXT;"];
}

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




@implementation HABaseEntityTest

- (void)setUp
{
    [super setUp];

//    NSArray* docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:HA_DATA_ENTITY_DB_FILE_PATH];
    [HAEntityManager instanceForPath:dbFilePath];

    // [HATestSample2 class],
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses:[HATestDataMock class], [HATestSample1 class], [HATestSample3 class], nil];
    [[HAEntityManager instance] up:2 migratings:migration, nil];
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instance] remove];
    
    // Tear-down code here.
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


// Right now, I disabled multiple db usage.
// I think createDatabase, getDatabase, removeDatabase should be
// override. After that, the class can access different db.
// And right now, there is a problem in cache.
/*
 - (void)testMultiDatabases
 {
 [HATestSample1 configure:dbFilePath];
 [HATestSample2 configure:dbFilePath2];
 
 HATestSample1* sample1 = [HATestSample1 new];
 sample1.numValue = 1;
 [sample1 save];
 
 HATestSample2* sample2 = [HATestSample2 new];
 sample2.numValue = 2;
 [sample2 save];
 
 STAssertEquals(1, sample1.rowid, @"Verify different db is used. So, rowid is 1.");
 STAssertEquals(1, sample2.rowid, @"Verify different db is used. So, rowid is 1.");
 }*/


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
    STAssertEquals(ulonglongProp, data.ulonglongProp, @"Verify property.");
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

/*
- (void)testAlterTable
{
    HATestSample1* sample1 = [HATestSample1 new];
    sample1.numValue = 1;
    [sample1 save];

    [[HAEntityManager instance] close];
    
    // Re initialize configuration.
    [HAEntityManager instanceForPath:dbFilePath];
    
    // And then updated table is used for created database.
    HATestSample2* sample2 = [HATestSample2 new];
    sample2.numValue = 2;
    sample2.stringValue = @"foo";
    [sample2 save];
    
    sample2 = [HATestSample2 find:sample2.rowid];
    STAssertEquals(2, sample2.numValue, @"Verify num value.");
    STAssertEqualObjects(@"foo", sample2.stringValue, @"Verify string value.");
    
    sample2 = [HATestSample2 find:sample1.rowid];
    STAssertEquals(1, sample2.numValue, @"Verify the same table should be read.");
    STAssertNil(sample2.stringValue, @"Verify default nil.");
}
*/


@end
