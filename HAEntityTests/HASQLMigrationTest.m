//
//  HASQLMigrationTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HASQLMigrationTest.h"
#import "HAEntityManager.h"
#import "HASQLMigration.h"

@implementation HASQLMigrationTest

- (void)setUp
{
    [super setUp];
    // Set-up code here.
    
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HASQLMigrationTest.sqlite"];
    [HAEntityManager instanceForPath:dbFilePath];
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


- (void)testVersion
{
    HASQLMigration* migration = [[HASQLMigration alloc] initWithVersion:3];
    STAssertEquals(3, migration.version, @"Verify version is set.");
}

- (void)testUpMigration
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    HASQLMigration* migration = [[HASQLMigration alloc] initWithVersion:3];
    [migration addSQLForEntity:[self class] upSQL:@"CREATE TABLE test_table (numValue NUMERIC);" downSQL:nil];
    [manager accessDatabase:^(FMDatabase *db) {
        [migration up:nil database:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(0, [db lastErrorCode], [db lastErrorMessage]);
    }];
}

- (void)testDownMigration
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    HASQLMigration* migration = [[HASQLMigration alloc] initWithVersion:3];
    [migration addSQLForEntity:[self class] upSQL:@"CREATE TABLE test_table (numValue NUMERIC);" downSQL:@"DROP TABLE test_table;"];
    [manager accessDatabase:^(FMDatabase *db) {
        [migration up:nil database:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(0, [db lastErrorCode], [db lastErrorMessage]);
        [migration down:nil database:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        // This should be error.
        STAssertEquals(1, [db lastErrorCode], [db lastErrorMessage]);
    }];
}

@end
