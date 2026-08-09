#include "pre_inc.h"
#include "bflib_fmvids.h"
#include "post_inc.h"

extern "C" TbBool play_smk(const char *filename, int flags)
{
    (void)filename;
    (void)flags;
    return false;
}

extern "C" short anim_stop(void)
{
    return 0;
}

extern "C" short anim_record(void)
{
    return 0;
}

extern "C" TbBool anim_record_frame(unsigned char *screenbuf, unsigned char *palette)
{
    (void)screenbuf;
    (void)palette;
    return false;
}
