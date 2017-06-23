//
//  InfoContinuViewController.m
//  rfj
//
//  Created by Gonçalo Girão on 18/05/2017.
//  Copyright © 2017 Genius App Sarl. All rights reserved.
//

#import "GalerieDetailViewController.h"
#import <MagicalRecord/MagicalRecord.h>
#import <GoogleMobileAds/DFPInterstitial.h>
#import "Constants.h"
#import "DataManager.h"
#import "CategoryViewController.h"
#import "Validation.h"
#import "MenuItem+CoreDataProperties.h"
#import "MenuItemTableViewCell.h"
#import "MenuManager.h"
#import "NewsCategorySeparatorView.h"
#import "NewsGroupViewController.h"
#import "NewsItem+CoreDataProperties.h"
#import "GalerieDetail+CoreDataProperties.h"
#import "NewsItemTableViewCell.h"
#import "NewsDetailViewController.h"
#import "NewsManager.h"
#import "NewsSeparatorViewWithBackButton.h"
#import "RadioManager.h"
#import "ResourcesManager.h"
#import "WebViewController.h"
#import "GalerieItem+CoreDataProperties.h"
#import "GalerieDetailViewController.h"
#import "GalerieDetail+CoreDataProperties.h"
#import "GalerieDetailTableViewCell.h"
#import "GalerieDetailTopTableViewCell.h"
#import "TGRImageViewController.h"
#import "TGRImageZoomAnimationController.h"
#import "IDMPhotoBrowser/IDMPhotoBrowser.h"


@interface GalerieDetailViewController ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, GADInterstitialDelegate,
GalerieDetailTableViewCellDelegate, GalerieDetailTableViewCellDelegate, UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIWebView *bottomBanner;
@property (weak, nonatomic) IBOutlet NewsSeparatorViewWithBackButton *separatorView;
@property (strong, nonatomic) NSMutableArray<MenuItem *> *menuItems;
@property (strong, nonatomic) NSArray<GalerieDetail *> *galerieDetail;
//@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSArray<NewsItem *> *> *sortedNewsItems;
@property (strong, nonatomic) NSArray<MenuItem *> *allMenuItems;
@property (strong, nonatomic) GalerieDetail *galeriesDetail;
@property (strong, nonatomic) NewsDetail *newsDetail;
@property (assign, nonatomic) NSInteger currentPage;
@property (assign, nonatomic) BOOL isLoading;
@property (strong, nonatomic) NSNumber *activeCategoryId;

@end

@implementation GalerieDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.backgroundColor = [UIColor whiteColor];
    refreshControl.tintColor = [UIColor blackColor];
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.contentTableView;
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = refreshControl;
    
    self.allMenuItems = [MenuItem sortedMenuItems];
    self.galerieDetail = [GalerieDetail MR_findAll];
    
    [[ResourcesManager singleton] fetchResourcesWithSuccessBlock:nil andFailureBlock:nil];
    
    [self loadGalerie:self.newsID];
    
    self.activeCategoryId = [NSNumber numberWithInt:9622];
    //self.activeCategoryId = self.navigationId;
    [self refreshCategory:[self.activeCategoryId intValue]];
    self.currentPage = 0;
    
    //self.isLoading = NO;
    
    NSString *banner = @"<link rel=\"stylesheet\" href=\"http://geniusapp.com/webview.css\" type=\"text/css\" media=\"all\" />";
    banner = [banner stringByAppendingString:@"<div class=\"pub\"><img src='https://ww2.lapublicite.ch/pubserver/www/delivery/avw.php?zoneid=20049&amp;cb=101&amp;n=a77eccf9' border='0' alt='' /></div>"];
    [self.bottomBanner loadHTMLString:banner baseURL:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)homeButtonTapped:(UIButton *)sender {
    NSArray *array = [self.navigationController viewControllers];
    [self.navigationController popToViewController:[array objectAtIndex:0] animated:YES];
}

// Metdodo Som

// Metodo infoReporter

- (void)refreshTable:(id)sender {
    //TODO: refresh your data
    
    //[self.contentTableView reloadData];
    //[self loadNextPage];
    [self.contentTableView.refreshControl endRefreshing];
    
    
}

