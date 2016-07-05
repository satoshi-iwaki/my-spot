//
//  MarkerViewController.m
//  MySpot
//
//  Created by Iwaki Satoshi on 2015/11/20.
//  Copyright © 2015年 Satoshi Iwaki. All rights reserved.
//

#import "MarkerViewController.h"

enum MenuIndex {
    MenuIndexTitle = 0,
    MenuIndexPosition,
    MenuIndexMax
};

static NSString *MenueTitles[] = {
    @"Title",
    @"Position",
};

@interface MarkerViewController ()

@end

@implementation MarkerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MenuIndexMax;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    
    switch (indexPath.row) {
        case MenuIndexTitle:
            cell.detailTextLabel.text = self.marker.title;
            break;
        case MenuIndexPosition:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%f, %f", self.marker.position.latitude, self.marker.position.longitude];
            break;
            
        default:
            break;
    }

    cell.textLabel.text = MenueTitles[indexPath.row];

    return cell;
}

- (IBAction)saveButtonClicked:(id)sender {
    NSMutableArray *markers = nil;
    
}

@end
