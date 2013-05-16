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
    NSMutableString* buffer = [NSMutableString new];
    
    [buffer appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", [entityClass tableName]];
    BOOL firstColunn = TRUE;
    for (HAEntityPropertyInfo* info in [HAEntityPropertyInfo propertyInfoList:entityClass]) {
        NSString* fmt = firstColunn ? @"%@ %@" : @", %@ %@";
        firstColunn = FALSE;
        [buffer appendFormat:fmt, info.columnName, info.columnType];
    }
    [buffer appendString:@");"];

    return buffer;
}

- (NSString*) dropTableSQL:(Class)entityClass
{
    return [NSString stringWithFormat:@"DROP TABLE %@;", [entityClass tableName]];
}



@end
