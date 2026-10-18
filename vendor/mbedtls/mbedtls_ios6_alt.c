#include "mbedtls/build_info.h"
#include "mbedtls/platform_time.h"
#include <mach/mach_time.h>

/* Milliseconds from a monotonic clock; mbedTLS only uses differences (TLS 1.3 ticket age, timeouts). */
mbedtls_ms_time_t mbedtls_ms_time(void)
{
    static mach_timebase_info_data_t tb;
    if (tb.denom == 0) {
        mach_timebase_info(&tb);
    }
    uint64_t ns = mach_absolute_time() * tb.numer / tb.denom;
    return (mbedtls_ms_time_t) (ns / 1000000ULL);
}
