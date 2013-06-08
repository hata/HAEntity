//
// Copyright 2013 Hiroki Ata
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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



@interface HATestSample3Having : HATableEntity {
@private
    NSInteger sumValue;
    
}

+ (NSString*) tableName;

@property NSInteger sumValue;


@end

@implementation HATestSample3Having

@synthesize sumValue;

+ (NSString*)tableName
{
    return @"test_table3";
}

+ (NSString*)selectPrefix
{
    return @"SELECT sum(numValue) as sumValue FROM test_table3";
}

@end



@interface HATestSample5 : HATableEntity {
@private
    NSInteger _numValue;
    NSString* _stringValue;
}

+ (NSString*) tableName;

@property(readonly) NSInteger numValue;
@property NSString* stringValue;

- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue;

@end

@implementation HATestSample5

@synthesize numValue = _numValue;
@synthesize stringValue = _stringValue;

+ (NSString*)tableName
{
    return @"test_table3";
}

- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue
{
    _numValue = newNumValue;
    _stringValue = newStringValue;
}

@end




#pragma mark -
#pragma mark HABaseEntityTest

@implementation HABaseEntityTest

- (void)setUp
{
    [super setUp];

    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HABaseEntityTest.sqlite"];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses:[HATestDataMock class], [HATestSample1 class],
                                         [HATestSample2 class], [HATestSample3 class], [HATestSample3Having class], [HATestSample4 class],
                                         [HATestSample5 class], nil];
    [manager addEntityMigrating:migration];
    [manager upToHighestVersion];
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instanceForPath:dbFilePath] remove];
    
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

- (HATestSample3*) createSample3:(NSInteger)numValue stringValue:(NSString*)stringValue
{
    HATestSample3* sample = [HATestSample3 new];
    sample.numValue = numValue;
    sample.stringValue = stringValue;
    [sample save];
    return sample;
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
    NSArray* columnNames = [HAEntityPropertyInfo propertyStringList:[HATestSample1 class] filterType:HAEntityPropertyInfoFilterTypeColumnName];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue", names, @"Verify columns");
}

- (void)testColumnNamesForHATestSample3
{
    NSArray* columnNames = [HAEntityPropertyInfo propertyStringList:[HATestSample3 class] filterType:HAEntityPropertyInfoFilterTypeColumnName];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue,stringValue", names, @"Verify columns");
}

- (void)testColumnNamesForHATestSample4
{
    NSArray* columnNames = [HAEntityPropertyInfo propertyStringList:[HATestSample4 class] filterType:HAEntityPropertyInfoFilterTypeColumnName];
    NSString* names = [columnNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numberValueC", names, @"Verify columns for dynamic property");
}


- (void)testColumnNamesAndTypes
{
    NSArray* columnNames = [NSMutableArray new];
    NSArray* columnTypes = [NSMutableArray new];

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

    columnNames = [HAEntityPropertyInfo propertyStringList:[HATestDataMock class] filterType:HAEntityPropertyInfoFilterTypeColumnName];
    columnTypes = [HAEntityPropertyInfo propertyStringList:[HATestDataMock class] filterType:HAEntityPropertyInfoFilterTypeColumnType];
    
    [columnNames isEqualToArray:correctNames];
    [columnTypes isEqualToArray:correctTypes];
    
}


- (void)testPropertyNamesForHATestSample1
{
    NSArray* propertyNames = [HAEntityPropertyInfo propertyStringList:[HATestSample1 class] filterType:HAEntityPropertyInfoFilterTypePropertyName];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue", names, @"Verify columns");
}

- (void)testPropertyNamesForHATestSample3
{
    NSArray* propertyNames = [HAEntityPropertyInfo propertyStringList:[HATestSample3 class] filterType:HAEntityPropertyInfoFilterTypePropertyName];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numValue,stringValue", names, @"Verify columns");
}

- (void)testPropertyNamesForHATestSample4
{
    NSArray* propertyNames = [HAEntityPropertyInfo propertyStringList:[HATestSample4 class] filterType:HAEntityPropertyInfoFilterTypePropertyName];
    NSString* names = [propertyNames componentsJoinedByString:@","];
    STAssertEqualObjects(@"numberValue", names, @"Verify columns for dynamic property");
}



- (void)testPropertyNamesAndTypes
{
    NSArray* propertyNames = [NSMutableArray new];
    NSArray* propertyTypes = [NSMutableArray new];
    
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

    propertyNames = [HAEntityPropertyInfo propertyStringList:[HATestDataMock class] filterType:HAEntityPropertyInfoFilterTypePropertyName];
    propertyTypes = [HAEntityPropertyInfo propertyStringList:[HATestDataMock class] filterType:HAEntityPropertyInfoFilterTypePropertyType];
    
    [propertyNames isEqualToArray:correctNames];
    [propertyTypes isEqualToArray:correctTypes];
    
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
    
    data = [HATestDataMock find_by_rowid:rowid];
    
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
    
    data = [HATestDataMock find_by_rowid:rowid];
    
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
    
    data = [HATestDataMock find_by_rowid:rowid];
    
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

- (void)testPropertiesForUpdates
{
    NSArray* infoList = [HAEntityPropertyInfo propertyInfoList:[HATestSample5 class] includesIfReadOnly:FALSE];
    STAssertEquals((NSUInteger)1, infoList.count, @"Verify no updatable propertyNames");
    STAssertEqualObjects(@"stringValue", [[infoList objectAtIndex:0] propertyName], @"Verify updatable property names");
}

- (void)testPropertiesForReadOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];

    NSArray* infoList = [HAEntityPropertyInfo propertyInfoList:[HATestSample5 class] includesIfReadOnly:TRUE];
    STAssertEquals((NSUInteger)1, infoList.count, @"Verify no updatable propertyNames");
    STAssertEqualObjects(@"numValue", [[infoList objectAtIndex:0] propertyName], @"Verify no updatable property names");
}

