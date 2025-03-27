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
        return strdup("{\"error\": \"Invalid IP address\"}");
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
        return strdup("{\"error\": \"Failed to read pairing file\"}");
    }

    TcpProviderHandle *provider = NULL;
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing_file, "ExampleProvider", &provider);
    if (err != IdeviceSuccess) {
        idevice_pairing_file_free(pairing_file);
        return strdup("{\"error\": \"Failed to create TCP provider\"}");
    }

    InstallationProxyClientHandle *client = NULL;
    err = installation_proxy_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        tcp_provider_free(provider);
        return strdup("{\"error\": \"Failed to connect to installation proxy\"}");
    }

    void *apps = NULL;
    size_t apps_len = 0;
    err = installation_proxy_get_apps(client, NULL, NULL, 0, &apps, &apps_len);
    if (err != IdeviceSuccess) {
        installation_proxy_client_free(client);
        tcp_provider_free(provider);
        return strdup("{\"error\": \"Failed to get apps\"}");
    }

    plist_t *app_list = (plist_t *)apps;
    char *result = malloc(8192);  // Allocate memory for output
    result[0] = '\0';
    strcat(result, "{\n");

    int first_entry = 1;
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

                        // Skip if bundle ID is empty
                        if (bundle_id == NULL || strlen(bundle_id) == 0) {
                            free(bundle_id);
                            continue;
                        }

                        // Retrieve the app name
                        plist_t app_name_node = plist_dict_get_item(app, "CFBundleName");
                        char *app_name = NULL;
                        if (app_name_node) {
                            plist_get_string_val(app_name_node, &app_name);
                        } else {
                            app_name = strdup("Unknown");
                        }

                        // Escape special characters in app name and bundle ID
                        char escaped_app_name[1024] = {0};
                        char escaped_bundle_id[1024] = {0};
                        for (int j = 0, k = 0; app_name[j] != '\0'; j++, k++) {
                            if (app_name[j] == '"' || app_name[j] == '\\') {
                                escaped_app_name[k++] = '\\';
                            }
                            escaped_app_name[k] = app_name[j];
                        }
                        for (int j = 0, k = 0; bundle_id[j] != '\0'; j++, k++) {
                            if (bundle_id[j] == '"' || bundle_id[j] == '\\') {
                                escaped_bundle_id[k++] = '\\';
                            }
                            escaped_bundle_id[k] = bundle_id[j];
                        }

                        // Add the app name and bundle ID to the result in JSON format
                        if (!first_entry) {
                            strcat(result, ",\n");
                        }
                        strcat(result, "  \"");
                        strcat(result, escaped_app_name);
                        strcat(result, "\": \"");
                        strcat(result, escaped_bundle_id);
                        strcat(result, "\"");

                        first_entry = 0;
                        free(bundle_id);
                        free(app_name);
                    }
                }
            }
        }
    }

    strcat(result, "\n}\n");

    installation_proxy_client_free(client);
    tcp_provider_free(provider);

    return result;
}