-(void)refreshCategory:(NSInteger)categoryId
{
    NSInteger menuIndex = [self.allMenuItems indexOfObjectPassingTest:^BOOL(MenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.id == categoryId;
    }];
    
    if(menuIndex == NSNotFound) {
        return;
    }
    
    self.activeCategoryId = @(categoryId);
    self.currentPage = 1;
    
    [self.separatorView setCategoryName:[self.allMenuItems objectAtIndex:menuIndex].name];
    
    [self showLoading];
    
//    [[NewsManager singleton] fetchNewsAtPage:self.currentPage objectType:0 categoryId:categoryId withSuccessBlock:^(NSArray<NewsItem *> *items) {
    [[NewsManager singleton] fetchGalerieDetailForNews:self.newsID successBlock:^(GalerieDetail *galerieDetail) {
        self.galeriesDetail = galerieDetail;
        [self.contentTableView reloadData];
        
        [self hideLoading];
    } andFailureBlock:^(NSError *error, GalerieDetail *oldGalerieDetail) {
        self.galeriesDetail = oldGalerieDetail;
        [self.contentTableView reloadData];
        
        [self hideLoading];
    }];
}

-(void)loadGalerie:(NSNumber *)newsID {
    
    if(VALID(newsID, NSNumber)) {
        
        self.currentGalerie = self.newsID;
        [[NewsManager singleton] fetchGalerieDetailForNews:[newsID integerValue] successBlock:^(GalerieDetail *galeriesDetail) {
            self.galeriesDetail = galeriesDetail;
            //NSLog(@"QUEREMOS FOTOS! %lu", [self.galerieDetails count]);
            
           // [self refreshNews];
            [self.contentTableView reloadData];
            [self hideLoading];
        } andFailureBlock:^(NSError *error, GalerieDetail *oldGalerieDetail) {
            self.galeriesDetail = oldGalerieDetail;
            [self.contentTableView reloadData];
            [self hideLoading];
        //    [self refreshNews];
        }];
    }
    
    if(VALID(newsID, NSNumber)) {
        
        
        [[NewsManager singleton] fetchNewsDetailForNews:[newsID integerValue] successBlock:^(NewsDetail *newsDetail) {
            self.newsDetail = newsDetail;
            
            [self.contentTableView reloadData];
        } andFailureBlock:^(NSError *error, NewsDetail *oldNewsDetail) {
            self.newsDetail = oldNewsDetail;
            
            [self.contentTableView reloadData];
        }];
    }
}

-(void)showLoading {
    [self.loadingView setHidden:NO];
}

-(void)hideLoading {
    [self.loadingView setHidden:YES];
}

#pragma mark - UITableView Delegates
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        if (section == 1) {
            return [self.galeriesDetail.contentGallery count];
        } else {
            return 1;
        }
    
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
        if (indexPath.section == 0) {
            
            GalerieDetailTopTableViewCell *actualCell = (GalerieDetailTopTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"GalerieDetailTopTableViewCell"];
            if(!VALID(actualCell, GalerieDetailTopTableViewCell)) {
                NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"GalerieDetailTopTableViewCell" owner:self options:nil];
                
                if(VALID_NOTEMPTY(views, NSArray)) {
                    actualCell = [views objectAtIndex:0];
                }
            }
            NSString *titleGalerie = self.newsDetail.title;
            NSString *linkGalerie = self.newsDetail.link;
            NSLog(@"LINK: %@", linkGalerie);
            NSString *authorHTML = @"";
            NSArray *contentValue = [self.galerieDetail valueForKey:@"content"];
            if(VALID_NOTEMPTY(contentValue, NSArray)) {
                authorHTML = [contentValue objectAtIndex:0];
            }
            [actualCell setTitle:titleGalerie andAuthor:authorHTML andLink:linkGalerie];
            cell = actualCell;
            return cell;
        }
        GalerieDetailTableViewCell *actualCell = (GalerieDetailTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"newsItemCell"];
        if(!VALID(actualCell, GalerieDetailTableViewCell)) {
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"GalerieDetailTableViewCell" owner:self options:nil];
            
            if(VALID_NOTEMPTY(views, NSArray)) {
                actualCell = [views objectAtIndex:0];
            }
        }
        
        if(VALID(actualCell, GalerieDetailTableViewCell)) {
            cell = actualCell;
            actualCell.delegate = self;
            

            
           
            if(indexPath.row >= 0 && indexPath.row < [self.galeriesDetail.contentGallery count]) {
               
                [actualCell setItem:self.galeriesDetail atIndex:indexPath.row];
                
            }
        }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        if (indexPath.section == 0) {
            return 150;
        }
            
        return ceilf([UIScreen mainScreen].bounds.size.width * 0.6372340425531915);
}

