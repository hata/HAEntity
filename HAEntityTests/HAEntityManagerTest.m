//
//  HAEntityManagerTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/12.
//  Copyright (c) 2013年 Hiroki Ata. All rights reserved.
//

#import "HAEntityManagerTest.h"
#import "HAEntityManager.h"
#import "FMDatabase.h"

@implementation HAEntityManagerTest

- (void)setUp
{
    [super setUp];
    NSArray* docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    dbFilePath = [[docPaths objectAtIndex:0] stringByAppendingString:@"/HAEntity_HAEntityManagerTest.sqlite"];
    dbFilePath2 = [[docPaths objectAtIndex:0] stringByAppendingString:@"/HAEntity_HAEntityManagerTest2.sqlite"];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instanceForPath:dbFilePath] remove];
    [[HAEntityManager instanceForPath:dbFilePath2] remove];
    
    NSError* error;
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:dbFilePath]) {
        [manager removeItemAtPath:dbFilePath error:&error];
    }
    if ([manager fileExistsAtPath:dbFilePath2]) {
        [manager removeItemAtPath:dbFilePath2 error:&error];
    }
    
    if (error) {
        NSLog(@"Delete test file error %@", error);
    }

    [super tearDown];
}

- (void)testInitialInstance
{
    STAssertNil([HAEntityManager instance], @"Verify default is nil.");
}

- (void)testInstanceWithPath
{
    [HAEntityManager instanceForPath:dbFilePath];
    STAssertNotNil([HAEntityManager instance], @"Verify default is not nil after creating an instance.");
}

- (void)testInstanceWithEntity
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* manager2 = [HAEntityManager instanceForPath:dbFilePath2];
    [manager2 setDefault];
    Class clazz = [self class];

    [manager addEntityClass:clazz];

    STAssertEqualObjects(manager2, [HAEntityManager instance], @"Verify default is manager2.");
    STAssertEqualObjects(manager, [HAEntityManager instanceForEntity:clazz], @"Verify manager is returned for [self class]");
}

- (void)testInstanceWithEntityNil
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* manager2 = [HAEntityManager instanceForPath:dbFilePath2];
    [manager2 setDefault];
    [manager addEntityClass:nil];

    STAssertEqualObjects(manager2, [HAEntityManager instanceForEntity:nil], @"Verify a default manager is returened for nil.");
}

- (void)testInstanceClose
{
    [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* manager = [HAEntityManager instance];
    [manager close];
    STAssertNil([HAEntityManager instance], @"Verify closed instance reset default instance if it is a default one.");
}

- (void)testInstanceCloseNonDefault
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* manager2 = [HAEntityManager instanceForPath:dbFilePath2];
    [manager2 setDefault];

    [manager close];
    STAssertNotNil([HAEntityManager instance], @"Verify closed instance doesn't reset a default instance if the closed one is not a default.");
}

- (void)testInstanceRemove
{
    NSFileManager* manager = [NSFileManager defaultManager];
    [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* em = [HAEntityManager instance];

    [em close];
    STAssertTrue([manager fileExistsAtPath:dbFilePath], @"Verify close doesn't remove file yet.");

    [em remove];
    STAssertFalse([manager fileExistsAtPath:dbFilePath], @"Verify database file is removed.");
}

- (void)testInstanceIsDefault
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    STAssertTrue([manager isDefault], @"Verify isDefault returns true.");
    [manager close];
    STAssertFalse([manager isDefault], @"Verify isDefault returns false for closed manager.");
}

- (void)testInstanceAddEntityClassAndRemoveEntityClass
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    HAEntityManager* manager2 = [HAEntityManager instanceForPath:dbFilePath2];
    [manager2 setDefault];

    [manager addEntityClass:[self class]];
    STAssertEqualObjects(manager, [HAEntityManager instanceForEntity:[self class]], @"Verify added instance is returned.");
    [manager removeEntityClass:[self class]];
    STAssertEqualObjects(manager2, [HAEntityManager instanceForEntity:[self class]], @"Verify a default instance is returned after removeEntityClass.");
}

- (void)testAccessDatabase
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];

    __block BOOL result = FALSE;
    [manager accessDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:@"CREATE TABLE test(id NUMERIC);"];
    }];
    
    STAssertTrue(result, @"Verify create table sql works well.");
}


- (void)testTransaction
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    __block BOOL result = FALSE;
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        result = [db executeUpdate:@"CREATE TABLE test(id NUMERIC);"];
        result &= [db executeUpdate:@"INSERT INTO test(id) VALUES (?);", [NSNumber numberWithInt:2]];
    }];

    STAssertTrue(result, @"Verify create table and insert sqls work well.");
}


- (void)testTransactionRollback
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        [db executeUpdate:@"CREATE TABLE test(id NUMERIC);"];
    }];

    __block BOOL result = FALSE;
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        result = [db executeUpdate:@"INSERT INTO test(id) VALUES (?);", [NSNumber numberWithInt:2]];
        *rollback = ![db executeUpdate:@"INSERT INTO test_not_found(not_found_column) VALUES (?);", [NSNumber numberWithInt:2]];
    }];
    
    STAssertTrue(result, @"Verify first insert should work well.");
    
    [manager accessDatabase:^(FMDatabase *db) {
        FMResultSet* rset = [db executeQuery:@"SELECT * FROM test;"];
        result = [rset next];
    }];

    STAssertFalse(result, @"Verify INSERT SQLs are failed.");
}

- (void)testAccessDatabaseInTransactionBlock
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        [db executeUpdate:@"CREATE TABLE test(id NUMERIC);"];
    }];
    
    __block BOOL result = FALSE;
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        [[HAEntityManager instanceForPath:dbFilePath] accessDatabase:^(FMDatabase *inDB) {
            result = [db executeUpdate:@"INSERT INTO test(id) VALUES (?);", [NSNumber numberWithInt:2]];
            *rollback = ![db executeUpdate:@"INSERT INTO test_not_found(not_found_column) VALUES (?);", [NSNumber numberWithInt:2]];
        }];
    }];
    
    STAssertTrue(result, @"Verify first insert should work well.");
    
    [manager accessDatabase:^(FMDatabase *db) {
        FMResultSet* rset = [db executeQuery:@"SELECT * FROM test;"];
        result = [rset next];
    }];
    
    STAssertFalse(result, @"Verify INSERT SQLs are failed.");
}

- (void)testTransactionBlockTwiceIsRollbacked
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        [db executeUpdate:@"CREATE TABLE test(id NUMERIC);"];
    }];
    
    __block BOOL result1 = FALSE;
    __block BOOL result2 = FALSE;
    [manager transaction:^(FMDatabase *db, BOOL* rollback) {
        result1 = [db executeUpdate:@"INSERT INTO test(id) VALUES (?);", [NSNumber numberWithInt:2]];
        [[HAEntityManager instanceForPath:dbFilePath] transaction:^(FMDatabase *db2, BOOL *rollback2) {
            result2 = TRUE;
            [db executeUpdate:@"INSERT INTO test(id) VALUES (?);", [NSNumber numberWithInt:3]];
        }];
    }];
    
    STAssertTrue(result1, @"Verify first insert should work well.");
    STAssertFalse(result2, @"Verify 2nd insert should not called.");
    
    __block BOOL result = FALSE;
    [manager accessDatabase:^(FMDatabase *db) {
        FMResultSet* rset = [db executeQuery:@"SELECT * FROM test;"];
        result = [rset next];
    }];
    
    STAssertFalse(result, @"Verify INSERT SQLs are rollbacked.");
}
@end
