//
//  GooropSQLiteQuery.h
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

#import "GooropSQLiteQuery.h"

@implementation GooropSQLiteQuery

- (instancetype)init
{
    if (self = [super init])
    {
        self.columns = [[NSMutableArray alloc] init];
        self.values = [[NSMutableArray alloc] init];
        self.parentQueries = [[NSMutableArray alloc] init];
        self.childernQueries = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)placeHolders
{
    NSMutableArray *holders = [[NSMutableArray alloc] init];
    if ([self.columns count] <= 0) {
        [NSException raise:@"No columns found" format:@"In order to get placeholders columns are requried."];
    }
    
    for (int i = 0; i < [self.columns count]; i++) {
        [holders addObject:@"?"];
    }
    return holders;
}

-(NSArray *)updatingPlaceHolders
{
    NSMutableArray *holders = [[NSMutableArray alloc] init];
    if ([self.columns count] <= 0) {
        [NSException raise:@"No columns found" format:@"In order to get placeholders columns are requried."];
    }
    for (int i = 0; i < [self.columns count]; i++) {
        [holders addObject:[NSString stringWithFormat:@"%@ = ?", [self.columns objectAtIndex:i]]];
    }
    return holders;
}

- (void) removePrimaryKey
{
    NSInteger index = [self.values indexOfObject:self.primaryKey];
    if (index != NSNotFound)
    {
        [self.values removeObject:self.primaryKey];
        [self.columns removeObjectAtIndex:index];
    }
}

@end
