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

@end

@implementation HATableEntityTestSample1

+ (NSString*) tableName {
    return @"table_sample1";
}

@synthesize numValue;
@synthesize stringValue;

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



@end
