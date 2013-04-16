//
//  HATableEntityTest.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/15.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntityTest.h"
#import "HAEntityManager.h"
#import "HATableEntityMigration.h"

@implementation HATableEntityTest

- (void)setUp
{
    [super setUp];
    
    dbFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/HAEntity_HATableEntityTest.sqlite"];
    [HAEntityManager instanceForPath:dbFilePath];
    HATableEntityMigration* migration = [[HATableEntityMigration alloc] initWithVersion:1
                                                                          entityClasses: nil];
    [[HAEntityManager instance] up:2 migratings:migration, nil];
}

- (void)tearDown
{
    // Tear-down code here.
    [[HAEntityManager instance] remove];
    
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

- (void)testExample
{
    //    STFail(@"Unit tests are not implemented yet in HAEntityTests");
}


@end
