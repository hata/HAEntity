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


#import "HATableEntityTest.h"
#import "HAEntityManager.h"
#import "HATableEntityMigration.h"
#import "HASQLMigration.h"
#import "HATableEntity.h"


@interface HATableEntityTestSample1 : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
}

@property NSInteger numValue;
@property NSString* stringValue;

+(HATableEntityTestSample1*) create:(NSInteger)numValue stringValue:(NSString*)stringValue;

@end

@implementation HATableEntityTestSample1

+ (NSString*) tableName {
    return @"table_sample1";
}

@synthesize numValue;
@synthesize stringValue;

+(HATableEntityTestSample1*) create:(NSInteger)numValue stringValue:(NSString*)stringValue
{
    HATableEntityTestSample1* data = [HATableEntityTestSample1 new];
    data.numValue = numValue;
    data.stringValue = stringValue;
    [data save];
    return data;
}

@end




@interface HATableEntityTestSample2 : HATableEntity {

    NSInteger _numValue;
    NSString* stringValue;
}

@property(readonly) NSInteger numValue;
@property NSString* stringValue;


- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue;
@end

@implementation HATableEntityTestSample2

+ (NSString*) tableName {
    return @"table_sample1";
}

@synthesize numValue = _numValue;
@synthesize stringValue;


- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue
{
    _numValue = newNumValue;
    stringValue = newStringValue;
}

@end

@interface HATableEntityTestSample3 : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
}

@property(readonly) NSInteger numValue;
@property NSString* stringValue;


- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue;
@end

@implementation HATableEntityTestSample3

+ (NSString*) tableName {
    return @"table_sample3";
}

@synthesize numValue;
@synthesize stringValue;


- (void)resetValues:(NSInteger)newNumValue newStringValue:(NSString*)newStringValue
{
    numValue = newNumValue;
    stringValue = newStringValue;
}

@end


@interface HATableEntityTestSample4 : HATableEntityTestSample3
@end

@implementation HATableEntityTestSample4
@end


@implementation HATableEntityTest

- (void)setUp
{
    [super setUp];
    
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HATableEntityTest.sqlite"];
    [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses:[HATableEntityTestSample1 class], nil];
    HASQLMigration* migration2 = [[HASQLMigration alloc] initWithVersion:1];
    [migration2 addSQLForEntity:[HATableEntityTestSample3 class] upSQL:@"CREATE TABLE table_sample3(numValue INTEGER PRIMARY KEY, stringValue TEXT);" downSQL:nil];
    [[HAEntityManager instanceForPath:dbFilePath] upToHighestVersion:migration, migration2, nil];
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

- (void)testExample
{
    HATableEntityTestSample1* sample1a = [HATableEntityTestSample1 new];
    sample1a.numValue = 1;
    [sample1a save];
    
    HATableEntityTestSample1* sample1b = [HATableEntityTestSample1 new];
    sample1b.numValue = 2;
    [sample1b save];

    HATableEntityTestSample1* find1 = [HATableEntityTestSample1 find_by_rowid:sample1a.rowid];
    STAssertEquals(1,find1.numValue, @"Verify find rowid");

    HATableEntityTestSample1* find2 = [HATableEntityTestSample1 find_by_rowid:sample1b.rowid];
    STAssertEquals(2, find2.numValue, @"Verify find rowid");
}


- (void)testIgnoreNilProperty
{
    HATableEntityTestSample1* data = [HATableEntityTestSample1 new];
    
    // Test insert.
    [data save];
    
    // Test Update.
    [data save];
}

- (void)testUpdateAndRemoveObject
{
    HATableEntityTestSample1* data = [HATableEntityTestSample1 new];
    
    // Test insert.
    data.stringValue = @"foo";
    [data save];
    
    data = [HATableEntityTestSample1 find_by_rowid:data.rowid];
    
    STAssertEqualObjects(@"foo", data.stringValue, @"Verify there is a data.");
    
    // Test Update.
    data = [HATableEntityTestSample1 find_by_rowid:data.rowid];
    data.stringValue = nil;
    [data save];
    
    // Test null value can be set and return nil for the prop.
    data = [HATableEntityTestSample1 find_by_rowid:data.rowid];
    
    STAssertNil(data.stringValue, @"Verify nil property");
    
    sqlite_int64 rowid = data.rowid;
    
    [data remove];
    
    STAssertNil([HATableEntityTestSample1 find_by_rowid:rowid], @"Verify there is no data.");
}

- (void)testRemoveAll
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];

    NSUInteger correctCount = 2;
    NSArray* result = [HATableEntityTestSample1 select_all];
    STAssertEquals(correctCount, result.count, @"Verify data.");
    [HATableEntityTestSample1 remove_all];
    correctCount = 0;
    result = [HATableEntityTestSample1 select_all];
    STAssertEquals(correctCount, result.count, @"Verify no data.");
}

