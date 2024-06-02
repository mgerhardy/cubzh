/*
 * Deferred light shader variant: point, linear depth g-buffer, shadows
 */

// Point light
#define LIGHT_VARIANT_TYPE_POINT 1
#define LIGHT_VARIANT_TYPE_SPOT 0
#define LIGHT_VARIANT_TYPE_DIRECTIONAL 0

// Linear depth in g-buffer
#define LIGHT_VARIANT_LINEAR_DEPTH 1

// Shadows w/ sampler
#define LIGHT_VARIANT_SHADOW_PACK 0
#define LIGHT_VARIANT_SHADOW_SAMPLE 1
#define LIGHT_VARIANT_SHADOW_CSM 0
#define LIGHT_VARIANT_SHADOW_SOFT 0

#include "./fs_deferred_light_common.sh"