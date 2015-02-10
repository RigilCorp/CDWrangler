//
//  CDWrangler.m
//
//  Created by Sean Rada on 11/24/14.
//  Copyright (c) 2014 Rigil. All rights reserved.
//

#import "CDWrangler.h"
#import <Foundation/Foundation.h>

//The name of your .xcdatamodeld file
static NSString * const kModelName = @"Model";

@implementation CDWrangler

@synthesize managedObjectModel, persistentStoreCoordinator, fetchedResultsController, managedObjectContext;
@synthesize mappingsForModels;

+ (CDWrangler *)sharedWrangler {
    static CDWrangler *sharedInstance;
    
    @synchronized(self) {
        if (!sharedInstance)
            sharedInstance = [CDWrangler new];
    }
    return sharedInstance;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:kModelName
                                                        ofType:@"momd"];
    
    if (!momPath) {
        momPath = [[NSBundle mainBundle] pathForResource:kModelName
                                                  ofType:@"mom"];
    }
    
    NSURL *url = [NSURL fileURLWithPath:momPath];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.sqlite", kModelName]]];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeUrl path]]) {
        
        NSURL *preloadURL = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.sqlite", kModelName]]];
        NSError* err = nil;
        
        if (![[NSFileManager defaultManager] copyItemAtURL:preloadURL toURL:storeUrl error:&err]) {
            NSLog(@"Oops, couldn't copy preloaded data");
        }
    }
    
    NSError *error = nil;
    NSDictionary *options = nil;
    if ([[CDWrangler sharedWrangler] isMigrationNeeded]) {
        options = @{
                    NSInferMappingModelAutomaticallyOption: @YES,
                    NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}
                    };
    }else{
        options = @{
                    NSInferMappingModelAutomaticallyOption: @YES,
                    NSSQLitePragmasOption: @{@"journal_mode": @"WAL"}
                    };
    }
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:[self sourceStoreType]
                                                  configuration:nil
                                                            URL:[self sourceStoreURL]
                                                        options:options
                                                          error:&error]) {
        
        //Error for store creation should be handled in here
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

- (NSURL *)sourceStoreURL
{
    return [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.sqlite", kModelName]]];
}

- (NSString *)sourceStoreType
{
    return NSSQLiteStoreType;
}

- (void)saveContext
{
    NSError *error = nil;
    [[CDWrangler sharedWrangler].managedObjectContext save:&error];
}

#pragma mark - Migration Management

- (BOOL)isMigrationNeeded
{
    NSError *error = nil;
    
    // Check if we need to migrate
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:[self sourceStoreType]
                                                                                              URL:[self sourceStoreURL]
                                                                                            error:&error];
    BOOL isMigrationNeeded = NO;
    
    if (sourceMetadata != nil) {
        NSManagedObjectModel *destinationModel = [self managedObjectModel];
        // Migration is needed if destinationModel is NOT compatible
        isMigrationNeeded = ![destinationModel isConfiguration:nil
                                   compatibleWithStoreMetadata:sourceMetadata];
    }

    return isMigrationNeeded;
}

- (BOOL)migrate
{
    NSURL *sourceStoreURL = [self sourceStoreURL];
    NSString *type = [self sourceStoreType];
    NSManagedObjectModel *finalModel = [self managedObjectModel];
    NSError *error;
    
    return [self progressivelyMigrateURL:sourceStoreURL ofType:type toModel:finalModel error:&error];
}

- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL
                         ofType:(NSString *)type
                        toModel:(NSManagedObjectModel *)finalModel
                          error:(NSError **)error
{
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                                                              URL:sourceStoreURL
                                                                                            error:error];
    if (!sourceMetadata) {
        return NO;
    }
    
    if ([finalModel isConfiguration:nil
        compatibleWithStoreMetadata:sourceMetadata]) {
        if (NULL != error) {
            *error = nil;
        }
        return YES;
    }
    
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]
                                                                    forStoreMetadata:sourceMetadata];
    NSManagedObjectModel *destinationModel = nil;
    NSMappingModel *mappingModel = nil;
    NSString *modelName = nil;
    if (![self getDestinationModel:&destinationModel
                      mappingModel:&mappingModel
                         modelName:&modelName
                    forSourceModel:sourceModel
                             error:error]) {
        return NO;
    }
    NSArray *mappingModels = @[mappingModel];
    NSArray *explicitMappingModels = [self mappingModelsForSourceModel:sourceModel];
    
    if (0 < explicitMappingModels.count) {
        mappingModels = explicitMappingModels;
    }
    
    NSURL *destinationStoreURL = [self destinationStoreURLWithSourceStoreURL:sourceStoreURL
                                                                   modelName:modelName];
    NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                                                 destinationModel:destinationModel];
    
    BOOL didMigrate = NO;
    for (NSMappingModel *mappingModel in mappingModels) {
        didMigrate = [manager migrateStoreFromURL:sourceStoreURL
                                             type:type
                                          options:nil
                                 withMappingModel:mappingModel
                                 toDestinationURL:destinationStoreURL
                                  destinationType:type
                               destinationOptions:nil
                                            error:error];
    }
    
    if (!didMigrate) {
        return NO;
    }
    // Migration was successful, move the files around to preserve the source in case things go bad
    if (![self backupSourceStoreAtURL:sourceStoreURL
          movingDestinationStoreAtURL:destinationStoreURL
                                error:error]) {
        return NO;
    }
    // We may not be at the "current" model yet, so recurse
    return [self progressivelyMigrateURL:sourceStoreURL
                                  ofType:type
                                 toModel:finalModel
                                   error:error];
}

