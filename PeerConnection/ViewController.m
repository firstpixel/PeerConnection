//
//  ViewController.m
//  PeerConnection
//
//  Created by Gil Beyruth on 8/27/16.
//  Copyright © 2016 Gil Beyruth. All rights reserved.
//

#import "ViewController.h"
#import "PeerServiceManager.h"

@interface ViewController ()<PeerServiceManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *connectionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *yellowButton;

@end

@implementation ViewController



- (IBAction)openBrowseViewController:(id)sender {
    [[PeerServiceManager sharedInstance] startBrowsingAndAdvertising];
}

- (IBAction)yellowTapped:(id)sender {
    [self changeColor:[UIColor yellowColor]];
    [[PeerServiceManager sharedInstance] sendData:@"yellow"];
}

- (IBAction)redTapped:(id)sender {
    [self changeColor:[UIColor redColor]];
    [[PeerServiceManager sharedInstance] sendData:@"red"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [PeerServiceManager sharedInstance].delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)changeColor: (UIColor*)color {
    self.view.backgroundColor = color;
}


#pragma PeerServiceManagerDelegate
-(void)connectedDevicesChanged:(PeerServiceManager*)peerServiceManager connectedDevices: (NSArray<NSString *>*)connectedDevices totalDevices:(int)totalDevices{
    if(totalDevices > 0){
        
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [_connectButton setHidden:YES];
            [_redButton setHidden:NO];
            [_yellowButton setHidden:NO];
            
            NSString * usernames = [connectedDevices componentsJoinedByString:@","];
            NSLog(@" CONNECTED DEVICES CHANGED :%@ ",usernames);
            _connectionsLabel.text = [NSString stringWithFormat:@"Connections: %@",usernames];
            
        }];
    }else{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_connectButton setHidden:NO];
            [_redButton setHidden:YES];
            [_yellowButton setHidden:YES];
        
            _connectionsLabel.text = [NSString stringWithFormat:@"Disconnected"];
        }];
    }
    
}

-(void)receiveData:(PeerServiceManager*)peerServiceManager sendData: (NSData*) gameData{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString* dataString = [[NSString alloc] initWithData:gameData encoding:NSUTF8StringEncoding];
        if([dataString isEqualToString:@"red"]){
            [self changeColor:[UIColor redColor]];
        }else{
            [self changeColor:[UIColor yellowColor]];
        }
    }];
}




#pragma MCBrowserViewControllerDelegate
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    NSLog(@"Dismissed FINISH");
    
}

// Notifies delegate that the user taps the cancel button.
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    NSLog(@"Dismissed Cancelled");

}


@end
