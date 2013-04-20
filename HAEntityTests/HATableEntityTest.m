//
//  HATableEntityTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/15.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntityTest.h"
#import "HAEntityManager.h"
#import "HATableEntityMigration.h"
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


@implementation HATableEntityTest

- (void)setUp
{
    [super setUp];
    
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HATableEntityTest.sqlite"];
    [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses:[HATableEntityTestSample1 class], nil];
    [[HAEntityManager instance] up:2 migratings:migration, nil];
    [[HAEntityManager instanceForPath:dbFilePath] addEntityClass:[HATableEntityTestSample1 class]];
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





@end
