/*
 * Quad fragment shader variant: lighting pass, textured
 */

// Multiple render target lighting
#define QUAD_VARIANT_MRT_LIGHTING 1
#define QUAD_VARIANT_MRT_LINEAR_DEPTH 0

// Textured
#define QUAD_VARIANT_TEX 1
#define QUAD_VARIANT_CUTOUT 0

#include "./fs_quad_common.sh"