- (void)testRemoveWhere
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    BOOL removeResult = [HATableEntityTestSample1 remove:@"numValue = 2"];
    STAssertTrue(removeResult, @"Verify remove is succeeded.");

    NSUInteger correctCount = 1;
    NSArray* result = [HATableEntityTestSample1 select_all];
    STAssertEquals(correctCount, result.count, @"Verify there is an entry.");
    HATableEntityTestSample1* remain = [result objectAtIndex:0];
    STAssertEquals(1, remain.numValue, @"Verify numValue = 1 is remained.");
}

- (void)testRemoveWhereOneParam
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    BOOL removeResult = [HATableEntityTestSample1 remove:@"numValue = ?" params:[NSNumber numberWithInt:2], nil];
    STAssertTrue(removeResult, @"Verify remove is succeeded.");
    
    NSUInteger correctCount = 1;
    NSArray* result = [HATableEntityTestSample1 select_all];
    STAssertEquals(correctCount, result.count, @"Verify there is an entry.");
    HATableEntityTestSample1* remain = [result objectAtIndex:0];
    STAssertEquals(1, remain.numValue, @"Verify numValue = 1 is remained.");
}

- (void)testRemoveWhereSomeParams
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    BOOL removeResult = [HATableEntityTestSample1 remove:@"numValue = ? and stringValue = ?" params:[NSNumber numberWithInt:2], @"bar", nil];
    STAssertTrue(removeResult, @"Verify remove is succeeded.");
    
    NSUInteger correctCount = 1;
    NSArray* result = [HATableEntityTestSample1 select_all];
    STAssertEquals(correctCount, result.count, @"Verify there is an entry.");
    HATableEntityTestSample1* remain = [result objectAtIndex:0];
    STAssertEquals(1, remain.numValue, @"Verify numValue = 1 is remained.");
}

- (void)testSaveProperties
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    HATableEntityTestSample1* sample = [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    sqlite_int64 rowid = sample.rowid;
    sample.stringValue = @"foo";
    sample.numValue = 10;
    [sample save:@"stringValue", nil];
    
    sample = [HATableEntityTestSample1 find_by_rowid:rowid];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stringValue is updated.");
    STAssertEquals(2, sample.numValue, @"Verify numValue is not updated.");
}

