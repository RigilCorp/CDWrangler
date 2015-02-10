# CDWrangler
CDWrangler is a CoreData manager that will perform lightweight as well as manual migration of models.

CDWrangler requires ARC.  Tested on iOS 8.1.

## Usage

``` objc
// Migration
if ([[CDWrangler sharedWrangler] isMigrationNeeded]) {
    // The key is the name of your starting model, and the value is the name of your mapping model.  In this example they are Model.xcdatamodel and MappingModel.xcmappingmodel
    [CDWrangler sharedWrangler].mappingsForModels = @{@"Model": @"MappingModel"};
    [[CDWrangler sharedWrangler] migrate];
}

// Create managed object
NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:@"ExampleObject" inManagedObjectContext:[[CDWrangler sharedWrangler] managedObjectContext]];

// Save
[[CDWrangler sharedWrangler] saveContext];
```

## Installation 

Add `CDWrangler.h` and `CDWrangler.m` to your project

``` objc
// CDWrangler.m

//The name of your .xcdatamodeld file
static NSString * const kModelName = @"Model";
```

## Resources

https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/Introduction.html#//apple_ref/doc/uid/TP40004399-CH1-SW1 (Need Apple Developer Account to view)

http://www.objc.io/issue-4/core-data-migration.html


## Example Project Explenation

This example project represents a data model that has already been migrated.  To go through the steps of migrating model versions follow the steps.

Step 1: Convert back to 'orginal' version.  Uncomment Blocks A and B in ViewController.m, and comment out Block C.

Step 2: Change the model version.  Select 'Model.xcdatamodeld' and then in the File Inspector change the Current Model Version from 'Model2' to 'Model'. A green check mark should now appear next to Model in the Project Navigator

Step 3: Revert the Person NSManagedObject subclass.  Change the managed object Person.h and Person.m so that they match the Person entity in the Model version

Step 4: Run.  Run the project and you should see the two Person objects, in the logs, that were created.

Step 5: Undo Changes.  Change the model version back to 'Model 2'.  Change the Person files back to be consistent with the model.  Comment out Block A and B and uncomment Block C.

Step 6: Migrate. Now run the project again and you should see in the log that your Person objects new attributes firstName and lastName created from the original name value. The person named 'James Smith', now has a firstName of 'James' and a lastName of 'Smith'.
