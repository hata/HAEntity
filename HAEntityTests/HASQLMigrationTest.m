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
    [manager inDatabase:^(FMDatabase *db) {
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
    [manager inDatabase:^(FMDatabase *db) {
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
