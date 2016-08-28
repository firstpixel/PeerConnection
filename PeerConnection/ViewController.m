//
//  ViewController.m
//  PeerConnection
//
//  Created by Gil Beyruth on 8/27/16.
//  Copyright © 2016 Gil Beyruth. All rights reserved.
//

#import "ViewController.h"
#import "PeerServiceManager.h"

@interface ViewController ()<PeerServiceManagerDelegate, MCBrowserViewControllerDelegate>
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
    [PeerServiceManager sharedInstance].bcVCDelegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)receiveData:(PeerServiceManager*)peerServiceManager dataString: (NSString*) dataString{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([dataString isEqualToString:@"red"]){
            [self changeColor:[UIColor redColor]];
        }else{
            [self changeColor:[UIColor yellowColor]];
        }
    }];
}

-(void)changeColor: (UIColor*)color {
    self.view.backgroundColor = color;
}


#pragma MCBrowserViewControllerDelegate
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:^(void){
        NSLog(@"Dismissed FINISH");
    }];
}

// Notifies delegate that the user taps the cancel button.
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:^(void){
        NSLog(@"Dismissed Cancelled");
    }];

}


@end
