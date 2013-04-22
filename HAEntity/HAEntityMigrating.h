//
//  HAEntityMigrating.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "HAEntityManager.h"

@class HAEntityManager;

@protocol HAEntityMigrating <NSObject>
@required
- (void) up:(HAEntityManager*)manager database:(FMDatabase*)db;
- (void) down:(HAEntityManager*)manager database:(FMDatabase*)db;

@property (readonly) NSInteger version;

@end
