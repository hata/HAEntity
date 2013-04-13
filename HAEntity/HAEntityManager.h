//
//  HAEntityManager.h
//
//  Created by Hiroki Ata on 13/04/10.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"

#ifdef DEBUG
# define LOG(...) NSLog(__VA_ARGS__)
#else
# define LOG(...) ;
#endif

/**
 * HAEntityManager* entityManager = [HAEntityManager instance:dbFilePath];
 * [entityManager save:entity];
 */
@interface HAEntityManager : NSObject {
@private
    FMDatabaseQueue* _dbQueue;
    NSString* _dbFilePath;
    NSMutableSet* _entityClasses;
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


/**
 * Get an instance for a specific entity class.
 * If there is an instance which is called addEntityClass,
 * the instance is returned. Otherwise, return a default instance.
 * @param entityClass is a specific entity class which is searched.
 * @return an instance for the entity class. Otherwise a default instance.
 */
+ (HAEntityManager*) instanceForEntity:(Class)entityClass;


#pragma mark -
#pragma mark instance methods

/**
 * Initialize this instance with database file path.
 * @param dbFilePath is used to initialize FMDatabaseQueue.
 * @return a created instance or nil if it failed.
 */
- (id) initWithFilePath:dbFilePath;


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
- (void) accessDatabase:(void (^)(FMDatabase *db))block;


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
- (void) transaction:(void (^)(FMDatabase *db, BOOL *rollback))block;


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


/**
 * Setup database.
 */
- (void) migrate;


@end