- (BOOL)getDestinationModel:(NSManagedObjectModel **)destinationModel
               mappingModel:(NSMappingModel **)mappingModel
                  modelName:(NSString **)modelName
             forSourceModel:(NSManagedObjectModel *)sourceModel
                      error:(NSError **)error
{
    NSArray *modelPaths = [self modelPaths];
    if (!modelPaths.count) {
        //Throw an error if there are no models
        if (NULL != error) {
            *error = [NSError errorWithDomain:@"Zarra"
                                         code:8001
                                     userInfo:@{ NSLocalizedDescriptionKey : @"No models found!" }];
        }
        return NO;
    }
    
    //See if we can find a matching destination model
    NSManagedObjectModel *model = nil;
    NSMappingModel *mapping = nil;
    NSString *modelPath = nil;
    for (modelPath in modelPaths) {
        model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
        mapping = [NSMappingModel mappingModelFromBundles:@[[NSBundle mainBundle]]
                                           forSourceModel:sourceModel
                                         destinationModel:model];
        //If we found a mapping model then proceed
        if (mapping) {
            break;
        }
    }
    //We have tested every model, if nil here we failed
    if (!mapping) {
        if (NULL != error) {
            *error = [NSError errorWithDomain:@"Zarra"
                                         code:8001
                                     userInfo:@{ NSLocalizedDescriptionKey : @"No mapping model found in bundle" }];
        }
        return NO;
    } else {
        *destinationModel = model;
        *mappingModel = mapping;
        *modelName = modelPath.lastPathComponent.stringByDeletingPathExtension;
    }
    return YES;
}

- (NSArray *)modelPaths
{
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                            inDirectory:nil];
    for (NSString *momdPath in momdArray) {
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                            inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
    }
    NSArray *otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                              inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    return modelPaths;
}

- (NSArray *)mappingModelsForSourceModel:(NSManagedObjectModel *)sourceModel
{
    NSMutableArray *mappingModels = [NSMutableArray new];
    NSString *modelName = [self modelName];

    // Find the mapping model file for the current managed object model
    for (NSString *key in [mappingsForModels allKeys]) {
        if ([modelName isEqual:key]) {
            NSArray *urls = [[NSBundle bundleForClass:[self class]]
                             URLsForResourcesWithExtension:@"cdm"
                             subdirectory:nil];
            for (NSURL *url in urls) {
                if ([url.lastPathComponent rangeOfString:[mappingsForModels valueForKey:key]].length != 0) {
                    NSMappingModel *mappingModel = [[NSMappingModel alloc] initWithContentsOfURL:url];
                    [mappingModels addObject:mappingModel];
                }
            }
        }
    }
    return mappingModels;
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (BOOL)backupSourceStoreAtURL:(NSURL *)sourceStoreURL
   movingDestinationStoreAtURL:(NSURL *)destinationStoreURL
                         error:(NSError **)error
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager moveItemAtPath:sourceStoreURL.path
                              toPath:backupPath
                               error:error]) {
        //Failed to copy the file
        return NO;
    }
    //Move the destination to the source path
    if (![fileManager moveItemAtPath:destinationStoreURL.path
                              toPath:sourceStoreURL.path
                               error:error]) {
        //Try to back out the source move first, no point in checking it for errors
        [fileManager moveItemAtPath:backupPath
                             toPath:sourceStoreURL.path
                              error:nil];
        return NO;
    }
    return YES;
}

- (NSURL *)destinationStoreURLWithSourceStoreURL:(NSURL *)sourceStoreURL
                                       modelName:(NSString *)modelName
{
    // We have a mapping model, time to migrate
    NSString *storeExtension = sourceStoreURL.path.pathExtension;
    NSString *storePath = sourceStoreURL.path.stringByDeletingPathExtension;
    // Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
    return [NSURL fileURLWithPath:storePath];
}

- (NSArray *)allModelPaths
{
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                            inDirectory:nil];
    for (NSString *momdPath in momdArray) {
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                            inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
    }
    NSArray *otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                              inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    return modelPaths;
}

- (NSString *)modelName
{
    NSString *modelName = nil;
    NSArray *modelPaths = [self allModelPaths];
    for (NSString *modelPath in modelPaths) {
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        if ([model isEqual:self]) {
            modelName = modelURL.lastPathComponent.stringByDeletingPathExtension;
            break;
        }
    }
    return modelName;
}

@end
