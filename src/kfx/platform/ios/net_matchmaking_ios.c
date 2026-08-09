#include "pre_inc.h"
#include "net_matchmaking.h"
#include <string.h>
#include "post_inc.h"

struct TbNetworkSessionNameEntry matchmaking_sessions[MATCHMAKING_SESSIONS_MAX];
int matchmaking_session_count = 0;
char join_lobby_id[MATCHMAKING_ID_MAX] = {0};

void matchmaking_connect_async(void)
{
}

int matchmaking_connect(void)
{
    return 0;
}

int matchmaking_request_list(void)
{
    matchmaking_session_count = 0;
    return 0;
}

void matchmaking_disconnect(void)
{
    matchmaking_session_count = 0;
    join_lobby_id[0] = '\0';
}

void matchmaking_close_lobby(void)
{
    join_lobby_id[0] = '\0';
}

void matchmaking_refresh_sessions(void)
{
    matchmaking_session_count = 0;
}

int matchmaking_create(const char *name, int udp_ipv4_port, int udp_ipv6_port)
{
    (void)name;
    (void)udp_ipv4_port;
    (void)udp_ipv6_port;
    return 0;
}

int matchmaking_punch(const char *lobby_id, int udp_ipv4_port, int udp_ipv6_port, PunchAddresses *output)
{
    (void)lobby_id;
    (void)udp_ipv4_port;
    (void)udp_ipv6_port;
    if (output != NULL) {
        memset(output, 0, sizeof(*output));
    }
    return 0;
}

int matchmaking_poll_punch(PunchAddresses *output)
{
    if (output != NULL) {
        memset(output, 0, sizeof(*output));
    }
    return 0;
}
