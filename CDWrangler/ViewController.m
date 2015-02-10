//
//  ViewController.m
//  CDWrangler
//
//  Created by Sean Rada on 2/9/15.
//  Copyright (c) 2015 Rigil. All rights reserved.
//








// Example Project Explenation
// This example project represents a data model that has already been migrated.  To go through the steps of migrating model versions follow the steps.

//Step 1: Convert back to 'orginal' version.  Uncomment Blocks A and B in ViewController.m, and comment out Block C.

//Step 2: Change the model version.  Select 'Model.xcdatamodeld' and then in the File Inspector change the Current Model Version from 'Model2' to 'Model'.
//          A green check mark should now appear next to Model2 in the Project Navigator

//Step 3: Revert the Person NSManagedObject subclass.  Change the managed object Person.h and Person.m so that they match the Model version

//Step 4: Run.  Run the project and you should see the two Person objects in the logs, that were created.

//Step 5: Undo Changes.  Change the model version back to 'Model 2'.  Change the Person files back to be consistent with the model.  Comment out Block A and B and uncomment Block C.

//Step 6: Migrate. Now run the project again and you should see in the log that your Person named 'James Smith', now has a firstName of 'James' and a lastName of 'Smith'.

#import "ViewController.h"
#import "CDWrangler.h"
#import "Person.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Migrate Core Data model if needed
    if ([[CDWrangler sharedWrangler] isMigrationNeeded]) {
        // The key is the name of your starting model, and the value is the name of your mapping model.  In this example they are Model.xcdatamodel and MappingModel.xcmappingmodel.  If progressively migrating more than one pair, they should be in ascending order
        [CDWrangler sharedWrangler].mappingsForModels = @{@"Model": @"MappingModel"};
        [[CDWrangler sharedWrangler] migrate];
    }
    
    /*
    //Block A
    Person *newPersonA = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[[CDWrangler sharedWrangler] managedObjectContext]];
    newPersonA.name = @"James Smith";
    newPersonA.age = [NSNumber numberWithInteger:25];
    
    Person *newPersonB = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[[CDWrangler sharedWrangler] managedObjectContext]];
    newPersonB.name = @"John Adams";
    newPersonB.age = [NSNumber numberWithInteger:32];
    
    [[CDWrangler sharedWrangler] saveContext];
    */
    
    //Fetch and print out all person objects
    NSManagedObjectContext *context = [[CDWrangler sharedWrangler] managedObjectContext];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
                                      
    /*
    //Block B
    for (Person *person in fetchedObjects) {
        NSLog(@"Person: %@, name: %@, age: %@ ", person, person.name, person.age);
    }
    */
    
    //Block C
    for (Person *person in fetchedObjects) {
        NSLog(@"Person: %@, firstName: %@, lastName: %@, fullName: %@, age: %@", person, person.firstName, person.lastName, person.fullName, person.age);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
