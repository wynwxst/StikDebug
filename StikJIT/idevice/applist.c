//
//  applist.c
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

#include "idevice.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CoreFoundation/CoreFoundation.h>
#include <limits.h>

char *list_installed_apps() {
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCKDOWN_PORT);
    if (inet_pton(AF_INET, "10.7.0.1", &addr.sin_addr) <= 0) {
        return strdup("Error: Invalid IP address");
    }

    char pairingFilePath[1024];
    CFURLRef url = CFCopyHomeDirectoryURL();
    if (url) {
        CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        if (path) {
            CFStringGetCString(path, pairingFilePath, sizeof(pairingFilePath), kCFStringEncodingUTF8);
            strncat(pairingFilePath, "/Documents/pairingFile.plist", sizeof(pairingFilePath) - strlen(pairingFilePath) - 1);
            CFRelease(path);
        }
        CFRelease(url);
    }

    IdevicePairingFile *pairing_file = NULL;
    IdeviceErrorCode err = idevice_pairing_file_read(pairingFilePath, &pairing_file);
    if (err != IdeviceSuccess) {
        return strdup("Error: Failed to read pairing file");
    }

    TcpProviderHandle *provider = NULL;
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing_file, "ExampleProvider", &provider);
    if (err != IdeviceSuccess) {
        idevice_pairing_file_free(pairing_file);
        return strdup("Error: Failed to create TCP provider");
    }

    InstallationProxyClientHandle *client = NULL;
    err = installation_proxy_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        tcp_provider_free(provider);
        return strdup("Error: Failed to connect to installation proxy");
    }

    void *apps = NULL;
    size_t apps_len = 0;
    err = installation_proxy_get_apps(client, NULL, NULL, 0, &apps, &apps_len);
    if (err != IdeviceSuccess) {
        installation_proxy_client_free(client);
        tcp_provider_free(provider);
        return strdup("Error: Failed to get apps");
    }

    plist_t *app_list = (plist_t *)apps;
    char *result = malloc(16384);  // Increased buffer size for additional data
    result[0] = '\0';

    for (size_t i = 0; i < apps_len; i++) {
        plist_t app = app_list[i];
        // Check if the app has an "Entitlements" dictionary.
        plist_t entitlements = plist_dict_get_item(app, "Entitlements");
        if (entitlements) {
            // Look for the "get-task-allow" key.
            plist_t taskAllowNode = plist_dict_get_item(entitlements, "get-task-allow");
            if (taskAllowNode) {
                int isAllowed = 0;
                plist_get_bool_val(taskAllowNode, &isAllowed);
                if (isAllowed) {
                    // Retrieve the bundle identifier if the entitlement is true.
                    plist_t bundle_id_node = plist_dict_get_item(app, "CFBundleIdentifier");
                    if (bundle_id_node) {
                        char *bundle_id = NULL;
                        plist_get_string_val(bundle_id_node, &bundle_id);
                        
                        // Get app name
                        char *app_name = NULL;
                        plist_t name_node = plist_dict_get_item(app, "CFBundleName");
                        if (name_node) {
                            plist_get_string_val(name_node, &app_name);
                        } else {
                            name_node = plist_dict_get_item(app, "CFBundleDisplayName");
                            if (name_node) {
                                plist_get_string_val(name_node, &app_name);
                            }
                        }
                        
                        // Add bundle ID and app name to result
                        strcat(result, bundle_id);
                        strcat(result, "|");  // Use pipe as separator
                        if (app_name) {
                            strcat(result, app_name);
                            free(app_name);
                        } else {
                            strcat(result, bundle_id);  // Use bundle ID as fallback name
                        }
                        strcat(result, "\n");
                        
                        free(bundle_id);
                    }
                }
            }
        }
    }

    installation_proxy_client_free(client);
    tcp_provider_free(provider);

    return result;
}

char *fetch_app_icon(const char *bundle_path) {
    // This would require implementing AFC service to access files on the device
    // and extract the icon file from the app bundle
    
    // For now, return NULL as this requires significant additional code
    return NULL;
}
