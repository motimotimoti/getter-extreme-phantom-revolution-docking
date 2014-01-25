//
//  MasterViewController.m
//  Getter
//
//  Created by 大坪裕樹 on 2013/10/22.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

//#import "MasterViewController.h"
#import "DetailViewController.h"
#import "TweetViewController.h"
#import "ProfileViewController.h"
#import "FaFViewController.h"
#import "QuartzCore/QuartzCore.h"
#define SEARCH_HEIGHT   (32.0f)

@interface MasterViewController : UITableViewController <UIAlertViewDelegate, TweetViewControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
{
    UIImage *profileImage;
    UIImage *bannerImage;
    UISearchBar     *m_Srch;
}

@property (nonatomic, retain) UIImage *profileImage;
@property (nonatomic, retain) UIImage *bannerImage;
@property (nonatomic, retain) NSURLConnection *connection;
@property (strong,nonatomic) NSArray *candyArray;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;

@end

#import "SBJson.h"
#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"

@implementation MasterViewController {
    // OAuth認証オブジェクト
    GTMOAuthAuthentication *auth_;
    // 表示中ツイート情報
    NSArray *timelineStatuses_;
    NSArray *timelineStatuses2_;
    NSDictionary *followerlist;
    NSDictionary *followinglist;
    NSArray *favlist;
    NSArray *userstream_timeline;
    NSDictionary *user2;
    NSNumber *myUserID;
}

@synthesize profileImage;
@synthesize bannerImage;
@synthesize connection = _connection;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

// KeyChain登録サービス名
static NSString *const kKeychainAppServiceName = @"KodawariButter";

- (void)viewDidLoad
{
    self.navigationController.navigationBar.barTintColor = [UIColor redColor];
    [super viewDidLoad];
    //SeachBarの設定
    //*****************************************************************
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.tintColor = [UIColor greenColor];
    // Do any additional setup after loading the view, typically from a nib.
    CGRect rc = [[UIScreen mainScreen] applicationFrame];
    // SearchBar
    m_Srch = [[UISearchBar alloc] initWithFrame:CGRectMake( 0, 0, rc.size.width, SEARCH_HEIGHT)];
    [m_Srch setTintColor:[UIColor greenColor]];
    m_Srch.barStyle = UIBarStyleBlack;
    [m_Srch setPlaceholder:@"Search Word"];
    [m_Srch setShowsCancelButton:YES];
    
    [self.view addSubview:m_Srch];
    m_Srch.delegate = self;
    //*****************************************************************
    
    //長押し処理の設定(1件削除)
    //*****************************************************************
    UILongPressGestureRecognizer *longPressGesture01 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(rowButtonAction:)];
    // 1つの指でタップを2回行い2回目は0.8秒押した状態で指のずれは10px以内の条件で発生させたい場合。
    // 指のズレを許容する範囲 10px
    longPressGesture01.allowableMovement = 100;
    // イベントが発生するまでタップする時間 3 秒
    longPressGesture01.minimumPressDuration = 3.0f;
    // タップする回数 1回の場合は[0] 2回の場合は[1]を指定
    longPressGesture01.numberOfTapsRequired = 0;
    // タップする指の数
    longPressGesture01.numberOfTouchesRequired = 1;
    
    // Viewへ関連付けします。
    [self.tableView addGestureRecognizer:longPressGesture01];
    //*****************************************************************
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //tweets = [NSMutableArray array];
    // GTMOAuthAuthenticationインスタンス生成
    // ※自分の登録アプリの Consumer Key と Consumer Secret に書き換えてください
    NSString *consumerKey = @"AlYNIai1ijrgUUmlbfaxg";
    NSString *consumerSecret = @"DeUNpwTEhn0FpuoRQKAwLF7O1dzjvgWEpT2zZhrPc";
    auth_ = [[GTMOAuthAuthentication alloc]
             initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
             consumerKey:consumerKey
             privateKey:consumerSecret];
    
    // 既にOAuth認証済みであればKeyChainから認証情報を読み込む
    BOOL authorized = [GTMOAuthViewControllerTouch
                       authorizeFromKeychainForName:kKeychainAppServiceName
                       authentication:auth_];
    if (authorized) {
        // 認証済みの場合はタイムライン更新
        [self myUserIdGet];
    } else {
        // 未認証の場合は認証処理を実施
        [self asyncSignIn];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 認証処理
- (void)asyncSignIn
{
    NSString *requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    NSString *accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    NSString *authorizeURL = @"https://api.twitter.com/oauth/authorize";
    
    NSString *keychainAppServiceName = @"KodawariButter";
    
    auth_.serviceProvider = @"Twitter";
    auth_.callback = @"http://www.example.com/OAuthCallback";
    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[GTMOAuthViewControllerTouch alloc]
                      initWithScope:nil
                      language:nil
                      requestTokenURL:[NSURL URLWithString:requestTokenURL]
                      authorizeTokenURL:[NSURL URLWithString:authorizeURL]
                      accessTokenURL:[NSURL URLWithString:accessTokenURL]
                      authentication:auth_
                      appServiceName:keychainAppServiceName
                      delegate:self
                      finishedSelector:@selector(authViewContoller:finishWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

// 認証エラー表示AlertViewタグ
static const int kMyAlertViewTagAuthenticationError = 1;

// 認証処理が完了した場合の処理
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    if (error != nil) {
        // 認証失敗
        NSLog(@"Authentication error: %d.", error.code);
        UIAlertView *alertView;
        alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Authentication failed."
                                              delegate:self
                                     cancelButtonTitle:@"Confirm"
                                     otherButtonTitles:nil];
        alertView.tag = kMyAlertViewTagAuthenticationError;
        [alertView show];
    } else {
        // 認証成功
        NSLog(@"Authentication succeeded.");
        // タイムライン表示
        //[self asyncShowHomeTimeline];
        [self myUserIdGet];
    }
}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 再度認証
        [self asyncSignIn];
    }
}

