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
#import "HAEntityManager.h"
#import "FMDatabase.h"
#import "HAEntityPropertyInfo.h"


typedef void (^HABaseEntityEachHandler)(id entity, BOOL* stop);

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
 * Call this method to convert property name to column name.
 * Just return propertyName if no need to convert the names.
 * @param propertyName is a name to be converted.
 * @return column name.
 */
+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName;
+ (NSString*) convertPropertyToColumnType:(NSString*) propertyType;


+ (id)       find_first;
+ (id)       find_first:(NSString*)where params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)       find_first:(NSString*)where params:(id)params list:(va_list)args;

+ (NSArray*) select_all;
+ (void)     select_all:(HABaseEntityEachHandler)block;

+ (NSArray*) select:(NSString*)select;
+ (NSArray*) select:(NSString*)select params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSArray*) select:(NSString*)select params:(id)params list:(va_list)args;
+ (void)     select_each:(HABaseEntityEachHandler)block select:(NSString*)select;
+ (void)     select_each:(HABaseEntityEachHandler)block select:(NSString*)select params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)     select_each:(HABaseEntityEachHandler)block select:(NSString*)select params:(id)params list:(va_list)args;

+ (NSArray*) where:(NSString*)where;
+ (NSArray*) where:(NSString*)where params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSArray*) where:(NSString*)where params:(id)params list:(va_list)args;
+ (void)     where_each:(HABaseEntityEachHandler)block where:(NSString*)where;
+ (void)     where_each:(HABaseEntityEachHandler)block where:(NSString*)where params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)     where_each:(HABaseEntityEachHandler)block where:(NSString*)where params:(id)params list:(va_list)args;

+ (NSArray*) order_by:(NSString*)order_by;
+ (NSArray*) order_by:(NSString*)order_by params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSArray*) order_by:(NSString*)order_by params:(id)params list:(va_list)args;
+ (void)     order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by;
+ (void)     order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (void)     order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by params:(id)params list:(va_list)args;

/*
 * Helper method. This may be used in sub classes.
 * @param condition contains parameters like col1 = ? and '?' is counted in this method
 * to make warning.
 * @param firstParam is added to the first element in NSArray.
 * @param args is remained parameters.
 * @return [firstParam, args ...]
 *
 */
+ (NSArray*) convertListToArray:(NSString*)condition firstParam:(id)firstParam list:(va_list)args;


#pragma mark -
#pragma mark instance method

- (id) init;
- (id) initWithResultSet:(FMResultSet*)resultSet;
- (void) setResultSetToProperties:(FMResultSet*)resultSet;

@end
