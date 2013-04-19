//
//  HATableMigration.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAEntityMigrating.h"

@interface HATableEntityMigration : NSObject<HAEntityMigrating> {
@private
    NSInteger _version;
    NSMutableArray* _classes;
}

- (id) initWithVersion:(NSInteger)version entityClasses:(Class)entityClass, ... NS_REQUIRES_NIL_TERMINATION;

- (void) up:(FMDatabase*)db;
- (void) down:(FMDatabase*)db;

@end
