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

    CFURLRef pairingFileURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(),
                                                      CFSTR("pairing_file"),
                                                      CFSTR("plist"),
                                                      NULL);
    if (pairingFileURL == NULL) {
        return strdup("Error: Pairing file not found");
    }

    char pairingFilePath[PATH_MAX];
    if (!CFURLGetFileSystemRepresentation(pairingFileURL, TRUE, (UInt8 *)pairingFilePath, PATH_MAX)) {
        CFRelease(pairingFileURL);
        return strdup("Error: Pairing file path conversion failed");
    }
    CFRelease(pairingFileURL);

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
    char *result = malloc(8192);  // Allocate memory for output
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
                        strcat(result, bundle_id);
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
