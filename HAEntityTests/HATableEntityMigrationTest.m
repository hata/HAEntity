//
//  HATableEntityMigrationTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntityMigrationTest.h"
#import "HATableEntity.h"
#import "HATableEntityMigration.h"

@interface HATableEntityMigrationSample : HATableEntity {
@private
    NSString* stringValue;
}

+ (NSString*) tableName;

@property NSString* stringValue;

@end

@implementation HATableEntityMigrationSample

@dynamic stringValue;

+ (NSString*) tableName
{
    return @"sample_table";
}

@end


@interface HAEntityManagerMock : HAEntityManager {
    NSMutableSet* testAddedClasses;
}

- (void) addEntityClass:(Class) entityClass;


@end


@implementation HAEntityManagerMock

- (void) addEntityClass:(Class) entityClass
{
    if (!testAddedClasses) {
        testAddedClasses = NSMutableSet.new;
    }
    [testAddedClasses addObject:entityClass];
}

- (void) removeEntityClass:(Class) entityClass
{
    [testAddedClasses removeObject:entityClass];
}

- (BOOL) isAddedMember:(Class)entityClass
{
    return [testAddedClasses member:entityClass] != nil;
}

@end


@implementation HATableEntityMigrationTest

- (void)setUp
{
    [super setUp];
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HATableEntityMigrationTest.sqlite"];
    
    // Set-up code here.
}

- (void)tearDown
{
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

- (void)testVersion
{
    NSInteger versionNumber = 1;
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:versionNumber entityClasses:[HATableEntityMigrationSample class], nil];
    STAssertEquals(versionNumber, migration.version, @"Verify version number.");
}

- (void)testUpAndDown
{
    HAEntityManagerMock* manager = HAEntityManagerMock.new;
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1 entityClasses:[HATableEntityMigrationSample class], nil];
    FMDatabase* db = [FMDatabase databaseWithPath:dbFilePath];
    [db open];
    [migration up:manager database:db];
    FMResultSet* rset = [db executeQuery:@"SELECT stringValue FROM sample_table"];
    [db close];

    STAssertNotNil(rset, @"Verify query finished successfully.");
    STAssertTrue([manager isAddedMember:[HATableEntityMigrationSample class]], @"Verify entity class is added to HAEntityManager.");

    [db open];
    [migration down:manager database:db];
    rset = [db executeQuery:@"SELECT stringValue FROM sample_table"];
    [db close];

    STAssertNil(rset, @"Verify table is dropped.");
    STAssertFalse([manager isAddedMember:[HATableEntityMigrationSample class]], @"Verify entity class is removed from HAEntityManager.");
}

@end
