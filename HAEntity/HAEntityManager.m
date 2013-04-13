//
//  HAEntityManager.m
//  readerdays
//
//  Created by Hiroki Ata on 13/04/10.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HAEntityManager.h"

#ifdef DEBUG
# define LOG(...) NSLog(__VA_ARGS__)
#else
# define LOG(...) ;
#endif

@implementation HAEntityManager

const static NSString* THREAD_LOCAL_KEY_HAENTITY_MANAGER_IN_TRANS_FMDATABASE = @"HAEntityManager::InTransactionFMDatabase";

static NSString* SYNC_OBJECT = @"HAEntityManager::SYNC_OBJECT";
static HAEntityManager* _defaultInstance = nil;
static NSMutableDictionary* _managerInstances = nil;


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
            HAEntityManager* manager = [_managerInstances objectForKey:dbFilePath];
            if ((nil == manager) || [manager closed]) {
                manager = [[HAEntityManager alloc] initWithFilePath:dbFilePath];
                if (nil == _defaultInstance) {
                    _defaultInstance = manager;
                }
                if (nil == _managerInstances) {
                    _managerInstances = [NSMutableDictionary new];
                }
                [_managerInstances setObject:manager forKey:dbFilePath];
            }
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

        __block HAEntityManager* entityManager = _defaultInstance;
        [_managerInstances enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            HAEntityManager* manager = obj;
            if ([manager isAddedEntityClass:entityClass]) {
                entityManager = manager;
                *stop = TRUE;
            }
        }];
        
        return entityManager;
    }
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
            [_managerInstances removeObjectForKey:_dbFilePath];
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

- (void) migrate
{
    // TODO: Create table, index, alter table, and so on.
}




@end
