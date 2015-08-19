#import "PhoneNumberDirectoryFilterManager.h"

#import "ContactsManager.h"
#import "Cryptography.h"
#import "Environment.h"
#import "NotificationManifest.h"
#import "PreferencesUtil.h"
#import "RPServerRequestsManager.h"
#import "ThreadManager.h"
#import "TSContactsIntersectionRequest.h"
#import "TSStorageManager.h"
#import "SignalRecipient.h"
#import "Util.h"

#define MINUTE (60.0)
#define HOUR (MINUTE*60.0)

#define DIRECTORY_UPDATE_TIMEOUT_PERIOD (1.0*MINUTE)
#define DIRECTORY_UPDATE_RETRY_PERIOD (1.0*HOUR)

@implementation PhoneNumberDirectoryFilterManager {
@private TOCCancelTokenSource* currentUpdateLifetime;
}

- (id)init {
    if (self = [super init]) {
        _isRefreshing              = NO;
    }
    return self;
}
- (void)startUntilCancelled:(TOCCancelToken*)cancelToken {
    lifetimeToken = cancelToken;
    
    //[self scheduleUpdate];
}


- (void)forceUpdate {
    [self scheduleUpdateAt:NSDate.date];
}

- (void)scheduleUpdateAt:(NSDate*)date {
    void(^doUpdate)(void) = ^{
        if (Environment.isRedPhoneRegistered) {
            [self updateRedPhone];
            
        }
    };
    
    [currentUpdateLifetime cancel];
    currentUpdateLifetime = [TOCCancelTokenSource new];
    [lifetimeToken whenCancelledDo:^{ [currentUpdateLifetime cancel]; }];
    [TimeUtil scheduleRun:doUpdate
                       at:date
                onRunLoop:[ThreadManager normalLatencyThreadRunLoop]
          unlessCancelled:currentUpdateLifetime.token];
}


- (void) updateRedPhone {
    _isRefreshing = YES;
   
    [self updateTextSecureWithRedPhoneSucces:YES];
}

- (void)updateTextSecureWithRedPhoneSucces:(BOOL)redPhoneSuccess {
    NSArray *allContacts = [[[Environment getCurrent] contactsManager] allContacts];
    
    NSMutableDictionary *contactsByPhoneNumber = [NSMutableDictionary dictionary];
    NSMutableDictionary *phoneNumbersByHashes  = [NSMutableDictionary dictionary];
    
    for (Contact *contact in allContacts) {
        for (PhoneNumber *phoneNumber in contact.parsedPhoneNumbers) {
            [phoneNumbersByHashes setObject:phoneNumber.toE164 forKey:[Cryptography truncatedSHA1Base64EncodedWithoutPadding:phoneNumber.toE164]];
            [contactsByPhoneNumber setObject:contact forKey:phoneNumber.toE164];
        }
    }
    
    NSArray *hashes = [phoneNumbersByHashes allKeys];
    
    TSRequest *request = [[TSContactsIntersectionRequest alloc]initWithHashesArray:hashes];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:request success:^(NSURLSessionDataTask *tsTask, id responseDict) {
        NSMutableArray      *tsIdentifiers      = [NSMutableArray array];
        NSMutableDictionary *relayForIdentifier = [NSMutableDictionary dictionary];
        NSMutableDictionary *supportsVoiceDict  = [NSMutableDictionary dictionary];
        NSArray *contactsArray                  = [(NSDictionary*)responseDict objectForKey:@"contacts"];
        
        if (contactsArray) {
            for (NSDictionary *dict in contactsArray) {
                NSString *hash = [dict objectForKey:@"token"];
                
                if (hash) {
                    [tsIdentifiers addObject:[phoneNumbersByHashes objectForKey:hash]];
                    
                    NSString *relay = [dict objectForKey:@"relay"];
                    if (relay) {
                        [relayForIdentifier setObject:relay forKey:[phoneNumbersByHashes objectForKey:hash]];
                    }
                    
                    id supportsVoice = [dict objectForKey:@"voice"];
                    if ([supportsVoice isEqualToNumber:@YES]) {
                        [supportsVoiceDict setObject:@YES forKey:[phoneNumbersByHashes objectForKey:hash]];
                    }
                    
                }
            }
        }
        
        NSLog(@"%@", supportsVoiceDict);
        
        [[TSStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            for (NSString *identifier in tsIdentifiers) {
                SignalRecipient *recipient = [SignalRecipient recipientWithTextSecureIdentifier:identifier withTransaction:transaction];
                if (!recipient) {
                    recipient = [[SignalRecipient alloc] initWithTextSecureIdentifier:identifier relay:nil voice:NO];
                }
                
                NSString *relay    = [relayForIdentifier objectForKey:recipient.uniqueId];
                NSNumber *voiceNum = [supportsVoiceDict  objectForKey:recipient.uniqueId];
                
                recipient.relay = relay;
                recipient.voice = voiceNum.boolValue?YES:NO;
                
                [recipient saveWithTransaction:transaction];
            }
        }];
        
        _isRefreshing = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DIRECTORY_WAS_UPDATED object:nil];
        
        //[self scheduleUpdate];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        _isRefreshing = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DIRECTORY_FAILED object:nil];
    }];
}


@end
