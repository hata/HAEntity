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
