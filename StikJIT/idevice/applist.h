//
//  applist.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

#ifndef APPLIST_H
#define APPLIST_H
@import Foundation;

NSDictionary<NSString*, NSString*>* list_installed_apps(IdevicePairingFile* pairing_file, NSString** error);

#endif /* APPLIST_H */
