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
#import <Foundation/Foundation.h>

@interface GooropSQLiteQuery : NSObject

/**
 *  The class which the query belongs to
 */
@property(nonatomic, assign) Class cls;

/**
 *  Primary key value
 */
@property(nonatomic, assign) id primaryKey;

/**
 *  Table name in which is query will be saved
 */
@property(nonatomic, strong) NSString *tableName;

/**
 *  Columns of the query
 */
@property(nonatomic, strong) NSMutableArray *columns;

/**
 *  Values of the query
 */
@property(nonatomic, strong) NSMutableArray *values;

/**
 *  Relationship queries which are required to be save before this query
 */
@property(nonatomic, strong) NSMutableArray *parentQueries;

/**
 *  Relationship queries which are required to be saved after this query
 */
@property(nonatomic, strong) NSMutableArray *childrenQueries;

/**
 *  Returns a list of placeholder from total columns
 *
 *  @return Returns an array of placeholders
 */
- (NSArray *)placeHolders;

/**
 *  Returns a list of column and placeholder from total columns
 *
 *  @return Returns an array of columns and placeholder.
 */
- (NSArray *)updatingPlaceHolders;

/**
 *  Removes the primary key and column, Useful for updating
 */
- (void)removePrimaryKey;

@end
