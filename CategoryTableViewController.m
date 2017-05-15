//
//  CategoryTableViewController.m
//  rfj
//
//  Created by Gonçalo Girão on 02/05/2017.
//  Copyright © 2017 Genius App Sarl. All rights reserved.
//

#import "CategoryTableViewController.h"
#import <MagicalRecord/MagicalRecord.h>
#import <GoogleMobileAds/DFPInterstitial.h>
#import "Constants.h"
#import "DataManager.h"
#import "CategoryViewController.h"
#import "Validation.h"
#import "MainViewController.h"
#import "MenuItem+CoreDataProperties.h"
#import "MenuItemTableViewCell.h"
#import "MenuManager.h"
#import "NewsCategorySeparatorView.h"
#import "NewsGroupViewController.h"
#import "NewsItem+CoreDataProperties.h"
#import "NewsItemTableViewCell.h"
#import "NewsDetailViewController.h"
#import "NewsManager.h"
#import "RadioManager.h"
#import "ResourcesManager.h"
#import "WebViewController.h"
#import "AppOwiz.h"

@interface CategoryTableViewController ()

@property (strong, nonatomic) NSArray<NewsItem *> *newsItems;
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSArray<NewsItem *> *> *sortedNewsItems;
@property (strong, nonatomic) NSArray<MenuItem *> *allMenuItems;


@property (assign, nonatomic) NSInteger currentPage;
@property (assign, nonatomic) BOOL isLoading;

@property (strong, nonatomic) DFPInterstitial *interstitial;
@property (strong, nonatomic) DFPBannerView  *bannerView;

@end

@implementation CategoryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshTable)
                  forControlEvents:UIControlEventValueChanged];
    
    self.allMenuItems = [MenuItem sortedMenuItems];
    self.newsItems = [NewsItem MR_findAllSortedBy:@"updateDate"
                                        ascending:NO];
    //self.newsItems = [NewsItem MR_findAll];
    //NSLog(@"NEWS ITEMS: %@", self.newsItems[0]);
    [[ResourcesManager singleton] fetchResourcesWithSuccessBlock:nil andFailureBlock:nil];
    [self sortNewsItems];
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsItemTableViewCell" bundle:nil] forCellReuseIdentifier:@"newsItemCell"];
    
    
    [self loadNextPage];
    [self loadInterstitial];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadInterstitial];
    
}

- (void)refreshTable {
    //TODO: refresh your data
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    
}

-(NSArray<NewsItem *> *)combinedNewsItems
{
    NSMutableArray<NewsItem *> *items = [[NSMutableArray<NewsItem *> alloc] init];
    
    for(NSNumber *navigationID in [self.sortedNewsItems allKeys]) {
        [items addObjectsFromArray:[self.sortedNewsItems objectForKey:navigationID]];
    }
    
    return items;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)sortNewsItems {
    self.sortedNewsItems = [[NSMutableDictionary<NSNumber *, NSArray<NewsItem *> *> alloc] init];
    
    for(NewsItem *item in self.newsItems) {
        NSArray *sortedItems = nil;
        
        if([self.sortedNewsItems objectForKey:@(item.navigationId)] == nil) {
            sortedItems = [NSArray arrayWithObject:item];
        }
        else {
            sortedItems = [[self.sortedNewsItems objectForKey:@(item.navigationId)] arrayByAddingObject:item];
        }
        
        [self.sortedNewsItems setObject:sortedItems forKey:@(item.navigationId)];
    }
}



-(void)loadInterstitial {
    //self.needsToLoadInterstitial = NO;
    
    NSDictionary *BackendURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BackendURLs" ofType:@"plist"]];
    self.interstitial = [[DFPInterstitial alloc] initWithAdUnitID:[BackendURLs objectForKey:@"DFPInterstitialLoadingLink"]];
    // self.interstitial.delegate = self;
    
    DFPRequest *request = [DFPRequest request];
    request.testDevices = @[kGADSimulatorID, @"40238db35009b7d4b7bf9ac26d418d9e"];
    
    [self.interstitial loadRequest:request];
}

