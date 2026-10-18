/* iOS 6 adjustments on top of mbedTLS's default mbedtls_config.h.
 * clock_gettime() only exists on iOS 10+, so mbedtls_ms_time() comes from mbedtls_ios6_alt.c (mach_absolute_time). */
#define MBEDTLS_PLATFORM_MS_TIME_ALT
