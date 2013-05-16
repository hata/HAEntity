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


#import <objc/runtime.h>
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "HAEntityManager.h"
#import "HABaseEntity.h"




@implementation HABaseEntity

const static NSString* PROPERTY_TYPE_CHAR = @"c";
const static NSString* PROPERTY_TYPE_SHORT = @"s";
const static NSString* PROPERTY_TYPE_INT = @"i";
const static NSString* PROPERTY_TYPE_LONG = @"l";
const static NSString* PROPERTY_TYPE_LONG_LONG = @"q";
const static NSString* PROPERTY_TYPE_UNSIGNED_CHAR = @"C";
const static NSString* PROPERTY_TYPE_UNSIGNED_INT = @"I";
const static NSString* PROPERTY_TYPE_UNSIGNED_SHORT = @"S";
const static NSString* PROPERTY_TYPE_UNSIGNED_LONG = @"L";
const static NSString* PROPERTY_TYPE_UNSIGNED_LONG_LONG = @"Q";
const static NSString* PROPERTY_TYPE_BOOL = @"B";
const static NSString* PROPERTY_TYPE_FLOAT = @"f";
const static NSString* PROPERTY_TYPE_DOUBLE = @"d";
const static NSString* PROPERTY_TYPE_CLASS_NSDate = @"NSDate";
const static NSString* PROPERTY_TYPE_CLASS_NSString = @"NSString";
const static NSString* PROPERTY_TYPE_CLASS_NSData = @"NSData";


+ (NSString*)addRequiredColumns:(NSString*)selectColumns {
    return selectColumns;
}



#pragma mark -
#pragma mark query methods

+ (id) find_first
{
    return [self find_first:nil params:nil list:NULL];
}

+ (id) find_first:(NSString*)where params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        return [self find_first:where params:params list:args];
    } else {
        return [self find_first:where params:nil list:NULL];
    }
}

+ (id) find_first:(NSString*)where params:(id)params list:(va_list)args
{
    if (!params || !args) {
        // TODO: This should be able to set limit 1...
        NSArray* results = [self where:where];
        return results != nil && results.count > 0 ? [results objectAtIndex:0] : nil;
    }
    
    // TODO: This should be able to set limit option..
    __block id result = nil;
    [self where_each:^(id entity, BOOL* stop){
        result = entity;
        *stop = TRUE;
    } where:where params:params list:args];
    
    return result;
}

+ (NSArray*) select_all
{
    return [self where:nil];
}

+ (void) select_all:(HABaseEntityEachHandler)block
{
    [self where_each:^(id entity, BOOL* stop) {
        block(entity, stop);
    } where:nil];
}


+ (NSArray*) select:(NSString*)select
{
    return [self select:select params:nil list:NULL];
}

+ (NSArray*) select:(NSString*)select params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        return [self select:select params:params list:args];
    } else {
        return [self select:select params:nil list:NULL];
    }
}

+ (NSArray*) select:(NSString*)select params:(id)params list:(va_list)args
{
    __block NSMutableArray* results = [NSMutableArray new];
    
    [self select_each:^(id entity, BOOL* stop){
        [results addObject:entity];
    } select:select params:params list:args];
    
    return results;
}

+ (void) select_each:(HABaseEntityEachHandler)block select:(NSString*)select
{
    [self select_each:block select:select params:nil list:NULL];
}

+ (void) select_each:(HABaseEntityEachHandler)block select:(NSString*)select params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        [self select_each:block select:select params:params list:args];
    } else {
        [self select_each:block select:select params:nil list:NULL];
    }
}

+ (void) select_each:(HABaseEntityEachHandler)block select:(NSString*)select params:(id)params list:(va_list)args
{
    [self HA_executeQuery:block selectPrefix:@"" sqlPrefix:@"SELECT" condition:[self addRequiredColumns:select] params:params list:args];
}


+ (NSArray*) where:(NSString*)where
{
    return [self where:where params:nil list:NULL];
}

+ (NSArray*) where:(NSString*)where params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        return [self where:where params:params list:args];
    } else {
        return [self where:where params:nil list:NULL];
    }
}

+ (NSArray*) where:(NSString*)where params:(id)params list:(va_list)args
{
    __block NSMutableArray* result = [NSMutableArray new];
    [self where_each:^(id entity, BOOL *stop) {
        [result addObject:entity];
    } where:where params:params list:args];
    return result;
}

