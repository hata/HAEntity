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

#import <Foundation/Foundation.h>

typedef enum HAEntityPropertyInfoFilterType : NSInteger {
    HAEntityPropertyInfoFilterTypePropertyName = 1,
    HAEntityPropertyInfoFilterTypePropertyType,
    HAEntityPropertyInfoFilterTypeColumnName,
    HAEntityPropertyInfoFilterTypeColumnType
} HAEntityPropertyInfoFilterType;


@interface HAEntityPropertyInfo : NSObject {
@private
    Class _entityClass;
    NSString* _propertyName;
    NSString* _propertyType;
    NSString* _columnName;
    NSString* _columnType;
    BOOL _readOnly;
}

@property(readonly) Class entityClass;

@property(readonly) NSString* propertyName;
@property(readonly) NSString* propertyType;

@property(readonly) NSString* columnName;
@property(readonly) NSString* columnType;

@property(readonly) BOOL readOnly;

+ (NSArray*)propertyInfoList:(Class)entityClass;
+ (NSArray*)propertyInfoList:(Class)entityClass includesIfReadOnly:(BOOL)includesIfReadOnly;
+ (NSArray*)propertyStringList:(Class)entityClass filterType:(HAEntityPropertyInfoFilterType)filterType;

- (id) initWithClass:(Class)entityClass propertyName:(NSString*)propertyName propertyType:(NSString*)propertyType propertyAttributes:(NSSet*)propertyAttributes;

@end