- (void)testSavePropertiesWithArgs
{
    [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    HATableEntityTestSample1* sample = [HATableEntityTestSample1 create:2 stringValue:@"bar"];
    sqlite_int64 rowid = sample.rowid;
    sample.stringValue = @"foo";
    sample.numValue = 10;
    [sample save:@"stringValue", @"numValue", nil];
    
    sample = [HATableEntityTestSample1 find_by_rowid:rowid];
    STAssertEqualObjects(@"foo", sample.stringValue, @"Verify stringValue is updated.");
    STAssertEquals(10, sample.numValue, @"Verify numValue is updated.");
}


- (void)testSaveWithReadOnlyProperty
{
    HATableEntityTestSample1* sample1 = [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    HATableEntityTestSample2* sample2 = [HATableEntityTestSample2 find_by_rowid:sample1.rowid];
    
    STAssertEquals(sample2.rowid, sample1.rowid, @"Verify rowid.");
    STAssertEquals(1, sample2.numValue, @"Verify data is read.");
    STAssertEqualObjects(@"foo", sample2.stringValue, @"Verify data is read.");
    
    sample2.stringValue = @"bar";
    [sample2 save];
    
    HATableEntityTestSample2* sampleB = [HATableEntityTestSample2 find_by_rowid:sample1.rowid];
    STAssertEquals(1, sampleB.numValue, @"Verify data is read.");
    STAssertEqualObjects(@"bar", sampleB.stringValue, @"Verify data is updated.");
}

- (void)testSaveDontChangeReadonlyValue
{
    HATableEntityTestSample1* sample1 = [HATableEntityTestSample1 create:1 stringValue:@"foo"];
    HATableEntityTestSample2* sample2 = [HATableEntityTestSample2 find_by_rowid:sample1.rowid];
    
    STAssertEquals(sample2.rowid, sample1.rowid, @"Verify rowid.");
    STAssertEquals(1, sample2.numValue, @"Verify data is read.");
    STAssertEqualObjects(@"foo", sample2.stringValue, @"Verify data is read.");
    
    [sample2 resetValues:3 newStringValue:@"bar"];
    [sample2 save];
    
    HATableEntityTestSample2* sampleB = [HATableEntityTestSample2 find_by_rowid:sample1.rowid];
    STAssertEquals(1, sampleB.numValue, @"Verify numValue is not updated.");
    STAssertEqualObjects(@"bar", sampleB.stringValue, @"Verify stringValue is updated.");
}

- (void)testSaveInsertShowReadData
{
    HATableEntityTestSample3* sample3 = [HATableEntityTestSample3 new];
    sample3.stringValue = @"foo";
    [sample3 save];
    sample3 = [HATableEntityTestSample3 new];
    sample3.stringValue = @"bar";
    [sample3 save];
    
    HATableEntityTestSample3* sample3b = [HATableEntityTestSample3 find_by_rowid:sample3.rowid];
    
    //[sample3 reload];
    
    STAssertTrue(sample3.numValue != 0, @"Verify numValue is set after save. find result for numValue is %d", sample3b.numValue);
    STAssertTrue(sample3.rowid != 0, @"Verify rowid is set after save.");
}

- (void)testReload
{
//    [HAEntityManager trace:HAEntityManagerTraceLevelDebug block:^(){
    HATableEntityTestSample3* sample3 = [HATableEntityTestSample3 new];
    sample3.stringValue = @"foo";
    [sample3 save];

    HATableEntityTestSample3* sample3b = [HATableEntityTestSample3 find_by_rowid:sample3.rowid];
    sample3b.stringValue = @"bar";
    [sample3b save];

    sample3b = [HATableEntityTestSample3 find_by_rowid:sample3.rowid];
    STAssertEqualObjects(@"bar", sample3b.stringValue, @"Verify stringValue is updated. %lld", sample3.rowid);
    
    [sample3 reload];

    STAssertEqualObjects(@"bar", sample3.stringValue, @"Verify reload load a new value.");
//    }];
    
}

- (void)testSelectCustomColumnsAddRowid
{
    HATableEntityTestSample3* sample3 = [HATableEntityTestSample3 new];
    sample3.stringValue = @"foo";
    [sample3 save];

    NSArray* result = [HATableEntityTestSample3 select:@"stringValue, numValue FROM table_sample3 WHERE rowid=?" params:[NSNumber numberWithLongLong:sample3.rowid], nil];
    HATableEntityTestSample3* sample3b = [result objectAtIndex:0];
    STAssertEquals(sample3b.rowid, sample3.rowid, @"Verify select method can return a correct rowid");
}


- (void)testSubClassFromOtherEntityClass
{
    HATableEntityTestSample4* sample4 = [HATableEntityTestSample4 new];
    sample4.stringValue = @"foo";
    [sample4 save];
    
    NSArray* result = [HATableEntityTestSample4 select:@"stringValue, numValue FROM table_sample3 WHERE rowid=?" params:[NSNumber numberWithLongLong:sample4.rowid], nil];
    HATableEntityTestSample4* sample4b = [result objectAtIndex:0];
    STAssertEquals(sample4b.rowid, sample4.rowid, @"Verify select method can return a correct rowid");
}





@end