#pragma mark -
#pragma mark find

- (void)testFind_first
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    STAssertNotNil([HATestSample3 find_first], @"Verify  object is returned. There is no order. So, just check nil or not.");
}

- (void)testFind_first_where
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    // TODO: This is not good I should not set 1 = 1 or something where cruse.
    HATestSample3* result = [HATestSample3 find_first:@"1 = 1 order by numValue" params:nil];
    STAssertEquals(1, result.numValue, @"Verify 1st object is returned.");
    
    result = [HATestSample3 find_first:@"1 = 1 order by numValue desc" params:nil];
    STAssertEquals(2, result.numValue, @"Verify 1st object is returned.");
}

- (void)testFindFirstOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"foo"];
    
    // TODO: This is not good I should not set 1 = 1 or something where cruse.
    HATestSample3* result = [HATestSample3 find_first:@"stringValue = ? order by numValue" params:@"foo", nil];
    STAssertEquals(1, result.numValue, @"Verify 1st object is returned.");
    
    result = [HATestSample3 find_first:@"stringValue = ? order by numValue desc" params:@"foo", nil];
    STAssertEquals(3, result.numValue, @"Verify 3rd object is returned.");
}

- (void)testFindFirstTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"foo"];
    
    // TODO: This is not good I should not set 1 = 1 or something where cruse.
    HATestSample3* result = [HATestSample3 find_first:@"stringValue = ? or stringValue = ? order by numValue" params:@"foo", @"bar", nil];
    STAssertEquals(1, result.numValue, @"Verify 1st object is returned.");
    
    result = [HATestSample3 find_first:@"stringValue = ? or stringValue = ? order by numValue desc" params:@"foo", @"bar", nil];
    STAssertEquals(3, result.numValue, @"Verify 3rd object is returned.");
}


#pragma mark -
#pragma mark select

- (void)testSelect_all
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"bar"];

    NSUInteger correctResult = 3;
    NSArray* entities = [HATestSample3 select_all];
    STAssertEquals(correctResult, entities.count, @"Verify all count.");
    
    [entities sortedArrayUsingSelector:@selector(numValue)];
    
    STAssertEquals(1, [[entities objectAtIndex:0] numValue], @"Verify each entity.");
    STAssertEquals(2, [[entities objectAtIndex:1] numValue], @"Verify each entity.");
    STAssertEquals(3, [[entities objectAtIndex:2] numValue], @"Verify each entity.");
}

- (void)testSelect_all_block
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"bar"];
    
    NSUInteger correctResult = 3;
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_all:^(id entity, BOOL* stop) {
        [entities addObject:entity];
    }];
    STAssertEquals(correctResult, entities.count, @"Verify all count.");
    
    [entities sortedArrayUsingSelector:@selector(numValue)];
    
    STAssertEquals(1, [[entities objectAtIndex:0] numValue], @"Verify each entity.");
    STAssertEquals(2, [[entities objectAtIndex:1] numValue], @"Verify each entity.");
    STAssertEquals(3, [[entities objectAtIndex:2] numValue], @"Verify each entity.");
}

- (void)testSelect_all_block_and_stop
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_all:^(id entity, BOOL* stop) {
        [entities addObject:entity];
        *stop = true;
    }];
    STAssertEquals(correctResult, entities.count, @"Verify all count.");
}


- (void)testSelectReturnArray
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    NSArray* entities = [HATestSample3 select:nil];
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


- (void)testSelectReturnArrayWithParamStringOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    NSArray* entities = [HATestSample3 select:@"numValue, stringValue FROM test_table3"];
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
    STAssertEquals(3, count, @"Verify all entities are returned.");
}


- (void)testSelectReturnArrayWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 select:@"numValue, stringValue FROM test_table3 WHERE numValue = ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}

- (void)testSelectReturnArrayWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 select:@"numValue, stringValue FROM test_table3 WHERE numValue = ? or stringValue = ?" params:[NSNumber numberWithInt:1], @"foo", nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}

