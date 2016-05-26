//
//  GooropSQLiteQueryBuilder.h
//  goorop-sqlite-orm
//
//  Created by Dushant Singh on 17/08/15.
//  Copyright (c) 2015 Dushant Singh. All rights reserved.
//

// Copyright (c) 2012-2015 Dushant Singh, Tweakers HB.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to
// do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
// IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "GooropSQLiteQueryBuilder.h"
#import "GooropSQLiteQuery.h"
#import <objc/runtime.h>

@implementation GooropSQLiteQueryBuilder

-(GooropSQLiteQuery *)buildQueryForModel:(GooropSQLiteModel *)model
{
    NSDictionary *objectDictionary = [self dictionaryRepresentationOfModel:model];
    
    GooropSQLiteQuery *query = [[GooropSQLiteQuery alloc] init];
    query.tableName = [[model class] tableName];
    query.cls = [model class];
    query.primaryKey = [model valueForKey:[[model class] primaryKey]];
    
    BOOL valueAddable = YES;
    for (id key in objectDictionary)
    {
        valueAddable = YES;
        
        id obj = [objectDictionary objectForKey:key];
        if (obj && ![obj isEqual:[NSNull null]]) {
            if ([obj isKindOfClass:[GooropSQLiteModel class]]) {
                [query.parentQueries addObject:obj];
                obj = [obj valueForKey:[[obj class] primaryKey]];
            } else if ([obj isKindOfClass:[NSArray class]]) {
                BOOL isSQLiteModel = NO;
                
                if ([obj count] > 0) {
                    id childObject = [obj objectAtIndex:0];
                    isSQLiteModel = [childObject isKindOfClass:[GooropSQLiteModel class]];
                }
                
                if (isSQLiteModel) {
                    id className = NSStringFromClass([[obj objectAtIndex:0] class]);
                    [query.childernQueries addObject:@{@"class_name": className,
                                                       @"column_name": key, @"array": obj}];
                    valueAddable = NO;
                } else {
                    obj = [NSKeyedArchiver archivedDataWithRootObject:obj];
                }
            } else if ([obj isKindOfClass:[NSDictionary class]]) {
                obj = [NSKeyedArchiver archivedDataWithRootObject:obj];
            }
            
            if (valueAddable) {
                [[query columns] addObject:key];
                [[query values] addObject:obj];
            }
        }
    }
    
    return query;
}

#pragma mark - Extra operations

/**
 *  Creates an NSDictionary representation of the object.
 *  Thank you! http://hesh.am/2013/01/transform-properties-of-an-nsobject-into-an-nsdictionary/
 *
 *  @return Returns an NSDictionary containing the properties of an object that are not nil
 */
- (NSDictionary *) dictionaryRepresentationOfModel:(GooropSQLiteModel *)model
{
    unsigned int count = 0;
    // Get a list of all properties in the class.
    objc_property_t *properties = class_copyPropertyList([model class], &count);
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = [model valueForKey:key];
        
        // Only add to the NSDictionary if it's not nil.
        if (value)
            [dictionary setObject:value forKey:key];
    }
    
    free(properties);
    return dictionary;
}

@end
