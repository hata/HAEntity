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


#import "HASQLMigration.h"

@implementation HASQLMigration

@synthesize version = _version;

- (id) initWithVersion:(NSInteger)version
{
    if (self = [super init]) {
        _version = version;
        _upSQLList = NSMutableArray.new;
        _downSQLList = NSMutableArray.new;
        _entityClasses = NSMutableArray.new;
    }
    return self;
}

- (void) addSQLForEntity:(Class)entityClass upSQL:(NSString*)upSQL downSQL:(NSString*)downSQL
{
    if (upSQL) {
        [_upSQLList addObject:upSQL];
    }
    if (downSQL) {
        [_downSQLList insertObject:downSQL atIndex:0];
    }

    if (entityClass) {
        [_entityClasses addObject:entityClass];
    }
}

- (void) up:(HAEntityManager*)manager database:(FMDatabase*)db
{
    for (NSString* sql in _upSQLList) {
        [db executeUpdate:sql];
    }
    
    for (Class clazz in _entityClasses) {
        [manager addEntityClass:clazz];
    }
}

- (void) down:(HAEntityManager*)manager database:(FMDatabase*)db
{
    for (NSString* sql in _downSQLList) {
        [db executeUpdate:sql];
    }

    for (Class clazz in _entityClasses) {
        [manager removeEntityClass:clazz];
    }
}

@end