+ (void) where_each:(HABaseEntityEachHandler)block where:(NSString*)where
{
    [self where_each:block where:where params:nil list:NULL];
}

+ (void) where_each:(HABaseEntityEachHandler)block where:(NSString*)where params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);

        [self where_each:block where:where params:params list:args];
    } else {
        [self where_each:block where:where params:nil list:NULL];
    }
}

+ (void) where_each:(HABaseEntityEachHandler)block where:(NSString*)where params:(id)params list:(va_list)args
{
    [self HA_executeQuery:block selectPrefix:[self selectPrefix] sqlPrefix:@"WHERE" condition:where params:params list:args];
}


+ (NSArray*) order_by:(NSString*)order_by
{
    return [self order_by:order_by params:nil list:NULL];
}

+ (NSArray*) order_by:(NSString*)order_by params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        return [self order_by:order_by params:params list:args];
    } else {
        return [self order_by:order_by params:nil list:NULL];
    }
}

+ (NSArray*) order_by:(NSString*)order_by params:(id)params list:(va_list)args
{
    __block NSMutableArray* results = [NSMutableArray new];
    
    [self order_by_each:^(id entity, BOOL* stop){
        [results addObject:entity];
    } order_by:order_by params:params list:args];
    
    return results;
}

+ (void) order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by
{
    [self order_by_each:block order_by:order_by params:nil list:NULL];
}

+ (void) order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        [self order_by_each:block order_by:order_by params:params list:args];
    } else {
        [self order_by_each:block order_by:order_by params:nil list:NULL];
    }
}

+ (void) order_by_each:(HABaseEntityEachHandler)block order_by:(NSString*)order_by params:(id)params list:(va_list)args
{
    [self HA_executeQuery:block selectPrefix:[self selectPrefix] sqlPrefix:@"ORDER BY" condition:order_by params:params list:args];
}


#pragma mark -
#pragma mark private methods


+ (int) HA_countParams:(NSString*)params
{
    int paramCount = 0;
    NSUInteger len = [params length];

    for (NSUInteger i = 0;i < len;i++) {
        unichar c = [params characterAtIndex:i];
        // '?' is used for parameter. ':' is named parameter like :name, :value, and so on.
        if (c == '?' || c == ':') {
            paramCount++;
        }
    }

    return paramCount;
}

+ (NSArray*) convertListToArray:(NSString*)condition firstParam:(id)firstParam list:(va_list)args
{
    NSMutableArray* paramList = [NSMutableArray new];
    int paramCount = [self HA_countParams:condition];
    
    if (firstParam) {
        [paramList addObject:firstParam];
        paramCount--;
    }
    
    if (!args) {
        return paramList;
    }
    
    id arg = va_arg(args, id);
    while (arg) {
        [paramList addObject:arg];
        paramCount--;
        arg = va_arg(args, id);
    }
    
    if (paramCount) {
        HA_LOG(@"WARNING: parameter count is incorrect. where:%@ additional params are %d params.", condition, paramCount);
    }
    
    return paramList;
}


+ (void) HA_executeQuery:(HABaseEntityEachHandler)block selectPrefix:(NSString*)selectPrefix sqlPrefix:(NSString*)sqlPrefix condition:(NSString*)condition params:(id)params list:(va_list)args
{
    NSString* querySql = nil;
    NSArray* paramList = nil;
    
    if (condition) {
        paramList = [self convertListToArray:condition firstParam:params list:args];
        querySql = [NSMutableString stringWithFormat:@"%@ %@ %@", selectPrefix, sqlPrefix, condition];
    } else {
        querySql = [self selectPrefix];
    }

    [[HAEntityManager instanceForEntity:self] inDatabase:^(FMDatabase *db) {
        BOOL stop = FALSE;

        HA_ENTITY_FINE(@"HABaseEntity::HA_executeQuery querySQL:'%@' params:%@", querySql, paramList);

        FMResultSet* results = paramList ? [db executeQuery:querySql withArgumentsInArray:paramList] : [db executeQuery:querySql];
        while ([results next]) {
            id entity = [[self alloc] initWithResultSet:results];
            [entity setResultSetToProperties:results];
            block(entity, &stop);
            if (stop) {
                break;
            }
        }
        [results close];

        HA_ENTITY_FINE(@"HABaseEntity::HA_executeQuery last_error_code:%d message:%@", [db lastErrorCode], [db lastErrorMessage]);
    }];
}


#pragma mark -
#pragma mark find

