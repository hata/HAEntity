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
#import "HATableEntity.h"

@implementation HATableEntity

NSString* ROW_ID_COLUMN_NAME = @"rowid";
static NSCache* CACHE_TABLE = nil;

+ (void) initialize
{
    static BOOL initialized = FALSE;
    if (!initialized) {
        initialized = TRUE;
        CACHE_TABLE = NSCache.new;
    }
}


@synthesize rowid = _rowid;


+ (NSString*) tableName
{
    // TODO: Should resolve automatically from classname.
    // and it may be better to call a delegate to convert classname to table name.
    NSString* className = NSStringFromClass([self class]);
    NSString* exceptionReason = [NSString stringWithFormat:@"%@ doesn't override tableName class method to return a table name.", className];
    [[NSException exceptionWithName:@"NoTableNameFoundException" reason:exceptionReason userInfo:nil] raise];
    return nil;
}

/*
 * If I created this, it may be easy for 1 entity. But,
 * now, I changed migration to use db. So,
 * the version number should set correct one.
 * From this, I comment out this basic behavior.
 * use should do explicitly.
+ (NSArray*) migratings
{
    NSMutableArray* migs = NSMutableArray.new;
    [migs addObject:[[HATableEntityMigration alloc] initWithVersion:1 entityClasses:self, nil]];
    return migs;
}
 */

+ (NSString*) join
{
    return nil;
}

+ (NSString*) queryColumnName:(NSString*)columnName
{
    return [self join] ? [NSString stringWithFormat:@"%@.%@", [self tableName], columnName] : columnName;
}


// TODO: Check code should check more details of columns.
+ (NSString*)addRequiredColumns:(NSString*)selectColumns {
    if (!selectColumns) {
        return nil;
    }

    NSUInteger len = [ROW_ID_COLUMN_NAME length];
    return ([selectColumns length] < len || ![ROW_ID_COLUMN_NAME isEqualToString:[selectColumns substringToIndex:len]]) ?
      [NSString stringWithFormat:@"%@, %@", ROW_ID_COLUMN_NAME, selectColumns] :
      selectColumns;
}


- (id) init
{
    if (self = [super init]) {
        _rowid = -1;
        _isNew = TRUE;
    }
    return self;
}

- (id) initWithResultSet:(FMResultSet*)resultSet
{
    if (self = [super init]) {
        BOOL isRowidSet = FALSE;

        // When a table has INTEGER PRIMARY KEY, rowid column name is changed
        // from rowid to the primary key column. So, the name is changed.
        // In this case, my code expected to return "rowid" column instead of pk.
        // If 'rowid' column is not found, I use first column(index=0) as rowid
        // because my code added rowid column at the first column.
        // If subclass redefine select stmt, it may be different. But,
        // it may be difficult for me to find it. So, right now, current code looks
        // enough to avoid the issue.
        int columnCount = [resultSet columnCount];
        for (int i = 0;i < columnCount;i++) {
            if ([ROW_ID_COLUMN_NAME isEqualToString:[[resultSet columnNameForIndex:i] lowercaseString]]) {
                _rowid = [resultSet longLongIntForColumnIndex:i];
                isRowidSet = TRUE;
                break;
            }
        }
        if (!isRowidSet && columnCount > 0) {
            _rowid = [resultSet longLongIntForColumnIndex:0];
        }
        _isNew = FALSE;
    }
    return self;
}



+ (NSString*) selectPrefix
{
    NSString* cachePrefix = [CACHE_TABLE objectForKey:self];
    if (!cachePrefix) {
        NSMutableString* buffer = [NSMutableString new];
        [buffer appendFormat:@"SELECT %@", [self queryColumnName:ROW_ID_COLUMN_NAME]];
        for (HAEntityPropertyInfo* info in [HAEntityPropertyInfo propertyInfoList:self]) {
            [buffer appendFormat:@", %@", [self queryColumnName:info.columnName]];
        }
        [buffer appendFormat:@" FROM %@", [self tableName]];
        NSString* joinText = [self join];
        if (joinText) {
            [buffer appendFormat:@" %@", joinText];
        }
        
        [CACHE_TABLE setObject:buffer forKey:self];
        return buffer;
    } else {
        return cachePrefix;
    }
}

+ (id) find_by_rowid:(sqlite_int64)rowid
{
    //TODO: cache this...
    NSString* fmt = [NSString stringWithFormat:@"%@ = ?", ROW_ID_COLUMN_NAME];
    return [self find_first:fmt params:[NSNumber numberWithLongLong:rowid], nil];
}


+ (BOOL) remove_all
{
    return [self remove:nil params:nil list:NULL];
}

+ (BOOL) remove:(NSString*)where
{
    return [self remove:where params:nil list:NULL];
}

