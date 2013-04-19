//
//  HAEntityManager.m
//  readerdays
//
//  Created by Hiroki Ata on 13/04/10.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAEntityManager.h"


@implementation HAEntityManager

const static NSString* THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE = @"HAEntityManager::InTransactionFMDatabase";

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
            LOG(@"It failed to delete %@ because of error:%@", _dbFilePath, error);
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


- (void) accessDatabase:(void (^)(FMDatabase *db))block
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
                LOG(@"Exception is thrown while using inDatabase %@", exception);
            }
            @finally {
            }
        }];
    }
}


- (void) transaction:(void (^)(FMDatabase *db, BOOL *rollback))block
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
                LOG(@"exception is thrown while running transaction. %@", exception);
                *rollback = TRUE;
            }
            @finally {
                [threadLocal removeObjectForKey:THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE];
            }
        }];
    } else {
        // This should be catched in the first transaction block and should rollback.
        // This code should not be called.
        [[NSException exceptionWithName:@"TransactionIsOpened" reason:@"Try to open db transaction twice." userInfo:nil] raise];
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



- (void) HA_migrate:(BOOL)up toVersion:(NSInteger)toVersion migrating:(id<HAEntityMigrating>)migrating list:(va_list)args
{
    NSMutableArray* migs = [NSMutableArray new];
    NSInteger fromVersion = up ? INT_MIN : INT_MAX; // TODO: This should get from db.


    [migs addObject:migrating];
    if (args) {
        migrating = va_arg(args, id<HAEntityMigrating>);
        while (migrating) {
            [migs addObject:migrating];
            migrating = va_arg(args, id<HAEntityMigrating>);
        }
    }
    
    NSSortDescriptor* sorter = [[NSSortDescriptor alloc] initWithKey:@"version" ascending:up];
    [migs sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    
    [migs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<HAEntityMigrating> sortedMigrating = obj;
        
        if (up) {
            if (sortedMigrating.version <= fromVersion) {
                // skip.
            } else if (sortedMigrating.version <= toVersion) {
                [self accessDatabase:^(FMDatabase *db) {
                    [obj up:db];
                }];
            } else {
                *stop = TRUE;
            }
        } else {
            if (sortedMigrating.version > fromVersion) {
                // skip.
            } else if (sortedMigrating.version > toVersion) {
                [self accessDatabase:^(FMDatabase *db) {
                    [obj down:db];
                }];
            } else {
                *stop = TRUE;
            }
        }
    }];
    
    // TODO: Set a new version to metadata table.
}


- (void) up:(NSInteger)toVersion migratings:(id<HAEntityMigrating>) migratings, ...
{
    if (!migratings) {
        return;
    }
    
    va_list args;
    va_start(args,migratings);
    va_end(args);
    
    [self HA_migrate:TRUE toVersion:toVersion migrating:migratings list:args];
}


- (void) upToHighestVersion:(id<HAEntityMigrating>) migratings, ...
{
    if (!migratings) {
        return;
    }
    
    va_list args;
    va_start(args,migratings);
    va_end(args);
    
    [self HA_migrate:TRUE toVersion:INT_MAX migrating:migratings list:args];
}

- (void) down:(NSInteger)toVersion migratings:(id<HAEntityMigrating>) migratings, ...
{
    if (!migratings) {
        return;
    }

    va_list args;
    va_start(args,migratings);
    va_end(args);
    
    [self HA_migrate:FALSE toVersion:toVersion migrating:migratings list:args];
}

- (void) downToLowestVersion:(id<HAEntityMigrating>) migratings, ...
{
    if (!migratings) {
        return;
    }
    
    va_list args;
    va_start(args,migratings);
    va_end(args);
    
    [self HA_migrate:FALSE toVersion:INT_MIN migrating:migratings list:args];
}

@end