//自分のアカウントの取得
//***********************************************************************************************************
- (void)myUserIdGet
{
    NSURL *url_myID = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
    NSMutableURLRequest *request_myID = [NSMutableURLRequest requestWithURL:url_myID];
    [request_myID setHTTPMethod:@"GET"];
    [auth_ authorizeRequest:request_myID];
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request_myID];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(myUserGetFetcher:finishedWithData:error:)];
}

- (void)myUserGetFetcher:(GTMHTTPFetcher *)fetcher
        finishedWithData:(NSData *)data
                   error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    NSError *jsonError = nil;
    NSDictionary *myuseID = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&jsonError];
    if (myuseID == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    myUserID = [myuseID objectForKey:@"id"];
    NSLog(@"my_id = %@",myUserID);
    [self asyncShowHomeTimeline];
}
//***********************************************************************************************************

// デフォルトのタイムライン処理表示
- (void)asyncShowHomeTimeline
{
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    
    NSLog(@"auth %@",auth_);
    
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

// タイムライン (home_timeline) 取得
- (void)fetchGetHomeTimeline:(NSURL *)url timeLine:(NSString *)tl
{
    // 要求を準備
    //NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:@"GET"];

    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    NSLog(@"%@",[auth_ userData]);
    
    // 非同期通信による取得開始
    if([tl  isEqual: @"tl01"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl02"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher02:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl03"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher03:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl04"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher04:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl05"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher05:finishedWithData:error:)];
    }
}

// タイムライン (home_timeline) 取得応答時
- (void)homeTimelineFetcher:(GTMHTTPFetcher *)fetcher
           finishedWithData:(NSData *)data
                      error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    //statuses = [NSMutableArray array];
    NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (statuses == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    userstream_timeline = statuses;
    [self.tableView reloadData];
    [self streamShowHomeTimeline];
}
    
- (void)homeTimelineFetcher02:(GTMHTTPFetcher *)fetcher
finishedWithData:(NSData *)data
error:(NSError *)error
    {
        if (error != nil) {
            // タイムライン取得時エラー
            NSLog(@"Fetching status/home_timeline error: %d", error.code);
            return;
        }
        
        // タイムライン取得成功
        // JSONデータをパース
        NSError *jsonError = nil;
        NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&jsonError];
        
        // JSONデータのパースエラー
        if (statuses == nil) {
            NSLog(@"JSON Parser error: %d", jsonError.code);
            return;
        }
        
        // データを保持
        timelineStatuses2_ = statuses;
    }

- (void)homeTimelineFetcher03:(GTMHTTPFetcher *)fetcher
             finishedWithData:(NSData *)data
                        error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSDictionary *followerData = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (followerData == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    NSLog(@"statuses size = %d", [followerData count]);
    followerlist = followerData;

}

- (void)homeTimelineFetcher04:(GTMHTTPFetcher *)fetcher
             finishedWithData:(NSData *)data
                        error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSDictionary *followingData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&jsonError];
    
    // JSONデータのパースエラー
    if (followingData == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    followinglist = followingData;
}

- (void)homeTimelineFetcher05:(GTMHTTPFetcher *)fetcher
             finishedWithData:(NSData *)data
                        error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;

    NSArray *favoriteData = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&jsonError];
    
    // JSONデータのパースエラー
    if (favoriteData == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    favlist = favoriteData;
}

