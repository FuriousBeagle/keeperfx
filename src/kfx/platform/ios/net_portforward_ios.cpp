#include "pre_inc.h"
#include "net_portforward.h"
#include "post_inc.h"

extern "C" int port_forward_add_mapping(uint16_t port)
{
    (void)port;
    // Hosting can still fall back to KeeperFX's direct/hole-punch networking.
    // Automatic NAT-PMP/UPnP router configuration is deferred for iOS.
    return 1;
}

extern "C" void port_forward_remove_mapping(void)
{
}
