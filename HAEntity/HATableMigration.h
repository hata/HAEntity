//
//  HATableMigration.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAEntityMigrating.h"

@interface HATableMigration : NSObject<HAEntityMigrating> {
@private
    NSMutableArray* _classes;
}

- (id) initWithEntityClasses:(Class) clazz, ... NS_REQUIRES_NIL_TERMINATION;

@end
