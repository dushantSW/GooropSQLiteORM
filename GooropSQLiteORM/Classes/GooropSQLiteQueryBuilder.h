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

#import <Foundation/Foundation.h>
#import "GooropSQLiteModel.h"
#import "GooropSQLiteQuery.h"

@interface GooropSQLiteQueryBuilder : NSObject

/**
 *  Builds an array of the queries. It´s an recursive function for
 *  recursivly getting all the child and parents queries in an GooropSQLiteModel object.
 *
 *  for.eg. User contains an Company object, Company contains an Address object.
 *
 *  @param model   The model whose columns and values are to parsed into GooropQuery
 *
 *  @return Returns an array with GooropQuery.
 */
- (GooropSQLiteQuery *) buildQueryForModel: (GooropSQLiteModel *) model;

/**
 *  Returns the current instance of the object as a key-value
 *  dicitionary
 *
 *  @return Returns NSDictionary
 */
- (NSDictionary *) dictionaryRepresentationOfModel: (GooropSQLiteModel *) model;

@end
