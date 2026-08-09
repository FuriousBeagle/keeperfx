#ifndef PLATFORM_IOS_H
#define PLATFORM_IOS_H

#include "kfx/platform/IPlatform.h"

/** Apple iOS/iPadOS platform. */
class PlatformIOS : public IPlatform {
public:
    bool VideoInit() override;
};

#endif // PLATFORM_IOS_H
