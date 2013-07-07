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


#import "HABaseEntity.h"

#import "sqlite3.h"



@interface HATableEntity : HABaseEntity {
@protected
    sqlite_int64 _rowid;
    BOOL _isNew;
}

@property (readonly) sqlite_int64 rowid;

+ (NSString*) tableName;
+ (NSString*) join;

+ (id) find_by_rowid:(sqlite_int64)rowid;

// DELETE
+ (BOOL) remove_all;
+ (BOOL) remove:(NSString*)where;
+ (BOOL) remove:(NSString*)where params:(id)params, ... NS_REQUIRES_NIL_TERMINATION;
+ (BOOL) remove:(NSString*)where params:(id)params list:(va_list)args;

- (BOOL) save;
- (BOOL) save:(NSString*)properties, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL) save:(NSString*)properties list:(va_list)args;

- (BOOL) remove;

- (id) reload;

- (NSNumber*) rowidNum;

@end
