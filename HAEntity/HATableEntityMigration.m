//
//  HATableMigration.m
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HATableEntityMigration.h"
#import "HATableEntity.h"

@implementation HATableEntityMigration

@synthesize version = _version;


- (id) initWithVersion:(NSInteger)version entityClasses:(Class)entityClass, ...
{
    if (self = [super init]) {
        _version = version;
        _classes = [NSMutableArray new];

        va_list args;
        va_start(args, entityClass);

        Class clazz = entityClass;
        while (clazz) {
            [_classes addObject:clazz];
            clazz = va_arg(args, Class);
        }
        
        va_end(args);
    }
    return self;
}

- (void) up:(HAEntityManager*)manager database:(FMDatabase*)db
{
    for (Class clazz in _classes) {
        [db executeUpdate:[self createTableSQL:clazz]];
        [manager addEntityClass:clazz];
    }
}

- (void) down:(HAEntityManager*)manager database:(FMDatabase*)db
{
    for (Class clazz in _classes) {
        [manager removeEntityClass:clazz];
        [db executeUpdate:[self dropTableSQL:clazz]];
    }
}

- (NSString*) createTableSQL:(Class)entityClass
{
    NSMutableArray *columnNames = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *columnTypes = [NSMutableArray arrayWithCapacity:0];
    
    [entityClass columns:columnNames columnTypes:columnTypes];
    
    NSMutableString* buffer = [NSMutableString new];
    
    [buffer appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", [entityClass tableName]];

    BOOL firstColunn = TRUE;
    NSUInteger columnCount = columnNames.count;
    for (NSUInteger i = 0;i < columnCount;i++) {
        NSString* fmt = firstColunn ? @"%@ %@" : @", %@ %@";
        firstColunn = FALSE;
        [buffer appendFormat:fmt, [columnNames objectAtIndex:i], [columnTypes objectAtIndex:i]];
    }
    [buffer appendString:@");"];

    return buffer;
}

- (NSString*) dropTableSQL:(Class)entityClass
{
    return [NSString stringWithFormat:@"DROP TABLE %@;", [entityClass tableName]];
}



@end