+ (BOOL) remove:(NSString*)where params:(id)params, ...
{
    if (params) {
        va_list args;
        va_start(args,params);
        va_end(args);
        
        return [self remove:where params:params list:args];
    } else {
        return [self remove:where params:nil list:NULL];
    }
}


+ (BOOL) remove:(NSString*)where params:(id)params list:(va_list)args
{
    NSString* deleteSQL = where != nil ?
      [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", [self tableName], where] :
      [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
    __block BOOL result = FALSE;
    
    [[HAEntityManager instanceForEntity:self] inDatabase:^(FMDatabase* db) {
        if (params) {
            NSArray* paramList = [self convertListToArray:where firstParam:params list:args];
            result = [db executeUpdate:deleteSQL withArgumentsInArray:paramList];
        } else {
            result = [db executeUpdate:deleteSQL];
        }
    }];
    
    return result;
}


- (id) convertToObjectValue:(NSString*)propertyName propertyType:(NSString*)propertyType
{
    // NOTE: This is a workaround to avoid wrong result when storing char property value
    // to SQLite. When I tested CHAR_MAX and CHAR_MIN, the value is stored as 1
    // when return the value from valueForKey.
    // So, I created NSNumber instance via integerValue.

    if ([@"c" isEqualToString:propertyType]) {
        NSNumber* charNumber = [self valueForKey:propertyName];
        return [NSNumber numberWithInt:[charNumber integerValue]];
    } else {
        return [self valueForKey:propertyName];
    }
    return [self valueForKey:propertyName];
}

- (BOOL) save
{
    return [self save:nil list:NULL];
}

- (BOOL) save:(NSString*)properties, ...
{
    if (properties) {
        va_list args;
        va_start(args,properties);
        va_end(args);
        
        return [self save:properties list:args];
    } else {
        return [self save:nil list:NULL];
    }
}


// NSArray for HAEntityPropertyInfo
- (NSArray*) HA_someOfUpdatingProperties:(Class)entityClass properties:(NSString*)properties list:(va_list)args
{
    if (properties) {
        NSMutableSet* updateProperties = NSMutableSet.new;
        [updateProperties addObject:properties];
        
        if (args) {
            id arg = va_arg(args, id);
            while (arg) {
                [updateProperties addObject:arg];
                arg = va_arg(args, id);
            }
        }

        NSMutableArray* list = NSMutableArray.new;
        for (HAEntityPropertyInfo* info in [HAEntityPropertyInfo propertyInfoList:entityClass]) {
            if ([updateProperties member:info.propertyName]) { // TODO: Is this use isEqualsString ???
                [list addObject:info];
            }
        }
        
        return list;
    } else {
        return [HAEntityPropertyInfo propertyInfoList:entityClass includesIfReadOnly:FALSE];
    }
}

- (void) HA_fetchReadonlyProperties:(Class)entityClass database:(FMDatabase*)db rowid:(sqlite_int64)rowid
{
    NSArray* readonlyPropertyInfoList = [HAEntityPropertyInfo propertyInfoList:entityClass includesIfReadOnly:TRUE];
    

    if (readonlyPropertyInfoList.count > 0) {
        
        NSMutableString* buffer = [NSMutableString new];
        BOOL firstColumn = TRUE;
        for (HAEntityPropertyInfo* info in readonlyPropertyInfoList) {
            if (!firstColumn) {
                [buffer appendString:@", "];
            }
            [buffer appendString:[entityClass queryColumnName:info.columnName]];
            firstColumn = FALSE;
        }
        

        NSArray* params = [NSArray arrayWithObject:[NSNumber numberWithLongLong:rowid]];
        NSString* selectReadonlySQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?",
                                       buffer,
                                       [entityClass tableName],
                                       ROW_ID_COLUMN_NAME];
        
        HA_ENTITY_FINE(@"HATableEntity::HA_updateReadonlyProperties executeQuery:'%@' withArray: %@", selectReadonlySQL, params);

        FMResultSet* resultSet = [db executeQuery:selectReadonlySQL withArgumentsInArray:params];
        
        HA_ENTITY_FINE(@"HATableEntity::HA_updateReadonlyProperties last_error_code:%d message:%@", [db lastErrorCode], [db lastErrorMessage]);

        if ([resultSet next]) {
            [self setResultSetToProperties:resultSet];
            [resultSet close];
        }
    }
}


- (BOOL) save:(NSString*)properties list:(va_list)args
{
    __block BOOL result = FALSE;
    Class entityClass = [self class];

    NSArray* propertyInfoList = [self HA_someOfUpdatingProperties:entityClass properties:properties list:args];
    
    if (_isNew) {
        // Build insert stmt like INSERT table_name (column, ...) values (?,...)
        // and prepare each values.
        NSMutableString* insertSQL = [NSMutableString new];
        NSMutableString* params = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [insertSQL appendFormat:@"INSERT INTO %@ (",[entityClass tableName]];
        
        for (HAEntityPropertyInfo* info in propertyInfoList) {
            NSString* propName = info.propertyName;
            NSString* propType = info.propertyType;
            NSString* columnName = info.columnName;
            id value = [self convertToObjectValue:propName propertyType:propType];
            NSString* paramFormat = (nil != value) ? @"?" : @"null";
            
            if (firstColumn) {
                firstColumn = FALSE;
                [insertSQL appendFormat:@"%@", columnName];
                [params appendFormat:@"(%@", paramFormat];
            } else {
                [insertSQL appendFormat:@", %@", columnName];
                [params appendFormat:@",%@", paramFormat];
            }
            
            if (value) {
                [values addObject:value];
            }
        }
        
        // TODO: Define the behavior if there is no need to update column here(AUTOINCREMENT and DEFAULT only.)
        [params appendString:@")"];
        [insertSQL appendFormat:@") VALUES %@;", params];
        
        if (firstColumn) {
            HA_LOG(@"WARNING: There is no column to insert data. SQL is %@", insertSQL);
        }
        
        // insert.
        [[HAEntityManager instanceForEntity:entityClass] inDatabase:^(FMDatabase* db){
            
            HA_ENTITY_FINE(@"HATableEntity::save insertSQL:'%@' withArray: %@", insertSQL, values);

            result = [db executeUpdate:insertSQL withArgumentsInArray:values];

            HA_ENTITY_FINE(@"HATableEntity::save after insertSQL last_error_code:%d message:%@", [db lastErrorCode], [db lastErrorMessage]);

            _rowid = [db lastInsertRowId];
            _isNew = FALSE;

            [self HA_fetchReadonlyProperties:entityClass database:db rowid:_rowid];
        }];

    } else {
        // Build insert stmt like UPDATE table_name SET column=?, ... where id = ?;";
        // and prepare each values.
        NSMutableString* updateSQL = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [updateSQL appendFormat:@"UPDATE %@ SET ",[entityClass tableName]];
        for (HAEntityPropertyInfo* info in propertyInfoList) {
            NSString* propName = info.propertyName;
            NSString* propType = info.propertyType;
            NSString* columnName = info.columnName;
            id value = [self convertToObjectValue:propName propertyType:propType];
            NSString* param = (nil != value) ? @"?" : @"null";
            if (firstColumn) {
                firstColumn = FALSE;
                [updateSQL appendFormat:@"%@=%@", columnName, param];
            } else {
                [updateSQL appendFormat:@", %@=%@", columnName, param];
            }
            if (nil != value) {
                [values addObject:value];
            }
        }
        [updateSQL appendFormat:@" WHERE %@ = ?", ROW_ID_COLUMN_NAME];
        [values addObject:[NSNumber numberWithLongLong:_rowid]];

        [[HAEntityManager instanceForEntity:entityClass] inDatabase:^(FMDatabase* db){

            HA_ENTITY_FINE(@"HATableEntity::save updateSQL:'%@' withArray: %@", updateSQL, values);
            
            result = [db executeUpdate:updateSQL withArgumentsInArray:values];
            
            HA_ENTITY_FINE(@"HATableEntity::save last_error_code:%d message:%@", [db lastErrorCode], [db lastErrorMessage]);
        }];
    }
    return result;
}


- (BOOL) remove
{
    __block BOOL result = FALSE;
    if (!_isNew) {
        // delete
        Class entityClass = [self class];
        NSString* deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ where %@ = ?", [entityClass tableName], ROW_ID_COLUMN_NAME];
        [[HAEntityManager instanceForEntity:entityClass] inDatabase:^(FMDatabase* db){
            result = [db executeUpdate:deleteSQL, [NSNumber numberWithInt:_rowid]];
        }];
    }
    return result;
}

- (id) reload
{
    Class entityClass = [self class];
    NSString* querySql = [NSString stringWithFormat:@"%@ WHERE %@ = ?", [entityClass selectPrefix], ROW_ID_COLUMN_NAME];
    NSArray* paramList = [NSArray arrayWithObject:[NSNumber numberWithLongLong:_rowid]];
    __block BOOL propertyIsLoad = FALSE;
    
    [[HAEntityManager instanceForEntity:entityClass] inDatabase:^(FMDatabase *db) {
        FMResultSet* results = [db executeQuery:querySql withArgumentsInArray:paramList];

        HA_ENTITY_FINE(@"HATableEntity::reload last_error_code:%d message:%@", [db lastErrorCode], [db lastErrorMessage]);

        while ([results next]) {
            [self setResultSetToProperties:results];
            propertyIsLoad = TRUE;
            break;
        }
        [results close];
    }];

    return propertyIsLoad ? self : nil;
}

- (NSNumber*) rowidNum
{
    return [NSNumber numberWithLongLong:_rowid];
}

@end
