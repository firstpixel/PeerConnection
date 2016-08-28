//
//  PeerServiceManager.m
//  PeerConnection
//
//  Created by Gil Beyruth on 8/27/16.
//  Copyright © 2016 Gil Beyruth. All rights reserved.
//


#import "PeerServiceManager.h"




@interface PeerServiceManager()<MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@end

@implementation PeerServiceManager {
    
    MCPeerID* myPeerId;
    MCNearbyServiceAdvertiser* serviceAdvertiser;
    MCNearbyServiceBrowser* serviceBrowser;
    MCSession* sessionLocal;
    
    
    
}
@synthesize PeerServiceType;

static PeerServiceManager *_sharedInstance;

- (id) init {
    self = [super init];
    if (self != nil){
        NSLog(@"PeerServiceManager init");
        
        // custom initialization
        PeerServiceType = @"peerConnection";
        myPeerId = [[MCPeerID alloc] initWithDisplayName: [[UIDevice currentDevice] name]];
        
        serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:myPeerId discoveryInfo:nil serviceType:PeerServiceType];
        
        serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:myPeerId serviceType:PeerServiceType];
        
        if (!sessionLocal) {
            sessionLocal = [[MCSession alloc] initWithPeer:myPeerId securityIdentity:nil encryptionPreference:MCEncryptionNone];
            sessionLocal.delegate = self;
        } else {
            NSLog(@"Session init skipped -- already exists");
        } 
        
    }
    return self;
}

- (void)startBrowsingAndAdvertising
{
    serviceAdvertiser.delegate = self;
    [serviceAdvertiser startAdvertisingPeer];
    
    serviceBrowser.delegate = self;
    [serviceBrowser startBrowsingForPeers];
    
    if (!browserVC){
        browserVC = [[MCBrowserViewController alloc] initWithServiceType:PeerServiceType
                                                                      session:sessionLocal];
        browserVC.delegate = _bcVCDelegate;
    } else {
        NSLog(@"Browser VC init skipped -- already exists");
    }
    UIViewController *rootController =(UIViewController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rootController presentViewController:browserVC animated:YES completion:nil];
}


- (void) stopAdvertisingAndBrowsing {
    [serviceAdvertiser stopAdvertisingPeer];
    [serviceBrowser stopBrowsingForPeers];
}

-(void)sendData:(NSString*)stringData {
    if(sessionLocal.connectedPeers.count > 0){
        NSError*errorData;
        
        [sessionLocal sendData:[stringData dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] toPeers:sessionLocal.connectedPeers withMode:MCSessionSendDataReliable error:&errorData];
        
        if(errorData){
            NSLog(@"ERROR sendData : %@", errorData);
        }
    }
}


+ (PeerServiceManager *) sharedInstance
{
    if (!_sharedInstance)
    {
        _sharedInstance = [[PeerServiceManager alloc] init];
    }
    
    return _sharedInstance;
}

#pragma MCNearbyServiceAdvertiserDelegate <NSObject>
// Incoming invitation request.  Call the invitationHandler block with YES
// and a valid session to connect the inviting peer to the session.
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    
    NSLog(@"didReceiveInvitationFromPeer: %@ ", peerID);
    invitationHandler(true, sessionLocal);
}

// Advertising did not start due to an error.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
    NSLog(@"didNotStartAdvertisingPeer: %@ ", error);
}


#pragma MCNearbyServiceBrowserDelegate
// Found a nearby advertising peer.
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info{
    
    NSLog(@"foundPeer:%@ ",peerID);
    NSLog(@"invitePeer:%@ ",peerID);
    [browser invitePeer:peerID toSession:sessionLocal withContext:nil timeout:10];
}

// A nearby peer has stopped advertising.
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    NSLog(@"lostPeer:%@ ",peerID);
    
}


// Browsing did not start due to an error.
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    NSLog(@"didNotStartBrowsingForPeers:%@ ",error);
    
    
}

#pragma MCSessionDelegate

// Remote peer changed state.
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSString* stateString;
    switch (state) {
        default:
        case 0:
            stateString = @"Disconnected";
            break;
        case 1:
            stateString = @"Connecting";
            break;
        case 2:
            stateString = @"Connected";
            [self stopAdvertisingAndBrowsing];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [browserVC dismissViewControllerAnimated:YES completion:^(void){
                    NSLog(@"CONNECTED");
                }];
            }];
            break;
    }
    
    
    
    NSLog(@"peer: %@  didChangeState: %@ ", peerID.displayName, stateString);
    
    NSArray *arrayOfNames = [NSArray array];
    for (int i = 0; i < session.connectedPeers.count; i++) {
        MCPeerID* peer = (MCPeerID*)session.connectedPeers[i];
        NSString* nameString = [NSString stringWithFormat:@"%@",peer.displayName];
        
        arrayOfNames = [arrayOfNames arrayByAddingObject:nameString];
        
    }
    
    if(_delegate){
        [_delegate connectedDevicesChanged:self connectedDevices:arrayOfNames totalDevices:(int)session.connectedPeers.count];
        arrayOfNames = nil;
    }else{
        NSLog(@"Missing delegate for PeerServiceManagerDelegate, please set a delete for PeerServiceManager");
    }
}

// Received data from remote peer.
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    /*
     NSLog("%@", "didReceiveData: \(data.length) bytes")
     let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
     self.delegate?.colorChanged(self, colorString: str)
     */
    NSLog(@"didReceiveData: %lu bytes", (unsigned long)data.length);
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [_delegate receiveData:self dataString:str];
}

// Received a byte stream from remote peer.
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID{
    NSLog(@"didReceiveStream");

}

// Start receiving a resource from remote peer.
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress{
    NSLog(@"didStartReceivingResourceWithName");

}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error{
    NSLog(@"didFinishReceivingResourceWithName");

}


// Made first contact with peer and have identity information about the
// remote peer (certificate may be nil).
- (void)        session:(MCSession *)session
  didReceiveCertificate:(nullable NSArray *)certificate
               fromPeer:(MCPeerID *)peerID
     certificateHandler:(void (^)(BOOL accept))certificateHandler{
    NSLog(@"didReceiveCertificate");
    certificateHandler(YES);
}


#pragma MCBrowserViewControllerDelegate
// Notifies the delegate, when the user taps the done button.
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [self stopAdvertisingAndBrowsing];
}

// Notifies delegate that the user taps the cancel button.
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [self stopAdvertisingAndBrowsing];

}


@end

