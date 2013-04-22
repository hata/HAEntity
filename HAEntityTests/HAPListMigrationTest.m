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
    [manager remove];
    
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
        [migration up:nil database:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(0, [db lastErrorCode], [db lastErrorMessage]);
        [migration down:nil database:db];
        [db executeUpdate:@"INSERT INTO test_table(numValue) VALUES(1);"];
        STAssertEquals(1, [db lastErrorCode], [db lastErrorMessage]);
    }];
}

@end
