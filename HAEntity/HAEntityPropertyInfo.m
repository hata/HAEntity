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

#import <objc/runtime.h>
#import "HABaseEntity.h"
#import "HATableEntity.h"
#import "HAReadEntity.h"
#import "HAEntityPropertyInfo.h"

@implementation HAEntityPropertyInfo

const static NSString* PROPERTY_ATTR_READONLY = @"R";

// class <-> NSArray<HAEntityPropertyInfo*>
static NSCache* CACHE_TABLE = nil;

+ (void) initialize
{
    static BOOL initialized = FALSE;
    if (!initialized) {
        initialized = TRUE;
        CACHE_TABLE = NSCache.new;
    }
}


@synthesize entityClass = _entityClass;
@synthesize propertyName = _propertyName;
@synthesize propertyType = _propertyType;
@synthesize columnName = _columnName;
@synthesize columnType = _columnType;
@synthesize readOnly = _readOnly;

/*
 * @see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW1
 */
static NSString* HA_getPropertyType(objc_property_t property, NSMutableSet* attrs) {
    const char* attributes = property_getAttributes(property);
    char buffer[strlen(attributes) + 1];
    strcpy(buffer, attributes);
    char *state = buffer;
    char *attribute;
    NSString* type = @"";
    
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            NSData* data = [NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1];
            type = [NSString stringWithCString:(const char *)[data bytes] encoding:NSASCIIStringEncoding];
        } else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            type = @"id";
        } else if (attribute[0] == 'T' && attribute[1] == '@') {
            NSData* data = [NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4];
            type = [NSString stringWithCString:(const char *)[data bytes] encoding:NSASCIIStringEncoding];
        } else if (attrs != nil && attribute[0] == 'R' /* && strlen(attribute) == 1*/) {
            [attrs addObject:PROPERTY_ATTR_READONLY];
        }
    }
    
    return type;
}

+ (NSArray*)propertyInfoList:(Class)entityClass
{
    NSArray* infoList = [CACHE_TABLE objectForKey:entityClass];
    if (infoList) {
        return infoList;
    }

    NSMutableArray* entityClassList = NSMutableArray.new;
    do {
        if ([entityClass isSubclassOfClass:HABaseEntity.class]) {
            [entityClassList addObject:entityClass];
            entityClass = [entityClass superclass];
        } else {
            break;
        }
    } while ((entityClass != HATableEntity.class) &&
             (entityClass != HAReadEntity.class) &&
             (entityClass != HABaseEntity.class));
 
    NSMutableArray* propInfoList = NSMutableArray.new;
    
    for (entityClass in entityClassList) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(entityClass, &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSMutableSet* attrList = [NSMutableSet new];
                NSString* propertyName = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
                NSString* propertyType = HA_getPropertyType(property, attrList);
                
                HAEntityPropertyInfo* info = [[HAEntityPropertyInfo alloc] initWithClass:entityClass propertyName:propertyName propertyType:propertyType propertyAttributes:attrList];
                [propInfoList addObject:info];
            }
        }
        free(properties);
    }
    
    infoList = propInfoList;
    [CACHE_TABLE setObject:infoList forKey:entityClass];

    return infoList;
}

+ (NSArray*)propertyInfoList:(Class)entityClass includesIfReadOnly:(BOOL)includesIfReadOnly
{
    return (includesIfReadOnly) ?
        [[self propertyInfoList:entityClass] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject readOnly];
        }]] :
        [[self propertyInfoList:entityClass] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return ![evaluatedObject readOnly];
        }]];
}

+ (NSArray*)propertyStringList:(Class)entityClass filterType:(HAEntityPropertyInfoFilterType)filterType
{
    NSMutableArray* list = NSMutableArray.new;
    switch (filterType) {
        case HAEntityPropertyInfoFilterTypePropertyName:
            for (HAEntityPropertyInfo* info in [self propertyInfoList:entityClass]) {
                [list addObject:info.propertyName];
            }
            break;
        case HAEntityPropertyInfoFilterTypePropertyType:
            for (HAEntityPropertyInfo* info in [self propertyInfoList:entityClass]) {
                [list addObject:info.propertyType];
            }
            break;
        case HAEntityPropertyInfoFilterTypeColumnName:
            for (HAEntityPropertyInfo* info in [self propertyInfoList:entityClass]) {
                [list addObject:info.columnName];
            }
            break;
        case HAEntityPropertyInfoFilterTypeColumnType:
            for (HAEntityPropertyInfo* info in [self propertyInfoList:entityClass]) {
                [list addObject:info.columnType];
            }
            break;
        default: // This should not occur.
            break;
    }
    
    return list;
}


- (id) initWithClass:(Class)entityClass propertyName:(NSString*)propertyName propertyType:(NSString*)propertyType propertyAttributes:(NSSet*)propertyAttributes
{
    if (self = [super init]) {
        _entityClass = entityClass;
        _propertyName = propertyName;
        _propertyType = propertyType;
        _columnName = [_entityClass convertPropertyToColumnName:propertyName];
        _columnType = [_entityClass convertPropertyToColumnType:propertyType];
        _readOnly = propertyAttributes.count > 0 && [propertyAttributes member:PROPERTY_ATTR_READONLY];
    }
    return self;
}



@end
