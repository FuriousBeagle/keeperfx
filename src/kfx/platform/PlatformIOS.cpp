#include "pre_inc.h"
#include "kfx/platform/PlatformIOS.h"
#include <SDL3/SDL.h>
#include <cstdlib>
#include "post_inc.h"

bool PlatformIOS::VideoInit()
{
    if (!SDL_Init(SDL_INIT_VIDEO))
        return false;
    atexit(SDL_Quit);
    return true;
}
