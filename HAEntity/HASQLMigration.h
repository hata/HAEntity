//
//  HASQLMigration.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAEntityMigrating.h"

/**
 * HASQLMigration* migration = [[HASQLMigration alloc] initWithVersion:aVersion];
 * [migration addSQL:@"CREATE TABLE test" downSQL:@"DROP TABLE test"];
 */
@interface HASQLMigration : NSObject<HAEntityMigrating> {
@private
    NSInteger _version;
    NSMutableArray* _upSQLList;
    NSMutableArray* _downSQLList;
    NSMutableArray* _entityClasses;
}

- (id) initWithVersion:(NSInteger)version;

- (void) addSQLForEntity:(Class)entityClass upSQL:(NSString*)upSQL downSQL:(NSString*)downSQL;

- (void) up:(HAEntityManager*)manager database:(FMDatabase*)db;
- (void) down:(HAEntityManager*)manager database:(FMDatabase*)db;

@end
