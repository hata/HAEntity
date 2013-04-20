//
//  HAPListMigrationTest.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/20.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "HAEntityManager.h"

@interface HAPListMigrationTest : SenTestCase {
@private
    NSString* dbFilePath;
    HAEntityManager* manager;
}


@end
