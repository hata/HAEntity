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

#import "HAEntityManager.h"
#import "HABaseEntity.h"
#import "HATableENtity.h"
#import "HASQLMigration.h"



// Internal table to manage HAEntity.
// Right now, I only use this for migration version.

@interface HAEntityInfo : HATableEntity

+ (NSString*) tableName;
+ (NSArray*) migratings;

@property NSString* name;
@property NSString* value;
@property NSString* info_description;

@end

@implementation HAEntityInfo

static NSString* HAEntityInfoMigrationVersion = @"migration.version";

+ (NSString*) tableName
{
    return @"ha_entity_info";
}

+ (NSArray*) migratings
{
    NSMutableArray* migs = NSMutableArray.new;
    HASQLMigration* migration = [[HASQLMigration alloc] initWithVersion:INT_MIN];
    [migration addSQLForEntity:self
                         upSQL:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (name TEXT, value TEXT, info_description TEXT);", [self tableName]]
                       downSQL:[NSString stringWithFormat:@"DROP TABLE %@;", [self tableName]]];
    [migration addSQLForEntity:self
                         upSQL:[NSString stringWithFormat:@"INSERT INTO %@ (name, value, info_description) VALUES ('%@', '%d', 'initial migration version.');", [self tableName], HAEntityInfoMigrationVersion, INT_MIN]
                       downSQL:[NSString stringWithFormat:@"DELETE %@ WHERE name = '%@'",[self tableName], HAEntityInfoMigrationVersion]];
    [migs addObject:migration];
    return migs;
}

@end




@implementation HAEntityManager

const static NSString* THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE = @"HAEntityManager::InTransactionFMDatabase";
const static NSString* THREAD_LOCAL_KEY_HAENTITY_MANAGER_TRACE_LEVEL = @"HAEntityManager::TraceLevel";

static NSString* SYNC_OBJECT = @"HAEntityManager::SYNC_OBJECT";
static HAEntityManager* _defaultInstance = nil;
static NSMutableArray* _managerInstances = nil;


+ (HAEntityManager*) instance
{
    return [self instanceForPath:nil];
}


+ (HAEntityManager*) instanceForPath:(NSString*)dbFilePath
{
    @synchronized(SYNC_OBJECT) {
        if (nil == dbFilePath) {
            return _defaultInstance;
        } else {
            if (nil == _managerInstances) {
                _managerInstances = [NSMutableArray new];
            }

            for (HAEntityManager* manager in _managerInstances) {
                if ([[manager HA_dbFilePath] isEqualToString:dbFilePath]) {
                    return manager;
                }
            }
            
            HAEntityManager* manager = [[HAEntityManager alloc] initWithFilePath:dbFilePath];
            if (nil == _defaultInstance) {
                _defaultInstance = manager;
            }
            [_managerInstances addObject:manager];

            return manager;
        }
    }
}

+ (HAEntityManager*) instanceForEntity:(Class)entityClass
{
    // TODO: It may be better to more effective code...
    @synchronized(SYNC_OBJECT) {
        // If there is only 1 instance, then return a default one
        // because it is a default instance.
        if ((nil == entityClass) || ((nil != _managerInstances) && [_managerInstances count] == 1)) {
            return _defaultInstance;
        }

        // Search entity using reverse order because if I ran test, the test class
        // usually use EntityManager temporarily.
        __block HAEntityManager* entityManager = _defaultInstance;
        [_managerInstances enumerateObjectsWithOptions:NSEnumerationReverse
                                            usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            HAEntityManager* manager = obj;
            if ([manager isAddedEntityClass:entityClass]) {
                entityManager = manager;
                *stop = TRUE;
            }
        }];
        
        return entityManager;
    }
}


+ (void) trace:(HAEntityManagerTraceLevel)level block:(void (^)())block
{
    NSMutableDictionary* threadLocal = [[NSThread currentThread] threadDictionary];
    @try {
        [threadLocal setObject:[NSNumber numberWithInt:level] forKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_TRACE_LEVEL];
        block();
    }
    @catch (NSException *exception) {
    }
    @finally {
        [threadLocal removeObjectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_TRACE_LEVEL];
    }
}

+ (BOOL) isTraceEnabled:(HAEntityManagerTraceLevel)level
{
    NSMutableDictionary* threadLocal = [[NSThread currentThread] threadDictionary];
    NSNumber* num = [threadLocal objectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_TRACE_LEVEL];
    return num ? ([num integerValue] >= level) : FALSE;
}



- (NSString*) HA_dbFilePath
{
    return _dbFilePath;
}


- (id) initWithFilePath:dbFilePath
{
    if (self = [super init]) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
        _dbFilePath = dbFilePath;
        _entityClasses = nil;
    }
    return self;
}

