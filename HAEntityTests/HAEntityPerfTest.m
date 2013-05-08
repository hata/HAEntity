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

#import "HAEntityPerfTest.h"
#import "HAEntityManager.h"
#import "HATableEntity.h"


#define BM_START(name) NSDate *name##_start = [NSDate new]
#define BM_END(name)   do{ NSDate *name##_end = [NSDate new];\
  NSLog(@"%s interval: %f", #name, [name##_end timeIntervalSinceDate:name##_start]);\
  } while(0)


#define INSERT_ROW_NUM 10000

@interface HAEntityPerfTestFoo : HATableEntity {
    
}

@property NSInteger intValue;
@property NSString* stringValue;

@end

@implementation HAEntityPerfTestFoo

+ (NSString*) tableName
{
    return @"foo";
}

@end




@implementation HAEntityPerfTest
- (void)setUp
{
    NSLog(@"Setup HAEntityPerfTest");
    [super setUp];
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HAEntityPerfTest.sqlite"];
    manager = [HAEntityManager instanceForPath:dbFilePath];
    
    [manager inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS foo (intValue INTEGER, stringValue TEXT);"];

        for (NSInteger i = 0;i < INSERT_ROW_NUM;i++) {
            [db executeUpdate:@"INSERT INTO foo(intValue, stringValue) VALUES (?, ?);", [NSNumber numberWithInteger:i], [NSString stringWithFormat:@"text-%d", i]];
        }

        [db executeUpdate:@"CREATE INDEX int_index ON foo (intValue);"];
        [db executeUpdate:@"CREATE INDEX string_index ON foo (stringValue);"];
    }];
    NSLog(@"Done setup HAEntityPerfTest");
}

- (void)tearDown
{
    [[HAEntityManager instanceForPath:dbFilePath] remove];
    
    NSError* error;
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dbFilePath]) {
        [fm removeItemAtPath:dbFilePath error:&error];
    }
    
    if (error) {
        NSLog(@"Delete test file error %@", error);
    }
    
    [super tearDown];
}

- (void)testInitialInstance
{
    NSLog(@"================== START: testInitialInstance ==================");
    [manager inDatabase:^(FMDatabase *db) {
        BM_START(SQL_SELECT_INDEXED_NUM);
        for (NSInteger loop_count = 0;loop_count < 10;loop_count++) {
            for (NSInteger i = 0;i < INSERT_ROW_NUM;i++) {
                FMResultSet* rset = [db executeQuery:@"SELECT intValue, stringValue FROM Foo WHERE intValue=?", [NSNumber numberWithInteger:i]];
                [rset close];
            }
        }
        BM_END(SQL_SELECT_INDEXED_NUM);
    }];
    
    BM_START(HAENTITY_SELECT_INDEXED_NUM);
    for (NSInteger loop_count = 0;loop_count < 10;loop_count++) {
        for (NSInteger i = 0; i < INSERT_ROW_NUM;i++) {
            [HAEntityPerfTestFoo where_each:^(id entity, BOOL *stop) {
                *stop = TRUE;
            } where:@"numValue = ?" params:[NSNumber numberWithInteger:i], nil];
        }
    }
    BM_END(HAENTITY_SELECT_INDEXED_NUM);
//    STAssertNil([HAEntityManager instance], @"Verify default is nil.");
    NSLog(@"================== END: testInitialInstance ==================");
}

@end
