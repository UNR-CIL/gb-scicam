//
//  CameraListViewController.m
//  Sensors
//
//  Created by John Jusayan on 12/2/13.
//  Copyright (c) 2013 CSE UNR All rights reserved.
//

#import "SitesViewController.h"
#import "SitePreviewCell.h"
#import <QuartzCore/QuartzCore.h>

#import "Site.h"
#import "Image.h"
#import "NSManagedObject+SCEntityFetchOrInsert.h"

#import "AppDelegate.h"
#import "SiteDetailViewController.h"
#import "CollectionHeaderView.h"

#import "AFNetworking.h"
#import "NSURL+SCUtilities.h"

#import "Project.h"

@interface SitesViewController () <NSFetchedResultsControllerDelegate>


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation SitesViewController

/**Default initializer
 @param Name of the nib
 @param Bundle where the nib is located
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**Called when the view is loaded from a nib or storyboard
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    self.title = @"Sites";
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL sc_projectListURL]];
    
    NSLog(@">>> request %@", request.URL.absoluteString);
    
    
    // Retrieve the list of projects
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSError *error;
            id JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (JSON) {
                NSArray *projects = [(NSDictionary*)JSON valueForKey:@"Data"];
                
                NSMutableArray *allProjects = [NSMutableArray new];

                for (NSDictionary *dictionary in projects) {
                    Project *newProject = [Project projectFromDictionary:dictionary inManagedObjectContext:appDelegate.managedObjectContext];
                    NSLog(@">>> newProj %@", newProject);
                    [allProjects addObject:newProject];
                }
                
                
                // Get a list of sites for each project

                for (Project *project in allProjects) {
                    NSURLSessionDataTask *sessionDataTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL sc_sitesURLForProject:project] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        if (data) {
                            NSError *error;
                            id JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                            if (JSON) {
                                NSArray *sites = [(NSDictionary*)JSON valueForKey:@"Data"];
                                
                                NSMutableArray *allSites = [NSMutableArray new];
                                
                                for (NSDictionary *dictionary in sites) {
                                    Site *newSite = [Site siteFromDictionary:dictionary inManagedObjectContext:appDelegate.managedObjectContext];
                                    newSite.project = project;
                                    newSite.projectName = project.name;
                                    
                                    NSLog(@">>> newSite %@", newSite);
                                    [allSites addObject:newSite];
                                }
                                
                            }
                            else {
                                NSLog(@">>> No valid JSON found");
                            }
                        
                        }
                    }];
                    [sessionDataTask resume];
                }
            }
            else {
                NSLog(@">>> No valid JSON found");
            }

        }
    }];
    [dataTask resume];
    
    
    
    
//    [appDelegate.sharedRequestOperationManager GET:[[NSURL sc_fetchRegionsURL] absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//        NSArray *regionDictionaries = (NSArray*)responseObject;
//        
//        [regionDictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            NSDictionary *regionDictionary = (NSDictionary*)obj;
//            Region *region = [Region regionFromDictionary:regionDictionary inManagedObjectContext:self.managedObjectContext];
//            
//            [appDelegate.sharedRequestOperationManager GET:[[NSURL sc_fetchSitesURLForRegionNamed:region.id] absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                NSArray *siteDictionaries = (NSArray*)responseObject;
//                
//                [siteDictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                    Site *site = [Site siteFromDictionary:obj inManagedObjectContext:self.managedObjectContext];
//                    site.regionName = region.name;
//                    site.region = region;
//                    
//                    NSLog(@">>> Site %@", site);
//                    
//                    [appDelegate.sharedRequestOperationManager GET:[[NSURL sc_fetchLatestItemURLForRegion:[[regionDictionary objectForKey:@"id"] lowercaseString] site:site.alias.lowercaseString] absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                        Image *newImage = [Image imageFromDictionary:responseObject inManagedObjectContext:self.managedObjectContext];
//                        
//                        NSLog(@">>>>] responseObject %@", responseObject);
//                        
//                        if (newImage.data == nil) {
//                            
//                            NSURL *url = [NSURL URLWithString:[newImage.url stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
//                            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
//                            [[NSURLSession sharedSession] dataTaskWithRequest:imageRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//                                if (data) {
//                                    UIImage *image = [[UIImage alloc] initWithData:data];
//                                    if (image) {
//                                        site.thumbnailImage = image;
//                                        site.thumbnailImageDate = newImage.date;
//                                        
//                                        NSError *error;
//                                        [newImage.managedObjectContext save:&error];
//                                    }
//                                }
//                            }];
//                        }
//                        
//                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                        
//                        NSLog(@"%@\n%@", operation, error.userInfo);
//                    }];
//                    
//                }];
//            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                NSLog(@"%@\n%@", operation, error.userInfo);
//            }];
//            
//        }];
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"%@\n%@", operation, error.userInfo);
//    }];
}

/**Automatically called when the system has low memory
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView

/**Called to determine the number of rows in a section for a collection view
 @param Collection view being displayed
 @param The section index being displayed
 @return Number of rows
 */
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

/**Called to determine the number of sections for a collection view
 @param Collection view being displayed
 @return Number of sections
 */
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

/**Provides a reusable collection view cell for a collection view
 @param Collection view being displayed
 @param Index path for the cell
 @return Collection view cell to be displayed
 */
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"SitePreviewCell" forIndexPath:indexPath];
    [self configureCollectionView:collectionView cell:cell atIndexPath:indexPath];
    
    return cell;
}

/**Configures a collecion view cell
 @param Collection view being displayed
 @param The section index being displayed
 */
- (void)configureCollectionView:(UICollectionView*)collectionView cell:(UICollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    SitePreviewCell *sitePreviewCell = (SitePreviewCell*)cell;

    Site *site = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (site.thumbnailImage) {
        sitePreviewCell.imageView.image = site.thumbnailImage;
    }
    else {
        sitePreviewCell.imageView.image = [UIImage imageNamed:@"Landscape"];
    }
    sitePreviewCell.siteNameLabel.text = site.name;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    sitePreviewCell.dateLabel.text = [dateFormatter stringFromDate:site.thumbnailImageDate];
}

/**Provides the header view for the collection view
 @param Collection view being displayed
 @param Type of reusable view
 @param Index path for the header or footer
 @return Reusable view used as a header or footer
 */
- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        CollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CollectionHeaderView" forIndexPath:indexPath];
        
        if (self.fetchedResultsController.fetchedObjects.count) {
            Site *site = [self.fetchedResultsController objectAtIndexPath:indexPath];
            headerView.titleLabel.text = site.projectName;
        }
        
        reusableview = headerView;
    }
    return reusableview;
}

/**Called when a collection view cell is selected by the user
 @param Collection view being displayed
 @param Index path of the selected cell
 */
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"SiteDetailViewController" sender:indexPath];
}

/**Called when the navigation controller is about to perform a segue
 @param Segue being performed
 @param The sending object
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SiteDetailViewController"]) {
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Site *selectedSite = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        
        [segue.destinationViewController setDetailSite:selectedSite];
        [segue.destinationViewController setManagedObjectContext:self.managedObjectContext];
    }
}

#pragma mark - Fetched results controller

/**Manages the fetched objects from the managed object context
 @discussion This also handles sectioning the sites into the proper regions
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Site" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"projectName" cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

/**Called when one of the objects monitored by the fetched results controller changed
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionView reloadData];
}


@end
