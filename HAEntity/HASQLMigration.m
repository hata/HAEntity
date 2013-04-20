//
//  HASQLMigration.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/19.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HASQLMigration.h"

@implementation HASQLMigration

@synthesize version = _version;

- (id) initWithVersion:(NSInteger)version
{
    if (self = [super init]) {
        _version = version;
        _upSQLList = [NSMutableArray new];
        _downSQLList = [NSMutableArray new];
    }
    return self;
}

- (void) addSQL:(NSString*)upSQL downSQL:(NSString*)downSQL
{
    if (upSQL) {
        [_upSQLList addObject:upSQL];
    }
    if (downSQL) {
        [_downSQLList insertObject:downSQL atIndex:0];
    }
}

- (void) up:(FMDatabase*)db
{
    for (NSString* sql in _upSQLList) {
        [db executeUpdate:sql];
    }
}

- (void) down:(FMDatabase*)db
{
    for (NSString* sql in _downSQLList) {
        [db executeUpdate:sql];
    }
}

@end
