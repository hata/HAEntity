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
