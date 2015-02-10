//
//  CDWrangler.h
//
//  Created by Sean Rada on 11/24/14.
//  Copyright (c) 2014 Rigil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CDWrangler : NSObject

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

/**A dictionary of the data models, and the mapping models needed to map them to the next model.  Mapping path names have to be the objects, with the associated models file path as the key.  If more than one pair, they should be in ascending order*/
@property (nonatomic) NSDictionary *mappingsForModels;

+ (CDWrangler *)sharedWrangler;

/**Check if the current model needs to be updated*/
- (BOOL)isMigrationNeeded;

/**Will progressivly migrate through all models in the mappingForModels property*/
- (BOOL)migrate;

/**Save managedObjectContext*/
- (void)saveContext;

@end