//UserStreamの取得
//*********************************************************************************************************
- (void)streamShowHomeTimeline
{
    NSURL *url = [NSURL URLWithString:@"https://userstream.twitter.com/1.1/user.json"];
    NSMutableURLRequest *stream_request = [NSMutableURLRequest requestWithURL:url];
    
    [stream_request setHTTPMethod:@"GET"];
    
    [auth_ authorizeRequest:stream_request];
    
    self.connection = [NSURLConnection connectionWithRequest:stream_request delegate:self];
    
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"%@",response);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //接続切れを防ぐためのタイマー(20分tweetの更新がなければuserstreamの再取得を行う)
    NSTimer *timer =
    [NSTimer
     scheduledTimerWithTimeInterval:1200.0f
     target:self
     selector:@selector(userstreamtimelineUpdate)
     userInfo:nil
     repeats:NO
     ];
    
    NSError *jsonError = nil;
    
    NSMutableArray *userstream_data;
    userstream_data = [NSMutableArray array];
    userstream_data = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingAllowFragments
                                                        error:&jsonError];
    //userstream取得後(headerの取得後)の1番目のデータはfriend情報なので, 2番目からのデータをtimelineにいれる。
    int stream_size = [userstream_data count];
    if(userstream_data != NULL)
    {
        if(stream_size != 1){
            //timerのストップ
            if (timer != nil ) {
                if ( [timer isValid] ) {
                    [timer invalidate];
                }
            }
            NSMutableArray *stream_data;
            stream_data = [NSMutableArray array];
            stream_data = [userstream_timeline mutableCopy];
            [stream_data insertObject:userstream_data atIndex:0];
            userstream_timeline = stream_data;
            [self.tableView reloadData];
            [timer fire]; //timerのスタート
        }
    }
    
    //もしtweet数が30より多くなったらtweetを初期化してhometimelineを取得し直す。
    int timeline_size = [userstream_timeline count];
    if(timeline_size>30){
        userstream_timeline = [NSArray array];
        NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
        NSString *tl01 = @"tl01";
        [self fetchGetHomeTimeline:url01 timeLine:tl01];
    }
}

-(void)userstreamtimelineUpdate
{
    [self.connection cancel];
    [self streamShowHomeTimeline];
}
//*********************************************************************************************************

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [userstream_timeline count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [userstream_timeline objectAtIndex:indexPath.row];
    
    // ツイート本文を表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.font = [UIFont fontWithName:@"Geeza Pro" size:9];
    cell.textLabel.text = [status objectForKey:@"text"];
    
    // ユーザ情報から screen_name を取り出して表示
    NSDictionary *user = [status objectForKey:@"user"];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:8];
    cell.detailTextLabel.text = [user objectForKey:@"screen_name"];
    NSURL *url = [NSURL URLWithString:[user objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    cell.imageView.image = [UIImage imageWithData:Tweetdata];
    
    UIImage *img = [UIImage imageWithData:Tweetdata];  // 切り取り前UIImage
    
    float widthPer = 0.8;  // リサイズ後幅の倍率
    float heightPer = 0.8;  // リサイズ後高さの倍率
    CGSize sz = CGSizeMake(img.size.width*widthPer,
                           img.size.height*heightPer);
    UIGraphicsBeginImageContext(sz);
    [img drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.layer.cornerRadius = 5.0f;
    
    cell.imageView.image = img;
    
    
    UIButton *sampleButton = [ UIButton buttonWithType:UIButtonTypeRoundedRect ];
    UIImage *favo = [UIImage imageNamed:@"getter_favo.png"];
    
    sampleButton.tag = (NSInteger)[status objectForKey:@"id_str"]; // senderで渡すため
    
	// ボタンの位置とサイズを指定する
	sampleButton.frame = CGRectMake(280, 10, 30, 40 );
	// ボタンのラベル文字列を指定する
	//[ sampleButton setTitle:@"★" forState:UIControlStateNormal ];
    [sampleButton setBackgroundImage:favo forState:UIControlStateNormal];
	// ボタンがタップされたときの動作を定義する
	[ sampleButton addTarget:self action:@selector(fetchPostFavorite:) forControlEvents:UIControlEventTouchUpInside ];
	// ボタンを画面に表示する
	[ cell addSubview:sampleButton ];
    
    return cell;
}

//Favoriteの取得
//*********************************************************************************************************
- (void)fetchPostFavorite:(NSString *)sender
{
    NSLog( @"タップされたよ！" );
    
    UIButton *sampleButton = (UIButton *)sender;
    UIImage *favo = [UIImage imageNamed:@"getter_favoed2.png"];
    [sampleButton setBackgroundImage:favo forState:UIControlStateNormal];
    
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites/create.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // idパラメータをURI符号化してbodyにセット
    NSString *body = [NSString stringWithFormat:@"id=%ld", (long)sampleButton.tag];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    
    NSLog(@"body---- %@",body);
    
    
    // 接続開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(tweetFavoriteFetcher:finishedWithData:error:)];
    
}

// favoriteに対する動作
- (void)tweetFavoriteFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if (error != nil) {
        // favorite取得エラー
        NSLog(@"Fetching statuses/favorites/create error: %d", error.code);
        return;
    }
    NSLog( @"お気に入りに登録したよ , %d",error.code );
}
//*********************************************************************************************************

//tweet検索
//*********************************************************************************************************
#pragma mark - 検索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [m_Srch resignFirstResponder];
    
    NSLog(@"検索 : %@", m_Srch.text);
    NSString *hashTag = [NSString stringWithFormat:@"%@", m_Srch.text];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSString *encode = [GTMOAuthAuthentication encodedOAuthParameterForString:hashTag];
    
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:[NSString stringWithFormat:@"%@?q=%@", url, encode]];
    [fetcher setAuthorizer:auth_];
    [fetcher beginFetchWithDelegate:self didFinishSelector:@selector(searchDidComplete:finishedWithData:error:)];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [m_Srch resignFirstResponder];
}

