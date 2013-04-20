//
//  HAReadEntityTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAReadEntityTest.h"
#import "HAEntityManager.h"
#import "HATableEntityMigration.h"
#import "HATableEntity.h"
#import "HAReadEntity.h"

@interface HAReadEntityTestSample : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
}

@property NSInteger numValue;
@property NSString* stringValue;

@end

@implementation HAReadEntityTestSample

@synthesize numValue;
@synthesize stringValue;

+ (NSString*)tableName
{
    return @"test_sample";
}


@end

@interface HAReadEntityTestView : HAReadEntity {
@private
    NSInteger sumValue;
}

@property NSInteger sumValue;

@end

@implementation HAReadEntityTestView

@synthesize sumValue;

+ (NSString*)tableName
{
    return @"test_sample";
}

+ (NSString*)convertPropertyToColumnName:(NSString *)propertyName
{
    return [propertyName isEqualToString:@"sumValue"] ? @"sum(numValue)" : propertyName;
}

@end


@implementation HAReadEntityTest

- (void)setUp
{
    [super setUp];
    // Set-up code here.

    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HAReadEntityTest.sqlite"];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1 entityClasses:[HAReadEntityTestSample class], nil];
    [manager upToHighestVersion:migration, nil];
    [manager addEntityClass:[HAReadEntityTestSample class]];
    [manager addEntityClass:[HAReadEntityTestView class]];
    
    HAReadEntityTestSample* sample = [HAReadEntityTestSample new];
    sample.numValue = 1;
    sample.stringValue = @"foo";
    [sample save];
    sample = [HAReadEntityTestSample new];
    sample.numValue = 2;
    sample.stringValue = @"bar";
    [sample save];
    sample = [HAReadEntityTestSample new];
    sample.numValue = 3;
    sample.stringValue = @"foo";
    [sample save];
    sample = [HAReadEntityTestSample new];
    sample.numValue = 4;
    sample.stringValue = @"bar";
    [sample save];
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

- (void)testSum
{
    NSUInteger correctCount = 1;
    
    [HAEntityManager trace:HAEntityManagerTraceLevelDebug block:^{
        NSArray* result = [HAReadEntityTestView select_all];
        STAssertEquals(correctCount, result.count, @"Verify result.");
        HAReadEntityTestView* sum = [result objectAtIndex:0];
        STAssertEquals(10, sum.sumValue, @"Verify sum(numValue).");
    }];
}

- (void)testSumGroupBy
{
    NSUInteger correctCount = 2;
    
    NSArray* result = [HAReadEntityTestView group_by:@"stringValue"];
    STAssertEquals(correctCount, result.count, @"Verify result.");
    HAReadEntityTestView* sum = [result objectAtIndex:0];
    STAssertTrue(sum.sumValue == 4 || sum.sumValue == 6, @"Verify sumValue.");
    sum = [result objectAtIndex:1];
    STAssertTrue(sum.sumValue == 4 || sum.sumValue == 6, @"Verify sumValue.");
}

- (void)testSumGroupByOneParam
{
    NSUInteger correctCount = 1;
    
    NSArray* result = [HAReadEntityTestView group_by:@"stringValue HAVING sum(numValue) > ?" params:[NSNumber numberWithInt:5], nil];
    STAssertEquals(correctCount, result.count, @"Verify result.");
    HAReadEntityTestView* sum = [result objectAtIndex:0];
    STAssertTrue(sum.sumValue == 6, @"Verify sumValue.");
}

- (void)testSumGroupByTwoParams
{
    NSUInteger correctCount = 1;
    
    NSArray* result = [HAReadEntityTestView group_by:@"stringValue HAVING sum(numValue) > ? and sum(numValue) < ?" params:[NSNumber numberWithInt:5], [NSNumber numberWithInt:10], nil];
    STAssertEquals(correctCount, result.count, @"Verify result.");
    HAReadEntityTestView* sum = [result objectAtIndex:0];
    STAssertTrue(sum.sumValue == 6, @"Verify sumValue.");
}

- (void)testSumGroupByBlock
{
    __block NSInteger count = 0;
    [HAReadEntityTestView group_by_each:^(id entity, BOOL *stop) {
        HAReadEntityTestView* sum = entity;
        STAssertTrue(sum.sumValue == 4 || sum.sumValue == 6, @"Verify sumValue.");
        count++;
    } group_by:@"stringValue"];
    STAssertEquals(2, count, @"Verify block calls.");
}

- (void)testSumGroupByBlockOneParam
{
    __block NSInteger count = 0;
    [HAReadEntityTestView group_by_each:^(id entity, BOOL *stop) {
        HAReadEntityTestView* sum = entity;
        STAssertEquals(6, sum.sumValue, @"Verify sumValue.");
        count++;
    } group_by:@"stringValue HAVING sum(numValue) > ?" params:[NSNumber numberWithInt:5], nil];
    STAssertEquals(1, count, @"Verify block calls.");
}

- (void)testSumGroupByBlockTwoParams
{
    __block NSInteger count = 0;
    [HAReadEntityTestView group_by_each:^(id entity, BOOL *stop) {
        HAReadEntityTestView* sum = entity;
        STAssertEquals(6, sum.sumValue, @"Verify sumValue.");
        count++;
    } group_by:@"stringValue HAVING sum(numValue) > ? and sum(numValue) < ?" params:[NSNumber numberWithInt:5], [NSNumber numberWithInt:10], nil];
    STAssertEquals(1, count, @"Verify block calls.");
}


@end
