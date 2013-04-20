//
//  HAPListMigrationTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/20.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAPListMigrationTest.h"
#import "HAEntityManager.h"
#import "HAPListMigration.h"

@implementation HAPListMigrationTest

- (void)setUp
{
    [super setUp];
    // Set-up code here.
    
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HAPListMigrationTest.sqlite"];
    manager = [HAEntityManager instanceForPath:dbFilePath];
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instanceForPath:dbFilePath] remove];
    
    NSError* error;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dbFilePath]) {
        [fileManager removeItemAtPath:dbFilePath error:&error];
    }
    if (error) {
        NSLog(@"Delete test file error %@", error);
    }
    
    [super tearDown];
}


- (void)testVersion
{
    HAPListMigration* migration = [[HAPListMigration alloc] initWithVersion:3];
    STAssertEquals(3, migration.version, @"Verify version is set.");
}

- (void)testAddPList
{
    NSString *path = nil;
    HAPListMigration* migration = [[HAPListMigration alloc] initWithVersion:3];
    for (NSBundle* bundle in [NSBundle allBundles]) {
        path = [bundle pathForResource:@"migration-test" ofType:@"plist"];
        if (path) {
            break;
        }
    }

    [migration addPropertyList:path];
    [manager accessDatabase:^(FMDatabase *db) {
        [migration up:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(0, [db lastErrorCode], [db lastErrorMessage]);
        [migration down:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(1, [db lastErrorCode], [db lastErrorMessage]);
    }];
}

@end
