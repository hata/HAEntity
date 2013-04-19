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



@interface HAEntityManagerTestMigration : NSObject<HAEntityMigrating> {
@private
    NSInteger _version;
    NSInteger upCount;
    NSInteger downCount;
    NSMutableArray* _upOrder;
    NSMutableArray* _downOrder;
}

@property NSInteger upCount;
@property NSInteger downCount;

@end


@implementation HAEntityManagerTestMigration

@synthesize version = _version;
@synthesize upCount;
@synthesize downCount;

- (id) initWithVersion:(NSInteger)version
{
    if (self = [super init]) {
        _version = version;
        upCount = 0;
        downCount = 0;
        _upOrder = nil;
        _downOrder = nil;
    }
    return self;
}

- (id) initWithVersion:(NSInteger)version upOrder:(NSMutableArray*)upOrder downOrder:(NSMutableArray*)downOrder
{
    if (self = [super init]) {
        _version = version;
        upCount = 0;
        downCount = 0;
        _upOrder = upOrder;
        _downOrder = downOrder;
    }
    return self;
}

- (void) up:(FMDatabase *)db
{
    upCount = upCount+1;
    [_upOrder addObject:[NSNumber numberWithInt:_version]];
}

- (void) down:(FMDatabase *)db
{
    downCount = downCount+1;
    [_downOrder addObject:[NSNumber numberWithInt:_version]];
}

@end


@implementation HAEntityManagerTest

- (void)setUp
{
    [super setUp];
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HAEntityManagerTest.sqlite"];
    dbFilePath2 = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HAEntityManagerTest2.sqlite"];
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


- (void)testUpToMax
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:INT_MAX migratings:migration1, migration2, migration3, nil];

    STAssertEquals(1, migration1.upCount, @"Verify migration1.up is called");
    STAssertEquals(1, migration2.upCount, @"Verify migration2.up is called");
    STAssertEquals(1, migration3.upCount, @"Verify migration3.up is called");
    STAssertEquals(0, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(0, migration2.downCount, @"Verify migration2.down is not called");
    STAssertEquals(0, migration3.downCount, @"Verify migration3.down is not called");
}

- (void)testUpSomeVersions
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:2 migratings:migration1, migration2, migration3, nil];
    
    STAssertEquals(1, migration1.upCount, @"Verify migration1.up is called");
    STAssertEquals(1, migration2.upCount, @"Verify migration2.up is called. The same toVersion is called.");
    STAssertEquals(0, migration3.upCount, @"Verify migration3.up is not called");
    STAssertEquals(0, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(0, migration2.downCount, @"Verify migration2.down is not called");
    STAssertEquals(0, migration3.downCount, @"Verify migration3.down is not called");
}

- (void)testUpNoVersion
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:0 migratings:migration1, migration2, migration3, nil];
    
    STAssertEquals(0, migration1.upCount, @"Verify migration1.up is not called");
    STAssertEquals(0, migration2.upCount, @"Verify migration2.up is not called");
    STAssertEquals(0, migration3.upCount, @"Verify migration3.up is not called");
    STAssertEquals(0, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(0, migration2.downCount, @"Verify migration2.down is not called");
    STAssertEquals(0, migration3.downCount, @"Verify migration3.down is not called");
}

- (void)testDownMin
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:INT_MIN migratings:migration1, migration2, migration3, nil];
    
    STAssertEquals(0, migration1.upCount, @"Verify migration1.up is not called");
    STAssertEquals(0, migration2.upCount, @"Verify migration2.up is not called");
    STAssertEquals(0, migration3.upCount, @"Verify migration3.up is not called");
    STAssertEquals(1, migration1.downCount, @"Verify migration1.down is called");
    STAssertEquals(1, migration2.downCount, @"Verify migration2.down is called");
    STAssertEquals(1, migration3.downCount, @"Verify migration3.down is called");
}

- (void)testDownSomeVersions
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:2 migratings:migration1, migration2, migration3, nil];
    
    STAssertEquals(0, migration1.upCount, @"Verify migration1.up is not called");
    STAssertEquals(0, migration2.upCount, @"Verify migration2.up is not called");
    STAssertEquals(0, migration3.upCount, @"Verify migration3.up is not called");
    STAssertEquals(0, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(0, migration2.downCount, @"Verify migration2.down is not called. The same toVersion for down is NOT called.");
    STAssertEquals(1, migration3.downCount, @"Verify migration3.down is called");
}