- (void)testSelectBlock
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } select:nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
}

- (void)testSelectBlockWithStringOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } select:@"numValue, stringValue FROM test_table3"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
}

- (void)testSelectBlockWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } select:@"numValue, stringValue FROM test_table3 WHERE numValue = ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}


- (void)testSelectBlockWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 select_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } select:@"numValue, stringValue FROM test_table3 WHERE numValue = ? or stringValue = ?" params:[NSNumber numberWithInt:1], @"foo", nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}


#pragma mark -
#pragma mark where

- (void)testWhereReturnArray
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
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

- (void)testWhereReturnArrayWithParamStringOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    NSArray* entities = [HATestSample3 where:@"numValue = 1"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}

- (void)testWhereReturnArrayWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 where:@"numValue = ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}

- (void)testWhereReturnArrayWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 where:@"numValue = ? or stringValue = ?" params:[NSNumber numberWithInt:1], @"foo", nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}

- (void)testWhereBlock
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
}

- (void)testWhereBlockWithStringOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"numValue = 1"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}

- (void)testWhereBlockWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"numValue = ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}

- (void)testWhereBlockWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"numValue = ? or stringValue = ?" params:[NSNumber numberWithInt:1], @"foo", nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample3 = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample3.stringValue, @"Verify stored value.");
}


- (void)testWhereWithOrderBy
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"bar"];

    NSUInteger correctResult = 2;
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"stringValue = ? ORDER BY numValue" params:@"bar", nil];
    STAssertEquals(correctResult, entities.count, @"Verify 'bar' entities are returned.");

    STAssertEquals(2, [[entities objectAtIndex:0] numValue], @"Verify order by.");
    STAssertEquals(3, [[entities objectAtIndex:1] numValue], @"Verify order by.");

    entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"stringValue = ? ORDER BY numValue DESC" params:@"bar", nil];
    STAssertEquals(3, [[entities objectAtIndex:0] numValue], @"Verify order by.");
    STAssertEquals(2, [[entities objectAtIndex:1] numValue], @"Verify order by.");
}

- (void)testWhereOrderByStringWithParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    [self createSample3:3 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"stringValue = ? ORDER BY numValue" params:@"bar", nil];
    STAssertEquals(correctResult, entities.count, @"Verify 'bar' entities are returned.");
    
    STAssertEquals(2, [[entities objectAtIndex:0] numValue], @"Verify order by.");
    STAssertEquals(3, [[entities objectAtIndex:1] numValue], @"Verify order by.");

    entities = [NSMutableArray new];
    [HATestSample3 where_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } where:@"stringValue = ? ORDER BY numValue DESC" params:@"bar", nil];
    STAssertEquals(3, [[entities objectAtIndex:0] numValue], @"Verify order by.");
    STAssertEquals(2, [[entities objectAtIndex:1] numValue], @"Verify order by.");
}


#pragma mark -
#pragma mark order_by

- (void)testOrder_byReturnArray
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    NSArray* entities = [HATestSample3 order_by:nil];
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


- (void)testOrder_byReturnArrayWithStringOnly
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    NSArray* entities = [HATestSample3 order_by:@"numValue"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");

    entities = [HATestSample3 order_by:@"numValue desc"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
}

- (void)testOrder_byReturnArrayWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 order_by:@"numValue limit ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
    
    entities = [HATestSample3 order_by:@"numValue desc limit ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify 2nd entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
}

- (void)testOrder_byReturnArrayWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSArray* entities = [HATestSample3 order_by:@"numValue limit ? offset ?" params:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
    
    entities = [HATestSample3 order_by:@"numValue desc limit ? offset ?" params:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify 2nd entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}


- (void)testOrder_byBlockNil
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
}

- (void)testOrder_byBlock
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 2;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue"];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
    
    entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue desc"];
    STAssertEquals(correctResult, entities.count, @"Verify 2nd entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
}

- (void)testOrder_byBlockWithOneParam
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue limit ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");

    entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue desc limit ?" params:[NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify 2nd entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
}

- (void)testOrder_byBlockWithTwoParams
{
    [self createSample3:1 stringValue:@"foo"];
    [self createSample3:2 stringValue:@"bar"];
    
    NSUInteger correctResult = 1;
    
    NSMutableArray* entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue limit ? offset ?" params:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify 2nd entity is returned.");
    HATestSample3* sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"bar", sample.stringValue, @"Verify stored value.");
    
    entities = [NSMutableArray new];
    [HATestSample3 order_by_each:^(id entity, BOOL *stop) {
        [entities addObject:entity];
    } order_by:@"numValue desc limit ? offset ?" params:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
    STAssertEquals(correctResult, entities.count, @"Verify first entity is returned.");
    sample = [entities objectAtIndex:0];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stored value.");
}

@end
