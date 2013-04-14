//
//  HABaseEntity.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAEntityManager.h"
#import "FMDatabase.h"


typedef void (^HABaseEntityEachHandler)(id entity);

/**
 * The base class to access FMDatabase.
 * Call [HADataEntity configure:dbFilePath] before using sub-classes.
 * Right now, this class can only use 1 database file.
 */
@interface HABaseEntity : NSObject

/**
 * This should implement in sub-class because where use this prefix text
 * to execute query.
 * @return a part of sql statement like "SELECT foo FROM bar".
 */
+ (NSString*) selectPrefix;


+ (NSArray*) columnNames;
+ (void) columns:(NSMutableArray*)columnNames columnTypes:(NSMutableArray*)columnTypes;
+ (void) properties:(NSMutableArray*)propertyNames propertyTypes:(NSMutableArray*)propertyTypes;

+ (NSArray*) where:(NSString*) params, ...;
+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params, ...;
+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params list:(va_list)args;


+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName;
+ (NSString*) convertColumnToPropertyName:(NSString*) columnName;


#pragma mark -
#pragma mark instance method

- (id) init;
- (id) initWithResultSet:(FMResultSet*)resultSet;
- (void) setResultSetToProperties:(FMResultSet*)resultSet;

@end