- (void) close
{
    [_dbQueue close];
    _dbQueue = nil;
    
    @synchronized(SYNC_OBJECT) {
        if (self == _defaultInstance) {
            _defaultInstance = nil;
        }

        if (nil != _dbFilePath) {
            [_managerInstances removeObject:self];
        }
    }
}


- (void) remove
{
    if (nil != _dbQueue) {
        [self close];
    }

    if (nil != _dbFilePath) {
        // Tear-down code here.
        NSError* error;
        NSFileManager* manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:_dbFilePath]) {
            [manager removeItemAtPath:_dbFilePath error:&error];
        }
        
        if (error) {
            HA_LOG(@"It failed to delete %@ because of error:%@", _dbFilePath, error);
        }
        
        _dbFilePath = nil;
    }
}


- (BOOL) closed
{
    return nil == _dbQueue;
}


- (BOOL) isDefault
{
    @synchronized(SYNC_OBJECT) {
        return _defaultInstance == self;
    }
}

- (void) setDefault
{
    @synchronized(SYNC_OBJECT) {
        _defaultInstance = self;
    }
}


- (void) inDatabase:(void (^)(FMDatabase *db))block
{
    NSMutableDictionary* threadLocal = [[NSThread currentThread] threadDictionary];
    FMDatabase* currentDatabase = [threadLocal objectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE];
    if (currentDatabase) {
        // In transaction ...
        block(currentDatabase);
    } else {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            @try {
                block(db);
            }
            @catch (NSException *exception) {
                // TODO: Handle error.
                HA_LOG(@"Exception is thrown while using inDatabase %@", exception);
            }
            @finally {
            }
        }];
    }
}


- (void) inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block
{
    NSMutableDictionary* threadLocal = [[NSThread currentThread] threadDictionary];
    FMDatabase* currentDatabase = [threadLocal objectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE];

    if (!currentDatabase) {
        [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            @try {
                [threadLocal setObject:db forKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE];
                block(db, rollback);
            }
            @catch (NSException *exception) {
                // TODO: Handle error.
                HA_LOG(@"exception is thrown while running transaction. %@", exception);
                *rollback = TRUE;
            }
            @finally {
                [threadLocal removeObjectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE];
            }
        }];
    } else {
        // This should be catched in the first transaction block and should rollback.
        // This code should not be called.
        //[[NSException exceptionWithName:@"TransactionIsOpened" reason:@"Try to open db transaction twice." userInfo:nil] raise];

        // This is handled to call inTransaction within inTransaction block.
        // manager inTransaction:^{
        //   ...
        //   manager inTransaction:^{
        //   ...
        // }
        // This may occur while calling methods.
        BOOL rollback = FALSE;
        block(currentDatabase, &rollback);
        if (rollback) {
            [[NSException exceptionWithName:@"TransactionRollback" reason:@"rollback is set while invoking block." userInfo:nil] raise];
        }
    }
}


- (void) addEntityClass:(Class)entityClass
{
    if (nil == entityClass) {
        return;
    }

    if (nil == _entityClasses) {
        @synchronized(self) {
            if (nil == _entityClasses) {
                // TODO: Is NSMutableArray faster than Set ?
                // If the number of element is small, Array may be faster than Set.
                _entityClasses = [NSMutableSet new];
            }
        }
    }
    
    @synchronized(self) {
        [_entityClasses addObject:entityClass];
    }
}


- (void) removeEntityClass:(Class) entityClass
{
    if (nil == entityClass) {
        return;
    }

    if (_entityClasses) {
        @synchronized(self) {
            [_entityClasses removeObject:entityClass];
        }
    }
}


- (BOOL) isAddedEntityClass:(Class)entityClass
{
    if (nil == entityClass) {
        return FALSE;
    }

    @synchronized(self) {
        return nil != [_entityClasses member:entityClass];
    }
}


- (NSInteger) HA_getCurrenMigrationVersion
{
    NSString* queryString = [NSString stringWithFormat:@"SELECT value FROM %@ WHERE name = ?", [HAEntityInfo tableName]];

    __block NSInteger migrationVersion = INT_MIN;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet* rset = [db executeQuery:queryString, HAEntityInfoMigrationVersion];
        if ([rset next]) {
            migrationVersion = [rset intForColumn:@"value"];
            [rset close];
        } else {
            [rset close];
            NSArray* migs = [HAEntityInfo migratings];
            for (id<HAEntityMigrating> mig in migs) {
                [mig up:self database:db];
            }
            rset = [db executeQuery:queryString, HAEntityInfoMigrationVersion];
            if ([rset next]) {
                migrationVersion = [rset intForColumn:@"value"];
            }
            [rset close];
        }
    }];
    
