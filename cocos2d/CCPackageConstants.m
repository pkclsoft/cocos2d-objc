#import <Foundation/Foundation.h>

// Errors
NSUInteger const PACKAGE_ERROR_DOWNLOAD_SERVER_RESPONSE_NOT_OK = 10000;

NSUInteger const PACKAGE_ERROR_INSTALL_UNZIPPED_PACKAGE_NOT_FOUND = 10010;

NSUInteger const PACKAGE_ERROR_INSTALL_COULD_NOT_MOVE_PACKAGE_TO_INSTALL_FOLDER = 10011;

NSUInteger const PACKAGE_ERROR_INSTALL_PACKAGE_EMPTY = 10012;

NSUInteger const PACKAGE_ERROR_INSTALL_PACKAGE_FOLDER_NAME_NOT_FOUND = 10013;

NSUInteger const PACKAGE_ERROR_MANAGER_CANNOT_ENABLE_NON_DISABLED_PACKAGE = 10020;

NSUInteger const PACKAGE_ERROR_MANAGER_CANNOT_DISABLE_NON_ENABLED_PACKAGE = 10021;


// Misc
NSString *const PACKAGE_REL_DOWNLOAD_FOLDER = @"com.cocos2d/Packages/Downloads";

NSString *const PACKAGE_REL_UNZIP_FOLDER = @"com.cocos2d/Packages/Unzipped";

NSString *const PACKAGE_STORAGE_USERDEFAULTS_KEY = @"cocos2d.packages";
