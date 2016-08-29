//
//  PeerServiceManager.h
//  PeerConnection
//
//  Created by Gil Beyruth on 8/27/16.
//  Copyright © 2016 Gil Beyruth. All rights reserved.
//

#ifndef PeerServiceManager_h
#define PeerServiceManager_h


#endif /* PeerServiceManager_h */

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>



@protocol PeerServiceManagerDelegate;

@interface PeerServiceManager : NSObject <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>{
    MCBrowserViewController* browserVC;
    NSString* PeerServiceType;
    
}

@property (weak) id<PeerServiceManagerDelegate,MCBrowserViewControllerDelegate> delegate;
@property (retain) NSString* PeerServiceType;

-(void)startBrowsingAndAdvertising;
-(void)stopAdvertisingAndBrowsing;

+(PeerServiceManager *) sharedInstance;
-(void)sendData:(NSString*)stringData;

@end

@protocol PeerServiceManagerDelegate <MCBrowserViewControllerDelegate>
@required
-(void)connectedDevicesChanged:(PeerServiceManager*)peerServiceManager connectedDevices: (NSArray<NSString *>*)connectedDevices totalDevices:(int)totalDevices;
-(void)receiveData:(PeerServiceManager*)peerServiceManager sendData: (NSData*) gameData;
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController;
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController;



@end