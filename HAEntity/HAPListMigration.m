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

#import "HAPListMigration.h"

@implementation HAPListMigration

- (id) initWithVersion:(NSInteger)version
{
    if (self = [super initWithVersion:version]) {
    }
    return self;
}

- (void) addPropertyList:(NSString*)pListPath
{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:pListPath];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* keyString = key;

        if ([keyString length] >= 2 && [[[keyString substringToIndex:2] lowercaseString] isEqualToString:@"up"]) {
            [self addSQLForEntity:nil upSQL:obj downSQL:nil];
        } else if ([keyString length] >= 4 && [[[keyString substringToIndex:4] lowercaseString] isEqualToString:@"down"]) {
            [self addSQLForEntity:nil upSQL:nil downSQL:obj];
        }
    }];
}

@end
