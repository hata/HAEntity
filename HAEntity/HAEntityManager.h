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
#import "FMDatabaseQueue.h"
#import "HAEntityMigrating.h"

#ifdef DEBUG
# define HA_LOG(...) NSLog(__VA_ARGS__)

# define HA_ENTITY_ERROR(...) do { if ([HAEntityManager isTraceEnabled:HAEntityManagerTraceLevelError])  { NSLog(__VA_ARGS__); } } while(0)
# define HA_ENTITY_WARN(...)  do { if ([HAEntityManager isTraceEnabled:HAEntityManagerTraceLevelWarning]){ NSLog(__VA_ARGS__); } } while(0)
# define HA_ENTITY_INFO(...)  do { if ([HAEntityManager isTraceEnabled:HAEntityManagerTraceLevelInfo])   { NSLog(__VA_ARGS__); } } while(0)
# define HA_ENTITY_FINE(...)  do { if ([HAEntityManager isTraceEnabled:HAEntityManagerTraceLevelFine])   { NSLog(__VA_ARGS__); } } while(0)
# define HA_ENTITY_DEBUG(...) do { if ([HAEntityManager isTraceEnabled:HAEntityManagerTraceLevelDebug])  { NSLog(__VA_ARGS__); } } while(0)

#else
# define HA_LOG(...) ;

# define HA_ENTITY_ERROR(...) ;
# define HA_ENTITY_WARN(...)  ;
# define HA_ENTITY_INFO(...)  ;
# define HA_ENTITY_FINE(...)  ;
# define HA_ENTITY_DEBUG(...) ;

#endif



@protocol HAEntityMigrating;

typedef enum HAEntityManagerTraceLevel : NSInteger {
    HAEntityManagerTraceLevelError = 1,
    HAEntityManagerTraceLevelWarning,
    HAEntityManagerTraceLevelInfo,
    HAEntityManagerTraceLevelFine,
    HAEntityManagerTraceLevelDebug
} HAEntityManagerTraceLevel;


/**
 * HAEntityManager* entityManager = [HAEntityManager instance:dbFilePath];
 * [entityManager save:entity];
 */
@interface HAEntityManager : NSObject {
@private
    FMDatabaseQueue* _dbQueue;
    NSString* _dbFilePath;
    NSString* _backupPath;
    NSMutableSet* _entityClasses;
    NSMutableArray* _migratings;
}

#pragma mark -
#pragma mark class methods

/**
 * Get a default instance or nil if it doesn't exist.
 * @return a default instance.
 */
+ (HAEntityManager*) instance;


/**
 * Get instance for db path.
 * @param dbFilePath is used to create or a key for a instance.
 * @return a new instance if it doesn't exist. Or, return
 * an instance for dbFilePath if the instance exists.
 */
+ (HAEntityManager*) instanceForPath:(NSString*)dbFilePath;


+ (HAEntityManager*) instanceForPath:(NSString*)dbFilePath backupPath:(NSString*)backupPath;


/**
 * Get an instance for a specific entity class.
 * If there is an instance which is called addEntityClass,
 * the instance is returned. Otherwise, return a default instance.
 * @param entityClass is a specific entity class which is searched.
 * @return an instance for the entity class. Otherwise a default instance.
 */
+ (HAEntityManager*) instanceForEntity:(Class)entityClass;


/**
 * Show executed sql and debug information in this block.
 * @param block is used to enable trace.
 */
+ (void) trace:(HAEntityManagerTraceLevel)level block:(void (^)())block;

/**
 * Check trace information.
 */
+ (BOOL) isTraceEnabled:(HAEntityManagerTraceLevel)level;


#pragma mark -
#pragma mark instance methods

/**
 * Initialize this instance with database file path.
 * @param dbFilePath is used to initialize FMDatabaseQueue.
 * @return a created instance or nil if it failed.
 */
- (id) initWithFilePath:dbFilePath;

/**
 * Initialize this instace with database file path and backup file path.
 * backup file path is used to copy when opening a file for dbFilePath.
 * And while opening the database, dbFilePath is used. Afte closing the
 * db, then copy the working file to backupPath.
 * This is used to avoid corrupt the working database file bacause of
 * crash.
 * @param dbFilePath working db file path.
 * @param backupPath a valid database path.
 */
- (id) initWithFilePath:dbFilePath backupPath:backupPath;

/**
 * close database and set to nil to avoid accessing the db anymore.
 */
- (void) close;


/**
 * Close database if it is not closed yet. And then
 * remove database file if it exists.
 */
- (void) remove;


/**
 * Check this instance is a default instance or not.
 * @return true if this instance is a default one.
 */
- (BOOL) isDefault;


/**
 * Set this instance as a default HAEntityManager.
 */
- (void) setDefault;


/**
 * This method is called from a simple query or update.
 * If this method is called in transaction block,
 * handler is called with transaction's FMDatabase.
 * Otherwise, it is called in inDatabase.
 * @param block is called with FMDatabase instance.
 */
- (void) inDatabase:(void (^)(FMDatabase *db))block;


/**
 * This method is called from a user code to use transaction block.
 * This is expected call like the following block.
 * [manager transaction:^(FMDatabase* db, BOOL* rollback) {
 *    [EntitySample1 save];
 *    [EntitySample2 remove];
 * }];
 * @param block is called from inside of inTransaction block.
 * if *rollback = TRUE is called, it is set to inTransaction's rollback
 * parameter and will be handled as rollback.
 */
- (void) inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;



/**
 * When the same entity class is used in several EntityManager,
 * this block can use a specific HAEntityManager instance.
 * This can affect for instance method and instanceForEntity method.
 * instance:dbPath is not affected because it points a specific instance.
 * This can help to test this classes using different file.
 */
- (void) useInstance:(void (^)(HAEntityManager* entityManager))block;


/**
 * Add HABaseEntity class to this instance. After adding it,
 * instanceForEntity can return this EntityManager instance
 * for a specific class.
 * @param entityClass is a registered class.
 */
- (void) addEntityClass:(Class) entityClass;

/**
 * Remove added entityClass entry from this instance.
 * @param entityClass is a registered class.
 */
- (void) removeEntityClass:(Class) entityClass;

- (BOOL) isAddedEntityClass:(Class)entityClass;

/**
 * migrate to higher version.
 * @param toVersion is the highest version which is included.
 */
- (void) up:(NSInteger)toVersion;

/**
 * This is the same as up:INT_MAX migratings:migratings, ...
 */
- (void) upToHighestVersion;

/**
 * migrate to lower version.
 * @param toVersion is the lowest version which is included.
 */
- (void) down:(NSInteger)toVersion;

/**
 * This is the same as down:INT_MIN migratings:migratings, ...
 */
- (void) downToLowestVersion;


/**
 * If HABaseEntity derived classes are not used to migrate
 * db, this method can use to add each HAEntityMigrating instances.
 */
- (void) addEntityMigrating:(id<HAEntityMigrating>) migrating;

- (void) removeEntityMigrating:(id<HAEntityMigrating>) migrating;

- (BOOL) isAddedEntityMigrating:(id<HAEntityMigrating>) migrating;

@end