- (void)testDownNoVersion
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:3 migratings:migration1, migration2, migration3, nil];
    
    STAssertEquals(0, migration1.upCount, @"Verify migration1.up is not called");
    STAssertEquals(0, migration2.upCount, @"Verify migration2.up is not called");
    STAssertEquals(0, migration3.upCount, @"Verify migration3.up is not called");
    STAssertEquals(0, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(0, migration2.downCount, @"Verify migration2.down is not called");
    STAssertEquals(0, migration3.downCount, @"Verify migration3.down is not called");
}


- (void)testUpToMaxCheckOrder
{
    NSMutableArray* upOrder = [NSMutableArray new];
    NSMutableArray* downOrder = [NSMutableArray new];

    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1 upOrder:upOrder downOrder:downOrder];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2 upOrder:upOrder downOrder:downOrder];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3 upOrder:upOrder downOrder:downOrder];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:INT_MAX migratings:migration1, migration2, migration3, nil];
    STAssertEqualObjects(@"1,2,3", [upOrder componentsJoinedByString:@","], @"Verify call order.");

    [upOrder removeAllObjects];
    
    [manager up:INT_MAX migratings:migration3, migration2, migration1, nil];
    STAssertEqualObjects(@"1,2,3", [upOrder componentsJoinedByString:@","], @"Verify call order.");
}

- (void)testDownMinCheckOrder
{
    NSMutableArray* upOrder = [NSMutableArray new];
    NSMutableArray* downOrder = [NSMutableArray new];
    
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1 upOrder:upOrder downOrder:downOrder];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2 upOrder:upOrder downOrder:downOrder];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3 upOrder:upOrder downOrder:downOrder];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:INT_MIN migratings:migration1, migration2, migration3, nil];
    STAssertEqualObjects(@"3,2,1", [downOrder componentsJoinedByString:@","], @"Verify call order.");
    
    [downOrder removeAllObjects];
    
    [manager down:INT_MIN migratings:migration3, migration2, migration1, nil];
    STAssertEqualObjects(@"3,2,1", [downOrder componentsJoinedByString:@","], @"Verify call order.");
}

- (void)testUpNil
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:INT_MAX migratings:nil];
    
    // Just verify no exception.
}

- (void)testUpOneMigration
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager up:INT_MAX migratings:migration1, nil];

    STAssertEquals(1, [migration1 upCount], @"Verify up is called.");
}

- (void)testDownNil
{
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:INT_MIN migratings:nil];
    
    // Just verify no exception.
}

- (void)testDownOneMigration
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager down:INT_MIN migratings:migration1,nil];
    STAssertEquals(1, [migration1 downCount], @"Verify down is called.");
}

- (void)testUpToHighestVersion
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager upToHighestVersion:migration1, migration2, migration3, nil];
    
    STAssertEquals(1, migration1.upCount, @"Verify migration1.up is called");
    STAssertEquals(1, migration2.upCount, @"Verify migration2.up is called");
    STAssertEquals(1, migration3.upCount, @"Verify migration3.up is called");
}


- (void)testDownLowestVersion
{
    HAEntityManagerTestMigration* migration1 = [[HAEntityManagerTestMigration alloc] initWithVersion:1];
    HAEntityManagerTestMigration* migration2 = [[HAEntityManagerTestMigration alloc] initWithVersion:2];
    HAEntityManagerTestMigration* migration3 = [[HAEntityManagerTestMigration alloc] initWithVersion:3];
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager downToLowestVersion:migration1, migration2, migration3, nil];
    
    STAssertEquals(1, migration1.downCount, @"Verify migration1.down is not called");
    STAssertEquals(1, migration2.downCount, @"Verify migration2.down is not called");
    STAssertEquals(1, migration3.downCount, @"Verify migration3.down is not called");
}


- (void) testEntitySearchOrder
{
    [HAEntityManager instanceForPath:dbFilePath];
    [[HAEntityManager instance] addEntityClass:[self class]];
    
    [HAEntityManager instanceForPath:dbFilePath2];
    [[HAEntityManager instanceForPath:dbFilePath2] addEntityClass:[self class]];

    STAssertEqualObjects([HAEntityManager instanceForPath:dbFilePath2],
                         [HAEntityManager instanceForEntity:[self class]],
                         @"Verify latest added entity's instance should be returned.");
}




@end
