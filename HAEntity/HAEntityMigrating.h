//
//  HAEntityMigrating.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@protocol HAEntityMigrating <NSObject>
@required
- (void) up:(FMDatabase*)db;
- (void) down:(FMDatabase*)db;

@property (readonly) NSInteger version;

@end
