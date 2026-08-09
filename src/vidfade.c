/*
 * KeeperFX, Open source Dungeon Keeper clone.
 * Copyright (C) 2001-2025 KeeperFX Team
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "pre_inc.h"
#include "vidfade.h"

#include "bflib_basics.h"
#include "bflib_video.h"
#include "bflib_vidraw.h"
#include "bflib_planar.h"
#include "bflib_sound.h"
#include "globals.h"
#include "game_legacy.h"
#include "player_data.h"
#include "power_hand.h"
#include "power_process.h"
#include "config_players.h"
#include "post_inc.h"

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************/

long palette_fade_steps = 20;

long LbPaletteFade(const unsigned char *pal, long fade_steps, enum TbBool open)
{
    long i;
    unsigned char palette[PALETTE_SIZE];
    unsigned char *dst;
    const unsigned char *src;
    long step;
    long allblack;

    if (fade_steps <= 0)
    {
        if (open)
            LbPaletteSet(pal);
        else
            LbPaletteSet(NULL);
        return 0;
    }

    for (step = 0; step < fade_steps; step++)
    {
        allblack = 1;
        dst = palette;
        src = pal;
        for (i = 0; i < PALETTE_SIZE; i++)
        {
            if (open)
                *dst = (unsigned char)((long)(*src) * step / fade_steps);
            else
                *dst = (unsigned char)((long)(*src) * (fade_steps-step) / fade_steps);
            if (*dst != 0)
                allblack = 0;
            dst++;
            src++;
        }
        LbPaletteSet(palette);
        if (allblack)
            break;
        LbScreenWaitVbi();
    }
    if (open)
        LbPaletteSet(pal);
    else
        LbPaletteSet(NULL);
    return step;
}

long LbPaletteFadeStop(void)
{
    return 0;
}

long LbPaletteFadeSingle(const unsigned char *pal, long fade_steps, enum TbBool open)
{
    return LbPaletteFade(pal, fade_steps, open);
}

long LbPaletteFadePlayer(struct PlayerInfo *player, const unsigned char *pal, long fade_steps, enum TbBool open)
{
    return LbPaletteFade(pal, fade_steps, open);
}

long LbPaletteFadePlayerSingle(struct PlayerInfo *player, const unsigned char *pal, long fade_steps, enum TbBool open)
{
    return LbPaletteFade(pal, fade_steps, open);
}

long LbPaletteFadePlayerSingleIntoBlack(struct PlayerInfo *player, const unsigned char *pal, long fade_steps)
{
    return LbPaletteFade(pal, fade_steps, false);
}

long LbPaletteFadePlayerSingleFromBlack(struct PlayerInfo *player, const unsigned char *pal, long fade_steps)
{
    return LbPaletteFade(pal, fade_steps, true);
}

long LbPaletteFadePlayerSingleColor(struct PlayerInfo *player, const unsigned char *pal, long fade_steps, enum TbBool open, unsigned char r, unsigned char g, unsigned char b)
{
    return LbPaletteFade(pal, fade_steps, open);
}

long PaletteSetPlayerPalette(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteSetPlayerPaletteSingle(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteApplyPlayer(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteApplyPlayerSingle(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteApplyPlayerInfluence(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteApplyPlayerInfluenceSingle(struct PlayerInfo *player, const unsigned char *pal)
{
    LbPaletteSet(pal);
    return 0;
}

long PaletteApplyPlayerPalette(struct PlayerInfo *player, const unsigned char *pal)
{
    unsigned char palette[PALETTE_SIZE];
    unsigned char *dst;
    const unsigned char *src;
    long step;

    if (player->palette_fade_step_pain > 0)
        step = player->palette_fade_step_pain;
    else
    if (player->palette_fade_step_possession > 0)
        step = player->palette_fade_step_possession;
    else
        step = 0;

    dst = palette;
    src = pal;
    while (src < &pal[PALETTE_SIZE])
    {
        unsigned char pix;
        pix = src[0];
        if (player->palette_fade_step_pain > 0)
        {
            pix = (unsigned char)(pix + ((63 - pix) * player->palette_fade_step_pain / 10));
        }
        if (player->palette_fade_step_possession > 0)
        {
            pix = (unsigned char)(pix * (12 - player->palette_fade_step_possession) / 12);
        }
        dst[0] = pix;

        pix = src[1];
        if (player->palette_fade_step_pain > 0)
        {
            pix = (unsigned char)(pix * (10 - player->palette_fade_step_pain) / 10);
        }
        if (player->palette_fade_step_possession > 0)
        {
            pix = (unsigned char)(pix * (12 - player->palette_fade_step_possession) / 12);
        }
        dst[1] = pix;

        pix = src[2];
        if (player->palette_fade_step_pain > 0)
        {
            pix = (unsigned char)(pix * (10 - player->palette_fade_step_pain) / 10);
        }
        if (player->palette_fade_step_possession > 0)
        {
            pix = (unsigned char)(pix + ((63 - pix) * player->palette_fade_step_possession / 12));
        }
        dst[2] = pix;
        dst += 3;
        src += 3;
    }
    if (player->palette_fade_step_pain > 0)
        player->palette_fade_step_pain--;
    if ((player->palette_fade_step_possession == 0) || (player->instance_num == PI_UnusedSlot18) || (player->instance_num == PI_UnusedSlot17))
    {
    } else
    if ((player->instance_num == PI_DirctCtrl) || (player->instance_num == PI_PsngrCtrl))
    {
        if (player->palette_fade_step_possession <= 12)
            player->palette_fade_step_possession++;
    } else
    {
        if (player->palette_fade_step_possession > 0)
            player->palette_fade_step_possession--;
    }
    LbScreenWaitVbi();
    LbPaletteSet(palette);
    return step;
}

void PaletteApplyPainToPlayer(struct PlayerInfo *player, long intense)
{
    long i = player->palette_fade_step_pain + intense;
    if (i < 1)
        i = 1;
    else
    if (i > 10)
        i = 10;
    player->palette_fade_step_pain = (int32_t)i;
}


/******************************************************************************/
#ifdef __cplusplus
}
#endif