- (void)searchDidComplete:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if( error != nil )
    {
        NSLog(@"error : %d", error.code);
    } else
    {
        NSLog(@"success");
        
        
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        
        NSDictionary *req = [parser objectWithString:str];
        NSLog(@"%@", req);
        
        timelineStatuses_ = [req objectForKey:@"statuses"];
        NSLog(@"%@",timelineStatuses_);
        
        NSLog(@"Count = %d", [timelineStatuses_ count]);
        for( int i = 0; i < [timelineStatuses_ count]; i++ )
        {
            NSDictionary *dict = [timelineStatuses_ objectAtIndex:i];
            NSDictionary *usr = [dict objectForKey:@"user"];
            NSLog(@"%@ : %@", [usr objectForKey:@"screen_name"], [dict objectForKey:@"text"]);
        }
        
        // テーブルを更新
        [self.tableView reloadData];
    }
}
//*********************************************************************************************************

// 指定位置の行で使用する高さの要求
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [userstream_timeline objectAtIndex:indexPath.row];
    
    // ツイート本文をもとにセルの高さを決定
    NSString *content = [status objectForKey:@"text"];
    CGSize labelSize = [content sizeWithFont:[UIFont systemFontOfSize:12]
                           constrainedToSize:CGSizeMake(300, 1000)
                               lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 25;
}

