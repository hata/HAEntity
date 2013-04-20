//
//  HATableEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntity.h"


@implementation HATableEntity

NSString* ROW_ID_COLUMN_NAME = @"rowid";

@synthesize rowid = _rowid;


+ (NSString*) tableName
{
    // TODO: Should resolve automatically from classname.
    // and it may be better to call a delegate to convert classname to table name.
    return nil;
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
        if ([[resultSet columnNameToIndexMap] objectForKey:ROW_ID_COLUMN_NAME]) {
            _rowid = [resultSet longLongIntForColumn:ROW_ID_COLUMN_NAME];
        }
        _isNew = FALSE;
    }
    return self;
}



+ (NSString*) selectPrefix
{
    NSMutableString* buffer = [NSMutableString new];
    [buffer appendFormat:@"SELECT %@", ROW_ID_COLUMN_NAME];
    
    for (NSString* column in [self columnNames]) {
        [buffer appendFormat:@", %@", column];
    }
    [buffer appendFormat:@" FROM %@", [self tableName]];

    return buffer;
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
    
    [[HAEntityManager instanceForEntity:self] accessDatabase:^(FMDatabase* db) {
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
    /*
    __block BOOL result = FALSE;
    Class entityClass = [self class];
    
    NSMutableArray* propertyNames = [NSMutableArray new];
    NSMutableArray* propertyTypes = [NSMutableArray new];
    [entityClass properties:propertyNames propertyTypes:propertyTypes];
    NSUInteger propCount = propertyNames.count;
    
    if (_isNew) {
        
        // Build insert stmt like INSERT table_name (column, ...) values (?,...)
        // and prepare each values.
        NSMutableString* insertSQL = [NSMutableString new];
        NSMutableString* params = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [insertSQL appendFormat:@"INSERT INTO %@ (",[entityClass tableName]];
        for (NSUInteger i = 0;i < propCount;i++) {
            NSString* propName = [propertyNames objectAtIndex:i];
            NSString* propType = [propertyTypes objectAtIndex:i];
            NSString* columnName = [entityClass convertPropertyToColumnName:propName];
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
            
            if ((nil != value)) {
                [values addObject:value];
            }
        }
        
        [params appendString:@")"];
        [insertSQL appendFormat:@") VALUES %@;", params];
        
        if (firstColumn) {
            LOG(@"WARNING: There is no column to insert data. SQL is %@", insertSQL);
        }
        
        // insert.
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            //LOG(@"insert SQL: %@", insertSQL);
            result = [db executeUpdate:insertSQL withArgumentsInArray:values];
            _rowid = [db lastInsertRowId];
            _isNew = FALSE;
        }];
    } else {
        // Build insert stmt like UPDATE table_name SET column=?, ... where id = ?;";
        // and prepare each values.
        NSMutableString* updateSQL = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [updateSQL appendFormat:@"UPDATE %@ SET ",[entityClass tableName]];
        for (NSUInteger i = 0;i < propCount;i++) {
            NSString* propName = [propertyNames objectAtIndex:i];
            NSString* propType = [propertyTypes objectAtIndex:i];
            NSString* columnName = [entityClass convertPropertyToColumnName:propName];
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
        [values addObject:[NSNumber numberWithInt:_rowid]];
        
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            result = [db executeUpdate:updateSQL withArgumentsInArray:values];
        }];
    }
    return result;
     */
    
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


- (void) HA_someOfProperties:(Class)entityClass propertyNames:(NSMutableArray*)propertyNames
               propertyTypes:(NSMutableArray*)propertyTypes properties:(NSString*)properties list:(va_list)args
{
    if (properties) {
        NSMutableArray* savedPropNameList = [NSMutableArray new];
        NSMutableArray* savedPropTypeList = [NSMutableArray new];
        [entityClass properties:savedPropNameList propertyTypes:savedPropTypeList];
        NSUInteger propCount = savedPropNameList.count;
        
        for (NSUInteger i = 0;i < propCount;i++) {
            if ([properties isEqualToString:[savedPropNameList objectAtIndex:i]]) {
                [propertyNames addObject:[savedPropNameList objectAtIndex:i]];
                [propertyTypes addObject:[savedPropTypeList objectAtIndex:i]];
                break;
            }
        }
        
        if (args) {
            id arg = va_arg(args, id);
            while (arg) {
                for (NSUInteger i = 0;i < propCount;i++) {
                    if ([arg isEqualToString:[savedPropNameList objectAtIndex:i]]) {
                        [propertyNames addObject:[savedPropNameList objectAtIndex:i]];
                        [propertyTypes addObject:[savedPropTypeList objectAtIndex:i]];
                        break;
                    }
                }
                
                arg = va_arg(args, id);
            }
        }
    } else {
        [entityClass properties:propertyNames propertyTypes:propertyTypes];
    }
}

- (BOOL) save:(NSString*)properties list:(va_list)args
{
    __block BOOL result = FALSE;
    Class entityClass = [self class];

    NSMutableArray* propertyNames = [NSMutableArray new];
    NSMutableArray* propertyTypes = [NSMutableArray new];
    [self HA_someOfProperties:entityClass propertyNames:propertyNames propertyTypes:propertyTypes properties:properties list:args];
    NSUInteger propCount = propertyNames.count;
    
    if (_isNew) {
        // Build insert stmt like INSERT table_name (column, ...) values (?,...)
        // and prepare each values.
        NSMutableString* insertSQL = [NSMutableString new];
        NSMutableString* params = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [insertSQL appendFormat:@"INSERT INTO %@ (",[entityClass tableName]];
        for (NSUInteger i = 0;i < propCount;i++) {
            NSString* propName = [propertyNames objectAtIndex:i];
            NSString* propType = [propertyTypes objectAtIndex:i];
            NSString* columnName = [entityClass convertPropertyToColumnName:propName];
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
        
        [params appendString:@")"];
        [insertSQL appendFormat:@") VALUES %@;", params];
        
        if (firstColumn) {
            LOG(@"WARNING: There is no column to insert data. SQL is %@", insertSQL);
        }
        
        // insert.
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            //LOG(@"insert SQL: %@", insertSQL);
            result = [db executeUpdate:insertSQL withArgumentsInArray:values];
            _rowid = [db lastInsertRowId];
            _isNew = FALSE;
        }];
    } else {
        // Build insert stmt like UPDATE table_name SET column=?, ... where id = ?;";
        // and prepare each values.
        NSMutableString* updateSQL = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        BOOL firstColumn = TRUE;
        [updateSQL appendFormat:@"UPDATE %@ SET ",[entityClass tableName]];
        for (NSUInteger i = 0;i < propCount;i++) {
            NSString* propName = [propertyNames objectAtIndex:i];
            NSString* propType = [propertyTypes objectAtIndex:i];
            NSString* columnName = [entityClass convertPropertyToColumnName:propName];
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
        [values addObject:[NSNumber numberWithInt:_rowid]];
        
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            result = [db executeUpdate:updateSQL withArgumentsInArray:values];
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
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            result = [db executeUpdate:deleteSQL, [NSNumber numberWithInt:_rowid]];
        }];
    }
    return result;
}




@end
