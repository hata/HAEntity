//
//  HATableEntity.h
//  HAEntity
//
//  Created by Hiroki Ata on 13/04/13.
//  Copyright (c) 2013 Hiroki Ata. All rights reserved.
//

#import "HABaseEntity.h"

#import "sqlite3.h"

@interface HATableEntity : HABaseEntity {
@protected
    sqlite_int64 _rowid;
    BOOL _isNew;
}

@property (readonly) sqlite_int64 rowid;

+ (NSString*) tableName;

+ (NSString*) convertPropertyToColumnName:(NSString*) propertyName;
+ (NSString*) convertColumnToPropertyName:(NSString*) columnName;

+ (id) find:(sqlite_int64)rowid;

- (BOOL) save;
- (BOOL) remove;

@end
