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
 */
@interface HABaseEntity : NSObject

/**
 * This should implement in sub-class because where use this prefix text
 * to execute query.
 * @return a part of sql statement like "SELECT foo FROM bar".
 */
+ (NSString*) selectPrefix;


/**
 * Get column names from property names.
 * This will call convertPropertyToColumnName to get column names.
 * @return column name arrays.
 */
+ (NSArray*) columnNames;

/**
 * Get column names and types from property name and type.
 * This method doesn't query database. So, it may not be
 * the same type as database's one.
 * NSMutableArray* names = [NSMutableArray new];
 * NSMutableArray* types = [NSMutableArray new];
 * [EntityClass columns:names columnTypes:types];
 * You can get names and types and then use the arrays.
 * The index for the both arrays are matched.
 * @param columnNames are a column name list to be returned.
 * @param columnTypes are a column type list to be returned.
 */
+ (void) columns:(NSMutableArray*)columnNames columnTypes:(NSMutableArray*)columnTypes;

/**
 * Get property names from entity class.
 * @return properties.
 */
+ (NSArray*) propertyNames;

/**
 * Get property names and types.
 * @param propertyNames are returned name list.
 * @param propertyTypes are returned type list.
 * This type list is using TypeEncoding.
 * https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 * So, primitive types are like 'i' and 'l'.
 */
+ (void) properties:(NSMutableArray*)propertyNames propertyTypes:(NSMutableArray*)propertyTypes;

/**
 * Call this method to convert property name to column name.
 * Just return propertyName if no need to convert the names.
 * @param propertyName is a name to be converted.
 * @return column name.
 */
+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName;

//+ (NSString*) convertColumnToPropertyName:(NSString*) columnName;

// TODO:
// find_all, find_first,
// find_by_pk, find_by_sql
// find, where, order, having
// join/inner/outer

+ (NSArray*) where:(NSString*) params, ...;
+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params, ...;
+ (void) where_each:(HABaseEntityEachHandler)handler params:(NSString*)params list:(va_list)args;


#pragma mark -
#pragma mark instance method

- (id) init;
- (id) initWithResultSet:(FMResultSet*)resultSet;
- (void) setResultSetToProperties:(FMResultSet*)resultSet;

@end