//セルを選択したときにscreen_nameを特定する。
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //特定した人のタイムラインだけを「NSDictionary *title」にいれる。
    NSDictionary *title = [userstream_timeline objectAtIndex:indexPath.row];
    
    //titleから「user」の構造だけをぬきとる。
    user2 = [title objectForKey:@"user"];
    //プロフィール画像用。
    NSURL *url = [NSURL URLWithString:[user2 objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    profileImage = [UIImage imageWithData:Tweetdata];
    
    NSURL *url2 = [NSURL URLWithString:[user2 objectForKey:@"profile_banner_url"]];
    NSData *Tweetdata2 = [NSData dataWithContentsOfURL:url2];
    bannerImage = [UIImage imageWithData:Tweetdata2];
    
    NSString *scname = [user2 objectForKey:@"screen_name"];
    NSString *str_cid = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=%@",scname];
    NSURL *url02 = [NSURL URLWithString:[str_cid stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl02 = @"tl02";
    [self fetchGetHomeTimeline:url02 timeLine:tl02];
    
    NSString *scname_followerlist = [user2 objectForKey:@"screen_name"];
    NSString *str_cid_followerlist = [NSString stringWithFormat:@"https://api.twitter.com/1.1/followers/list.json?screen_name=%@",scname_followerlist];
    NSURL *url03 = [NSURL URLWithString:[str_cid_followerlist stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl03 = @"tl03";
    [self fetchGetHomeTimeline:url03 timeLine:tl03];
    
    NSString *scname_followinglist = [user2 objectForKey:@"screen_name"];
    NSString *str_cid_followinglist = [NSString stringWithFormat:@"https://api.twitter.com/1.1/friends/list.json?screen_name=%@",scname_followinglist];
    NSURL *url04 = [NSURL URLWithString:[str_cid_followinglist stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl04 = @"tl04";
    [self fetchGetHomeTimeline:url04 timeLine:tl04];
    
    NSString *scname_favlist = [user2 objectForKey:@"screen_name"];
    NSString *str_cid_favlist = [NSString stringWithFormat:@"https://api.twitter.com/1.1/favorites/list.json?screen_name=%@",scname_favlist];
    NSURL *url05 = [NSURL URLWithString:[str_cid_favlist stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl05 = @"tl05";
    [self fetchGetHomeTimeline:url05 timeLine:tl05];
    
}

// ツイート投稿要求
- (void)fetchPostTweet:(NSString *)text
{
    // 要求を準備
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // statusパラメータをURI符号化してbodyにセット
    NSString *encodedText = [GTMOAuthAuthentication encodedOAuthParameterForString:text];
    NSString *body = [NSString stringWithFormat:@"status=%@", encodedText];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 接続開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(postTweetFetcher:finishedWithData:error:)];
}

// ツイート投稿要求に対する応答
- (void)postTweetFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if (error != nil) {
        // ツイート投稿取得エラー
        NSLog(@"Fetching error: %d", error.code);
        return;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTweetView"]) {
        [segue.destinationViewController setDelegate:self];
    }else if ([[segue identifier] isEqualToString:@"reply"]) {
        [segue.destinationViewController setDelegate:self];
        
        TweetViewController *tweetViewController = (TweetViewController*)[segue destinationViewController];
        tweetViewController.username = [user2 objectForKey:@"screen_name"];

    }else if ([[segue identifier] isEqualToString:@"showProfileView"]) {
        ProfileViewController *profileViewController = (ProfileViewController*)[segue destinationViewController];
        
        profileViewController.username = [user2 objectForKey:@"screen_name"];
        profileViewController.name = [user2 objectForKey:@"name"];
        [profileViewController setProf:self.profileImage];
        profileViewController.tweets = [user2 objectForKey:@"statuses_count"];
        profileViewController.following = [user2 objectForKey:@"friends_count"];
        profileViewController.followers = [user2 objectForKey:@"followers_count"];
        [profileViewController setBann:self.bannerImage];
        
        profileViewController.timeline =  timelineStatuses2_;

        NSLog(@"master followerlist size = %d", [followerlist count]);
        profileViewController.followerlistPro = followerlist;
        profileViewController.followinglistPro = followinglist;
        profileViewController.favlistPro = favlist;
        profileViewController.auth = auth_;
    }
}

// TweetViewでCancelが押された
- (void)tweetViewControllerDidCancel:(TweetViewController *)viewController
{
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
}

// TweetViewでDoneが押された
-(void)tweetViewControllerDidFinish:(TweetViewController *)viewController
                            content:(NSString *)content
{
    // ツイートを投稿する
    if ([content length] > 0) {
        [self fetchPostTweet:content];
    }
    
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
    
}

//TableViewのCellが長押しされたときの処理。
-(IBAction)rowButtonAction:(UILongPressGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    NSLog(@"indexPath ===== %d",indexPath.row);
    if (indexPath == nil){
        NSLog(@"long press on table view");
    }else if (((UILongPressGestureRecognizer *)gestureRecognizer).state == UIGestureRecognizerStateBegan){
        NSDictionary *title_long = [userstream_timeline objectAtIndex:indexPath.row];
        NSNumber *userTweetID_long = [title_long objectForKey:@"id"];
        NSDictionary *user_long = [title_long objectForKey:@"user"];
        NSNumber *userID_long = [user_long objectForKey:@"id"];
        if ([userID_long isEqualToNumber:myUserID]) {
            //int timeline_count = [userstream_timeline count];
            NSMutableArray *timeline_save;
            timeline_save = [NSMutableArray array];
            timeline_save = [userstream_timeline mutableCopy];
            [timeline_save removeObjectAtIndex:indexPath.row];
            userstream_timeline = timeline_save;
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]  withRowAnimation:UITableViewRowAnimationFade];
            NSString *userDestroy = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/destroy/%@.json",userTweetID_long];
            NSURL *userDestroy_url = [NSURL URLWithString:[userDestroy stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
            NSMutableURLRequest *destroy_request = [NSMutableURLRequest requestWithURL:userDestroy_url];
            [destroy_request setHTTPMethod:@"POST"];
            [auth_ authorizeRequest:destroy_request];
            GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:destroy_request];
            [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(postTweetFetcher:finishedWithData:error:)];
        }
    }
}

@end
