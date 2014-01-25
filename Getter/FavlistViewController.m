//
//  FavlistViewController.m
//  Getter
//
//  Created by Yumitaka Sugimoto on 2013/12/17.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import "FavlistViewController.h"
#import "MasterViewController.h"
#import "ProfileViewController.h"
#import "DetailViewController.h"
#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"

@interface FavlistViewController ()

@end

@implementation FavlistViewController {
    NSDictionary *users_data;
    NSArray *next_cursor_data;
    MasterViewController *master_;
    //NSDictionary *fafview;
}

@synthesize followerlistFaF;
@synthesize followinglistFaF;
@synthesize favlistFav;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"followerlistFaf size = %d", [followerlistFaF count]);
    //return [followerlistFaF count];
    return [favlistFav count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell==nil){
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // 対象インデックスのステータス情報を取り出す
    NSLog(@"ex size = %d", [followerlistFaF count]);
    NSDictionary *favlist = [favlistFav objectAtIndex:indexPath.row];
    // ユーザ情報から screen_name を取り出して表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.text = [favlist objectForKey:@"text"];
    NSDictionary *user = [favlist objectForKey:@"user"];
    //cell.textLabel.numberOfLines = 0;
    //cell.textLabel.font = [UIFont systemFontOfSize:8];
    //cell.textLabel.text = [user objectForKey:@"screen_name"];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.text = [user objectForKey:@"name"];
    NSURL *url = [NSURL URLWithString:[user objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    cell.imageView.image = [UIImage imageWithData:Tweetdata];
    
    return cell;
}

@end