+ (void) find:(HABaseEntityEachHandler)block where:(NSString*)where list:(va_list)args
{
    NSString* querySql = nil;
    NSMutableArray* paramList = nil;

    if (where) {
        int paramCount = [self HA_countParams:where];

        paramList = [NSMutableArray new];
        NSMutableArray* optionalList = [NSMutableArray new];

        id arg = va_arg(args, id);
        while (arg) {
            if (paramCount <= 0) {
                [optionalList addObject:arg];
            } else {
                [paramList addObject:arg];
                paramCount--;
            }
            arg = va_arg(args, id);
        }

        // optionalList contains order by or having

        BOOL paramFound = FALSE;
        for (id optParam in optionalList) {
            if (paramFound) {
                [paramList addObject:optParam];
            } else if ([optParam isKindOfClass:[NSString class]]) {
                NSString* mayHaving = (NSString*)optParam;
                paramCount = [self HA_countParams:mayHaving];
                if (paramCount > 0) {
                    paramFound = TRUE;
                }
            }
        }

        // optionalList should have order by and having text only..
        // having's parameters are added to paramList.
        [optionalList removeObjectsInArray:paramList];

        NSMutableString* buffer = [NSMutableString stringWithFormat:@"%@ WHERE %@", [self selectPrefix], where];
        for (NSString* optParam in optionalList) {
            [buffer appendFormat:@" %@ ", optParam];
        }
        querySql = buffer;
    } else {
        querySql = [self selectPrefix];
    }

    [[HAEntityManager instanceForEntity:self] inDatabase:^(FMDatabase *db) {
        BOOL stop = FALSE;
        FMResultSet* results = [db executeQuery:querySql withArgumentsInArray:paramList];
        while ([results next]) {
            id entity = [[self alloc] initWithResultSet:results];
            [entity setResultSetToProperties:results];
            block(entity, &stop);
            if (stop) {
                break;
            }
        }
        [results close];
    }];
}


+ (NSString*) selectPrefix
{
    return nil;
}


+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName
{
    return propertyName;
}

/**
 * @see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 */
+ (NSString*) convertPropertyToColumnType:(NSString*) propertyType
{
    if ([PROPERTY_TYPE_CLASS_NSString isEqualToString:propertyType]) {
        return @"TEXT";
    } else if ([PROPERTY_TYPE_INT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_CHAR isEqualToString:propertyType] ||
               [PROPERTY_TYPE_SHORT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_LONG isEqualToString:propertyType] ||
               [PROPERTY_TYPE_LONG_LONG isEqualToString:propertyType] ||
               [PROPERTY_TYPE_UNSIGNED_CHAR isEqualToString:propertyType] ||
               [PROPERTY_TYPE_UNSIGNED_INT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_UNSIGNED_SHORT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_UNSIGNED_LONG isEqualToString:propertyType] ||
               [PROPERTY_TYPE_UNSIGNED_LONG_LONG isEqualToString:propertyType] ||
               [PROPERTY_TYPE_BOOL isEqualToString:propertyType]) {
        return @"INTERGER";
    } else if ([PROPERTY_TYPE_FLOAT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_DOUBLE isEqualToString:propertyType]) {
        return @"REAL";
    } else if ([PROPERTY_TYPE_CLASS_NSDate isEqualToString:propertyType]) {
        return @"NUMERIC";
    } else {
        // e.g. NSData
        return @"NONE";
    }
}

// TODO: I don't implement it yet...
// camel class name to underscore plural name and remove prefix text.
+ (NSString*) HA_classNameToTableName:(NSString*) className prefixLength:(NSUInteger)prefixLength
{
    className = [className substringFromIndex:prefixLength]; // remove 'AA' from AABarFoo.
    NSUInteger length = className.length;
    
    // BARFOO => b_a_r_f_o_o . So, the maximum is 2 * length.
    unichar* replaceChars = malloc(sizeof(unichar) * length * 2 + 1);
    NSUInteger replaceIndex = 0;
    
    BOOL uppercase = TRUE;
    for (NSUInteger i = 0;i < length;i++) {
        unichar c = [className characterAtIndex:i];
        if (isupper(c)) {
            if (!uppercase) {
                uppercase = TRUE;
                if (i > 0) {
                    replaceChars[replaceIndex++] = '_';
                }
            }
            replaceChars[replaceIndex++] = tolower(c);
        } else {
            if (uppercase) {
                uppercase = FALSE;
            }
            replaceChars[replaceIndex++] = c;
        }
    }
    replaceChars[replaceIndex] = '\0';
    
    NSMutableString* pluralName = [NSMutableString stringWithCharacters:replaceChars length:replaceIndex];
    free(replaceChars);
    
    // pluralName should be changed to real plural name......
    
    return pluralName;
}


