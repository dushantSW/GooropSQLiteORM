//
//  GooropSQLiteModelMigrator.h
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
#import <JSONModel/JSONModel.h>
#import <objc/runtime.h>

@interface GooropSQLiteModelMigrator : JSONModel

/**
 *  Truncates the table
 *
 *  @return Returns true if table could truncate else false.
 */
+ (BOOL) truncate;

/**
 *  Returns the table name of the model. Table name is by default
 *  same as model name in lower captials
 *
 *  @return Returns NSString
 */
+ (NSString *) tableName;

/**
 *  Check the current model with SQLite.
 *
 *  @return Returns true if model exists in database
 */
+ (BOOL) doesModelExistsInDatabase;

/**
 *  Creates a new table from the class.
 *
 *  @return Returns true if the table was created else false
 */
+ (BOOL)createTableSchema;

/**
 *  Recreates the given table schema. Rebuilding schema will
 *  destroy all the data inside it.
 *
 *  Method compares all the columns from class to the columns
 *  of schema, if even single comparision fails then schema
 *  is re-built else it will return.
 *
 *  @return Yes if schema was rebuilt else NO
 *
 *  @since 1.0
 */
+ (BOOL)recreateTableScehma;

/**
 *  Updates the schema of the self model
 *
 *  @param buildNummer build number of the current application.
 *
 *  @returns true if schema was updated else false is returned.
 *
 *  @since 1.0
 */
+ (BOOL) updateTableSchemaForVersion:(NSInteger)buildNummer;

+ (NSString *) sqliteTypeForProperty: (objc_property_t) property;

@end