/*
 // If I used HAEntityInfo, multiple instance may not work well.
    HAEntityInfo* info = [HAEntityInfo find_first:@"name = ?" params:HAEntityInfoMigrationVersion, nil];
    if (!info) {
        NSArray* migs = [HAEntityInfo migratings];
        for (id<HAEntityMigrating> mig in migs) {
            
            [[self class] trace:HAEntityManagerTraceLevelDebug block:^{
                
                [self inDatabase:^(FMDatabase *db) {
                    [mig up:self database:db];
                }];
            }];
        }
        info = [HAEntityInfo find_first:@"name = ?" params:HAEntityInfoMigrationVersion, nil];
    }

    return [info.value integerValue];
 */
    return migrationVersion;
}

- (void) HA_applyMigratingsWithOrder:(BOOL)up toVersion:(NSInteger)toVersion
{
//    NSInteger fromVersion = up ? INT_MIN : INT_MAX; // TODO: This should get from db.
    NSInteger fromVersion = [self HA_getCurrenMigrationVersion];

    NSMutableArray* allMigratings = NSMutableArray.new;
    if (_entityClasses) {
        @synchronized (self) {
            for (Class clazz in _entityClasses) {
                NSArray* migratings = [clazz migratings];
                if (migratings) {
                    [allMigratings addObjectsFromArray:migratings];
                }
            }
        }
    }
    
    if (_migratings) {
        @synchronized (self) {
            [allMigratings addObjectsFromArray:_migratings];
        }
    }

    NSSortDescriptor* sorter = [[NSSortDescriptor alloc] initWithKey:@"version" ascending:up];
    [allMigratings sortUsingDescriptors:[NSArray arrayWithObject:sorter]];

    // TODO: This may need to run in txn.
    [allMigratings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<HAEntityMigrating> sortedMigrating = obj;
        
        if (up) {
            if (sortedMigrating.version <= fromVersion) {
                // skip.
            } else if (sortedMigrating.version <= toVersion) {
                [self inDatabase:^(FMDatabase *db) {
                    [sortedMigrating up:self database:db];
                    [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET value = ? WHERE name = '%@'", [HAEntityInfo tableName], HAEntityInfoMigrationVersion],
                     [NSString stringWithFormat:@"%d", sortedMigrating.version]];
                    // TODO: NEED TO UPDATE VERSION IN HAENTITYINFO
                }];
            } else {
                *stop = TRUE;
            }
        } else {
            if (sortedMigrating.version > fromVersion) {
                // skip.
            } else if (sortedMigrating.version > toVersion) {
                [self inDatabase:^(FMDatabase *db) {
                    [sortedMigrating down:self database:db];
                    [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET value = ? WHERE name = '%@'", [HAEntityInfo tableName], HAEntityInfoMigrationVersion],
                     [NSString stringWithFormat:@"%d", sortedMigrating.version]];
                    // TODO: NEED TO UPDATE VERSION IN HAENTITYINFO
                }];
            } else {
                *stop = TRUE;
            }
        }
    }];
}

- (void) up:(NSInteger)toVersion
{
    [self HA_applyMigratingsWithOrder:TRUE toVersion:toVersion];
}

- (void) upToHighestVersion
{
    [self HA_applyMigratingsWithOrder:TRUE toVersion:INT_MAX];
}

- (void) down:(NSInteger)toVersion
{
    [self HA_applyMigratingsWithOrder:FALSE toVersion:toVersion];
    
}

- (void) downToLowestVersion
{
    [self HA_applyMigratingsWithOrder:FALSE toVersion:INT_MIN];
}

- (void) addEntityMigrating:(id<HAEntityMigrating>) migrating
{
    if (nil == migrating) {
        return;
    }
    
    if (nil == _migratings) {
        @synchronized(self) {
            if (nil == _migratings) {
                _migratings = NSMutableArray.new;
            }
        }
    }
    
    @synchronized(self) {
        [_migratings addObject:migrating];
    }

}

- (void) removeEntityMigrating:(id<HAEntityMigrating>) migrating
{
    if (nil == migrating) {
        return;
    }
    
    if (_migratings) {
        @synchronized(self) {
            [_migratings removeObject:migrating];
        }
    }
}

- (BOOL) isAddedEntityMigrating:(id<HAEntityMigrating>) migrating
{
    if (nil == migrating) {
        return FALSE;
    }
    
    if (_migratings) {
        @synchronized (self) {
            return [_migratings containsObject:migrating];
        }
    }
    
    return FALSE;
}

@end


