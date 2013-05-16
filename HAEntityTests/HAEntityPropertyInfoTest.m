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

#import "HAEntityPropertyInfoTest.h"
#import "HATableEntity.h"

@interface HAEntityPropertyInfoTestSample1 : HATableEntity {
@private
    NSInteger numValue;
    NSString* stringValue;
}

+ (NSString*) tableName;

@property(readonly) NSInteger numValue;
@property NSString* stringValue;

@end

@implementation HAEntityPropertyInfoTestSample1

@synthesize numValue;
@synthesize stringValue;

+ (NSString*)tableName
{
    return @"test_table1";
}
+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName
{
    return [NSString stringWithFormat:@"col_%@", propertyName];
}

+ (NSString*) convertPropertyToColumnType:(NSString*) propertyType
{
    return [NSString stringWithFormat:@"col_%@", propertyType];
}

@end


@implementation HAEntityPropertyInfoTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


- (void)testPropertyInfoList
{
    NSArray* infoList = [HAEntityPropertyInfo propertyInfoList:[HAEntityPropertyInfoTestSample1 class]];
    STAssertEquals((NSUInteger)2, infoList.count, @"Vierfy two properties");
    HAEntityPropertyInfo* info = [infoList objectAtIndex:0];
    STAssertEqualObjects([HAEntityPropertyInfoTestSample1 class], info.entityClass, @"Verify entityClass");
    STAssertEqualObjects(@"numValue", info.propertyName, @"Verify property name");
    STAssertEqualObjects(@"i", info.propertyType, @"Verify property type");
    STAssertEqualObjects(@"col_numValue", info.columnName, @"Verify column name");
    STAssertEqualObjects(@"col_i", info.columnType, @"Verify column type");
    STAssertTrue(info.readOnly, @"Verify readonly attribute");

    info = [infoList objectAtIndex:1];
    STAssertEqualObjects([HAEntityPropertyInfoTestSample1 class], info.entityClass, @"Verify entityClass");
    STAssertEqualObjects(@"stringValue", info.propertyName, @"Verify property name");
    STAssertEqualObjects(@"NSString", info.propertyType, @"Verify property type");
    STAssertEqualObjects(@"col_stringValue", info.columnName, @"Verify column name");
    STAssertEqualObjects(@"col_NSString", info.columnType, @"Verify column type");
    STAssertFalse(info.readOnly, @"Verify readonly attribute");
}

- (void)testPropertyInfoIncludesListReadOnly
{
    NSArray* infoList = [HAEntityPropertyInfo propertyInfoList:[HAEntityPropertyInfoTestSample1 class] includesIfReadOnly:TRUE];
    STAssertEquals((NSUInteger)1, infoList.count, @"Vierfy two properties");
    HAEntityPropertyInfo* info = [infoList objectAtIndex:0];
    STAssertEqualObjects(@"numValue", info.propertyName, @"Verify property name");
    STAssertTrue(info.readOnly, @"Verify readonly attribute");
}

- (void)testPropertyInfoListExcludesReadOnly
{
    NSArray* infoList = [HAEntityPropertyInfo propertyInfoList:[HAEntityPropertyInfoTestSample1 class] includesIfReadOnly:FALSE];
    STAssertEquals((NSUInteger)1, infoList.count, @"Vierfy two properties");
    HAEntityPropertyInfo* info = [infoList objectAtIndex:0];
    STAssertEqualObjects(@"stringValue", info.propertyName, @"Verify property name");
    STAssertFalse(info.readOnly, @"Verify readonly attribute");
}

- (void)testPropertyStringListForPropertyType
{
    NSArray* stringList = [HAEntityPropertyInfo propertyStringList:[HAEntityPropertyInfoTestSample1 class] filterType:HAEntityPropertyInfoFilterTypePropertyType];
    
    STAssertEquals((NSUInteger)2, stringList.count, @"Vierfy two properties");
    STAssertEqualObjects(@"i", [stringList objectAtIndex:0], @"Verify 1st property type");
    STAssertEqualObjects(@"NSString", [stringList objectAtIndex:1], @"Verify 2nd property type");
}

- (void)testPropertyStringListForColumnName
{
    NSArray* stringList = [HAEntityPropertyInfo propertyStringList:[HAEntityPropertyInfoTestSample1 class] filterType:HAEntityPropertyInfoFilterTypeColumnName];
    
    STAssertEquals((NSUInteger)2, stringList.count, @"Vierfy two properties");
    STAssertEqualObjects(@"col_numValue", [stringList objectAtIndex:0], @"Verify 1st column name");
    STAssertEqualObjects(@"col_stringValue", [stringList objectAtIndex:1], @"Verify 2nd column name");
}

- (void)testPropertyStringListForPropertyName
{
    NSArray* stringList = [HAEntityPropertyInfo propertyStringList:[HAEntityPropertyInfoTestSample1 class] filterType:HAEntityPropertyInfoFilterTypeColumnType];
    
    STAssertEquals((NSUInteger)2, stringList.count, @"Vierfy two properties");
    STAssertEqualObjects(@"col_i", [stringList objectAtIndex:0], @"Verify 1st column type");
    STAssertEqualObjects(@"col_NSString", [stringList objectAtIndex:1], @"Verify 2nd column type");
}
@end
