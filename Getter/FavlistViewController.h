//
//  FaFViewController.h
//  Getter
//
//  Created by Yumitaka Sugimoto on 2013/12/17.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FavlistViewControllerDelegate;  // プロトコル先行宣言

@interface FavlistViewController : UITableViewController
{
}

@property (nonatomic, retain) NSDictionary *followerlistFaF;
@property (weak, nonatomic) IBOutlet UILabel *fafusername;
@property (nonatomic, retain) NSArray *favlistFav;
@property (weak, nonatomic) IBOutlet UILabel *fafscreenname;
@property (weak, nonatomic) IBOutlet UIImageView *fafimage;
@property (nonatomic, retain) NSDictionary *followinglistFaF;

@end