#pragma mark - UIScrollView Delegate

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(scrollView == self.contentTableView) {
        if(scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height && !self.isLoading) {
            //We probably don't want this
            //[self loadNextPage];
        }
    }
}

#pragma mark - NewsItemTableViewCell Delegate

-(void)GalerieDetailDidTap:(GalerieDetailTableViewCell *)item {

    NSIndexPath *index = [self.contentTableView indexPathForCell:item];
    NSLog(@"GALERIE PHOTO TAPPED %ld", (long)index.row);
    NSLog(@"IMAGEM: %@", [self.galeriesDetail.contentGallery objectAtIndex:index.row]);
    NSString *imgConvert = [[self.galeriesDetail.contentGallery objectAtIndex:index.row] valueForKey:@"ImageUrl"];
    NSURL *imageURL = [NSURL URLWithString:imgConvert];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    
    NSMutableArray *ImageUrlArray = [[NSMutableArray alloc] initWithArray:self.galeriesDetail.contentGallery];
    
    NSLog(@"IMAGE URL COUNT: %lu", (unsigned long)ImageUrlArray.count);
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    for(NSDictionary *imageDictionary in ImageUrlArray) {
        if(VALID_NOTEMPTY(imageDictionary, NSDictionary) && NOTEMPTY([imageDictionary objectForKey:@"ImageUrl"])) {
            NSString *urlString = [imageDictionary objectForKey:@"ImageUrl"];
            
            if(VALID_NOTEMPTY(urlString, NSString)) {
                IDMPhoto *photo = [IDMPhoto photoWithURL:[NSURL URLWithString:urlString]];
                [photos addObject:photo];
            }
        }
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:item];
    
    [browser setInitialPageIndex:index.row];
    
    [self presentViewController:browser animated:YES completion:nil];

//    TGRImageViewController *viewController = [[TGRImageViewController alloc] initWithImage:image];
//    // Don't forget to set ourselves as the transition delegate
//    viewController.transitioningDelegate = self;
//    
//    [self presentViewController:viewController animated:YES completion:nil];
//    //[self addImageViewWithImage:image];
//    if(index.row >= 0 && index.row < [self.galerieDetail count]) {
//
//    }
    
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    NSString *imgConvert1 = [[self.galeriesDetail.contentGallery objectAtIndex:0] valueForKey:@"ImageUrl"];
    NSURL *imageURL1 = [NSURL URLWithString:imgConvert1];
    NSData *imageData1 = [NSData dataWithContentsOfURL:imageURL1];
    UIImage *image1 = [UIImage imageWithData:imageData1];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.backgroundColor = [UIColor blackColor];
    imgView.image = image1;

    if ([presented isKindOfClass:TGRImageViewController.class]) {
        return [[TGRImageZoomAnimationController alloc] initWithReferenceImageView:imgView];
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    NSString *imgConvert1 = [[self.galeriesDetail.contentGallery objectAtIndex:0] valueForKey:@"ImageUrl"];
    NSURL *imageURL1 = [NSURL URLWithString:imgConvert1];
    NSData *imageData1 = [NSData dataWithContentsOfURL:imageURL1];
    UIImage *image1 = [UIImage imageWithData:imageData1];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.backgroundColor = [UIColor blackColor];
    imgView.image = image1;

    if ([dismissed isKindOfClass:TGRImageViewController.class]) {
        return [[TGRImageZoomAnimationController alloc] initWithReferenceImageView:imgView];
    }
   return nil;
}

-(void)removeImage {
    
    UIImageView *imgView = (UIImageView*)[self.view viewWithTag:100];
    [imgView removeFromSuperview];
}

-(void)addImageViewWithImage:(UIImage*)image {
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.backgroundColor = [UIColor blackColor];
    imgView.image = image;
    imgView.tag = 100;
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeImage)];
    dismissTap.numberOfTapsRequired = 1;
    [imgView addGestureRecognizer:dismissTap];
    [self.view addSubview:imgView];
}




- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationMaskPortrait;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return FALSE;
}
@end