- (id) init
{
    if (self = [super init]) {
    }
    return self;
}

- (id) initWithResultSet:(FMResultSet*)resultSet
{
    if (self = [super init]) {
    }
    return self;
}

- (void) setResultSetToProperties:(FMResultSet*)resultSet
{
    Class entityClass = [self class];

    int columnCount = [resultSet columnCount];
    NSMutableSet* resultColumnSet = [[NSMutableSet alloc] initWithCapacity:columnCount];
    for (int i = 0;i < columnCount;i++) {
        [resultColumnSet addObject:[resultSet columnNameForIndex:i]];
    }
    
    for (HAEntityPropertyInfo* info in [HAEntityPropertyInfo propertyInfoList:entityClass]) {
        if ([resultColumnSet member:info.columnName]) {
            id returnValue = [self convertColumnToPropertyValue:resultSet
                                                   propertyName:info.propertyName
                                                   propertyType:info.propertyType
                                                     columnName:info.columnName];
            [self setValue:returnValue forKey:info.propertyName];
        }
    }
}

- (id) convertColumnToPropertyValue:(FMResultSet*) resultSet propertyName:(NSString*)propertyName propertyType:(NSString*)propertyType columnName:(NSString*)columnName
{
    if ([PROPERTY_TYPE_CLASS_NSString isEqualToString:propertyType]) {
        return [resultSet stringForColumn:columnName];
    } else if ([PROPERTY_TYPE_INT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_SHORT isEqualToString:propertyType] ||
               [PROPERTY_TYPE_CHAR isEqualToString:propertyType]) {
        return [NSNumber numberWithInt:[resultSet intForColumn:columnName]];
    } else if ([PROPERTY_TYPE_LONG isEqualToString:propertyType]) {
        return [NSNumber numberWithLong:[resultSet longForColumn:columnName]];
    } else if ([PROPERTY_TYPE_LONG_LONG isEqualToString:propertyType]) {
        return [NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columnName]];
    } else if ([PROPERTY_TYPE_UNSIGNED_CHAR isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedChar:[resultSet intForColumn:columnName]];
    } else if ([PROPERTY_TYPE_UNSIGNED_INT isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedInt:[resultSet intForColumn:columnName]];
    } else if ([PROPERTY_TYPE_UNSIGNED_SHORT isEqualToString:propertyType]) {
        return [NSNumber numberWithUnsignedShort:[resultSet intForColumn:columnName]];
    } else if ([PROPERTY_TYPE_UNSIGNED_LONG isEqualToString:propertyType]) {
#ifdef FMDB_UNSIGNED_LONG_LONG_INT_FOR_COLUMN
        return [NSNumber numberWithUnsignedLong:[resultSet unsignedLongLongIntForColumn:columnName]];
#else
        return [NSNumber numberWithUnsignedLong:[resultSet longLongIntForColumn:columnName]];
#endif
    } else if ([PROPERTY_TYPE_UNSIGNED_LONG_LONG isEqualToString:propertyType]) {
#ifdef FMDB_UNSIGNED_LONG_LONG_INT_FOR_COLUMN
        return [NSNumber numberWithUnsignedLongLong:[resultSet unsignedLongLongIntForColumn:columnName]];
#else
        return [NSNumber numberWithUnsignedLongLong:[resultSet longLongIntForColumn:columnName]];
#endif
    } else if ([PROPERTY_TYPE_FLOAT isEqualToString:propertyType]) {
        return [NSNumber numberWithDouble:[resultSet doubleForColumn:columnName]];
    } else if ([PROPERTY_TYPE_DOUBLE isEqualToString:propertyType]) {
        return [NSNumber numberWithDouble:[resultSet doubleForColumn:columnName]];
    } else if ([PROPERTY_TYPE_BOOL isEqualToString:propertyType]) {
        return [NSNumber numberWithBool:[resultSet boolForColumn:columnName]];
    } else if ([PROPERTY_TYPE_CLASS_NSDate isEqualToString:propertyType]) {
        return [resultSet dateForColumn:columnName];
    } else if ([PROPERTY_TYPE_CLASS_NSData isEqualToString:propertyType]) {
        return [resultSet dataForColumn:columnName];
    } else {
        return nil;
    }
}


@end
