//
//  HATableEntity.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntity.h"


@implementation HATableEntity

NSString* PRIMARY_KEY_PROP_NAME = @"rowid";
NSString* PRIMARY_KEY_COLUMN_NAME = @"id";

@synthesize rowid = _rowid;


+ (NSString*) tableName
{
    // TODO: Should resolve automatically from classname.
    // and it may be better to call a delegate to convert classname to table name.
    return nil;
}



+ (NSString*) createTableSQL
{
    NSMutableArray *propertyNames = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *propertyTypes = [NSMutableArray arrayWithCapacity:0];
    
    [self columns:propertyNames columnTypes:propertyTypes];
    
    NSMutableString* buffer = [NSMutableString new];
    
    [buffer appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT", [self tableName], PRIMARY_KEY_COLUMN_NAME];
    
    NSUInteger propertyCount = propertyNames.count;
    for (NSUInteger i = 0;i < propertyCount;i++) {
        [buffer appendFormat:@", %@ %@", [propertyNames objectAtIndex:i], [propertyTypes objectAtIndex:i]];
    }
    [buffer appendString:@");"];
    
    // LOG(@"createTableSQL is %@", buffer);
    
    return buffer;
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
        _rowid = [resultSet intForColumn:PRIMARY_KEY_COLUMN_NAME];
        _isNew = FALSE;
    }
    return self;
}



+ (NSString*) selectPrefix
{
    NSMutableString* buffer = [NSMutableString new];
    [buffer appendFormat:@"SELECT %@", PRIMARY_KEY_COLUMN_NAME];
    
    for (NSString* column in [self columnNames]) {
        [buffer appendFormat:@", %@", column];
    }
    [buffer appendFormat:@" FROM %@", [self tableName]];
    return buffer;
}

+ (id) find:(sqlite_int64)rowid
{
    __block HATableEntity* entity = nil;
    
    NSString* querySQLByPrimaryKey = nil;
    if (nil == querySQLByPrimaryKey) {
        querySQLByPrimaryKey = [NSString stringWithFormat:@"%@ %@", [self selectPrefix], @"WHERE id = ?"];
    }
    
    [[HAEntityManager instanceForEntity:self] accessDatabase:^(FMDatabase *db) {
        FMResultSet* results = [db executeQuery:querySQLByPrimaryKey, [NSNumber numberWithLongLong:rowid]];
        while ([results next]) {
            entity = [[self alloc] initWithResultSet:results];
            [entity setResultSetToProperties:results];
            break;
        }
        [results close];
    }];
    
    return entity;
}


+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName
{
    return [propertyName isEqualToString:PRIMARY_KEY_PROP_NAME] ? PRIMARY_KEY_COLUMN_NAME : propertyName;
}

+ (NSString*) convertColumnToPropertyName:(NSString*) columnName
{
    return [columnName isEqualToString:PRIMARY_KEY_COLUMN_NAME] ? PRIMARY_KEY_PROP_NAME : columnName;
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
}

- (BOOL) save
{
    __block BOOL result = FALSE;
    Class entityClass = [self class];
    
    if (_isNew) {
        
        // Build insert stmt like INSERT table_name (column, ...) values (?,...)
        // and prepare each values.
        NSMutableString* insertSQL = [NSMutableString new];
        NSMutableString* params = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        NSMutableArray* propertyNames = [NSMutableArray new];
        NSMutableArray* propertyTypes = [NSMutableArray new];
        [entityClass properties:propertyNames propertyTypes:propertyTypes];
        NSUInteger propCount = propertyNames.count;
        
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
            result = [db executeUpdate:insertSQL withArgumentsInArray:values];
            _rowid = [db lastInsertRowId];
            _isNew = FALSE;
        }];
    } else {
        // Build insert stmt like UPDATE table_name SET column=?, ... where id = ?;";
        // and prepare each values.
        NSMutableString* updateSQL = [NSMutableString new];
        NSMutableArray* values = [NSMutableArray new];
        
        NSMutableArray* propertyNames = [NSMutableArray new];
        NSMutableArray* propertyTypes = [NSMutableArray new];
        [entityClass properties:propertyNames propertyTypes:propertyTypes];
        NSUInteger propCount = propertyNames.count;
        
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
        [updateSQL appendFormat:@" WHERE %@ = ?", PRIMARY_KEY_COLUMN_NAME];
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
        NSString* deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ where %@ = ?", [entityClass tableName], PRIMARY_KEY_COLUMN_NAME];
        [[HAEntityManager instanceForEntity:entityClass] accessDatabase:^(FMDatabase* db){
            result = [db executeUpdate:deleteSQL, [NSNumber numberWithInt:_rowid]];
        }];
    }
    return result;
}


@end
