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

#import "HASampleTest.h"
#import "HAEntityManager.h"
#import "HATableEntityMigration.h"
#import "HATableEntity.h"

@interface HASampleTestSample1 : HATableEntity

+ (NSString*) tableName;

@property NSString* name;
@property NSString* details;
@property NSInteger price;

@end

@implementation HASampleTestSample1

+ (NSString*) tableName
{
    return @"sample1";
}

@synthesize name;
@synthesize details;
@synthesize price;

@end



@implementation HASampleTest

- (void)setUp
{
    [super setUp];
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HASampleTest.sqlite"];
}

- (void)tearDown
{
    [[HAEntityManager instanceForPath:dbFilePath] remove];
    
    NSError* error;
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:dbFilePath]) {
        [manager removeItemAtPath:dbFilePath error:&error];
    }

    [super tearDown];
}

- (void) testSample1
{
    // Init sqlite file.
    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];

    // Create a new table based on the class properties.
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1 entityClasses:[HASampleTestSample1 class], nil];
    [manager addEntityMigrating:migration];
    [manager upToHighestVersion];

    // Create a new instance and then set new values.
    HASampleTestSample1* sample = HASampleTestSample1.new;
    sample.name = @"sample";
    sample.details = @"testSample1 details";
    sample.price = 101;

    // Then save it.
    [sample save];

    // Get it from memory(Or use the same instance.)
    sample = [HASampleTestSample1 find_first];
    STAssertEqualObjects(@"sample", sample.name, @"Verify name is saved successfully.");
    STAssertEqualObjects(@"testSample1 details", sample.details, @"Verify details is saved successfully.");
    STAssertEquals(101, sample.price, @"Verify price is saved successfully.");
}

@end