-(void)loadPageItemsForPage:(NSInteger)page count:(NSInteger)count
                    success:(void(^)(NSArray<NewsItem *> *items))successBlock
                    failure:(void(^)(NSError *error))failureBlock {
    self.isLoading = YES;
    
    [[NewsManager singleton] fetchNewsAtPage:page objectType:0 categoryId:-1 withSuccessBlock:^(NSArray<NewsItem *> *items) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoading = NO;
            
            if(successBlock) {
                successBlock(items);
            }
        });
    } andFailureBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoading = NO;
            
            if(failureBlock) {
                failureBlock(error);
            }
        });
    }];
}

-(void)loadNextPage {
    if(self.isLoading) {
        return;
    }
    
    
    
    self.currentPage++;
    
    [self loadPageItemsForPage:self.currentPage count:kItemsPerPage success:^(NSArray<NewsItem *> *items) {
        
        for(NewsItem *item in items) {
            NSInteger itemIndex = [self.newsItems indexOfObjectPassingTest:^BOOL(NewsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return item.id == obj.id;
            }];
            if(itemIndex == NSNotFound) {
                self.newsItems = [self.newsItems arrayByAddingObject:item];
            }
        }
        
        [self sortNewsItems];
        
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        //[self hideLoading];
        
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sortedNewsItems count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSNumber *navigationID = [[self.sortedNewsItems allKeys] objectAtIndex:section];
    return [[self.sortedNewsItems objectForKey:navigationID] count];
    //return [self.newsItems count]; -> uncomment this for ads count
    //return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int rowNumber = indexPath;
    BOOL isMultipleOfSeven = !(rowNumber % 7);
    if (isMultipleOfSeven == TRUE) {
        
    }
    if (rowNumber % 7 == 0 && rowNumber != 0) {
        static NSString *CellIdentifier = @"Cell";
        // Reuse and create cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.textLabel.text = @"Test Data";
        return cell;
    } else {
        UITableViewCell *cell = nil;
        NewsItemTableViewCell *actualCell = (NewsItemTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"newsItemCell"];
        
        if(!VALID(actualCell, NewsItemTableViewCell))
        {
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"NewsItemTableViewCell" owner:self options:nil];
            
            if(VALID_NOTEMPTY(views, NSArray))
            {
                actualCell = [views objectAtIndex:0];
            }
        }
        
        if(VALID(actualCell, NewsItemTableViewCell))
        {
            cell = actualCell;
            NSNumber *navigationID = [[self.sortedNewsItems allKeys] objectAtIndex:indexPath.section];
            NSArray<NewsItem *> *items = [self.sortedNewsItems objectForKey:navigationID];
            //NSLog(@"NUMBER OF ITEMS: %lu", (unsigned long)items.count);
            //NSLog(@"NUMBER OF SECTIONS: %lu", (unsigned long)self.sortedNewsItems.count);
            if(indexPath.row >= 0 && indexPath.row < [self.newsItems count])
            {
                NewsItem *item = [self.newsItems objectAtIndex:indexPath.row];
                
                actualCell.item = item;
                //NSLog(@"ID: %lld", item.id);
                //NSLog(@"NAV ID: %lld", item.navigationId);
                //NSLog(@"UPDATE DATE: %@", item.updateDate);
                
                
            }
        }
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return ceilf([UIScreen mainScreen].bounds.size.width * 0.6372340425531915);
    
    return 44.0f;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"DID SELECT ROW AT INDEXPATH: %@", indexPath.row);
    UITableViewCell *cell = nil;
    NewsItemTableViewCell *actualCell = (NewsItemTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"newsItemCell"];
    cell = actualCell;
    
    NSNumber *navigationID = [[self.sortedNewsItems allKeys] objectAtIndex:indexPath.section];
    NSArray<NewsItem *> *items = [self.sortedNewsItems objectForKey:navigationID];
    
    if(indexPath.row >= 0 && indexPath.row < [self.newsItems count]) {
        NewsItem *item = [self.newsItems objectAtIndex:indexPath.row];
        actualCell.item = item;
        
        NewsGroupViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"newsGroup"];
        if(VALID(controller, NewsGroupViewController)) {
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
                NewsItem *localItem = [item MR_inContext:localContext];
                
                if(VALID(localItem, NewsItem)) {
                    localItem.read = YES;
                }
            }];
            controller.newsToDisplay = [self combinedNewsItems];
            controller.startingIndex = @([controller.newsToDisplay indexOfObjectPassingTest:^BOOL(NewsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return obj == item;
            }]);
            
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}
@end
