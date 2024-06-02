#ifndef __UTILS_LIB_SH__
#define __UTILS_LIB_SH__

bool fequal(float f1, float f2, float epsilon) {
	return f2 - epsilon <= f1 && f1 <= f2 + epsilon;
}

float mag(vec3 v) {
	return sqrt(dot(v, v));
}

float sqrmag(vec3 v) {
	return dot(v, v);
}

float safe_divide(float v1, float v2) {
	float s = sign(v2);
	float sq = s * s;
	return sq * v1 / (v2 + sq - 1.0);
}

bvec3 bvec3_or(bvec3 v1, bvec3 v2) {
	return bvec3 (v1.x || v2.x, v1.y || v2.y, v1.z || v2.z);
}

float sum(vec3 v) {
	return v.x + v.y + v.z;
}

vec4 encodeNormalUint(vec4 v) {
	return v * 0.5 + 0.5;
}

vec4 decodeNormalUint(vec4 v) {
	return v * 2.0 - 1.0;
}

float toClipSpaceDepth(float depth) {
#if BGFX_SHADER_LANGUAGE_GLSL
	return depth * 2.0 - 1.0;
#else
	return depth;
#endif
}

float fromClipSpaceDepth(float depth) {
#if BGFX_SHADER_LANGUAGE_GLSL
	return depth * 0.5 + 0.5;
#else
	return depth;
#endif
}

float linearizeDepth(float depth, float far, float near){
    return near * far / (far - depth * (far - near));
}

vec3 uvDepthToClip(vec2 uv, float depth) {
	vec3 clip = vec3(uv * 2.0 - 1.0, depth);
#if BGFX_SHADER_LANGUAGE_GLSL
	clip.z = depth * 2.0 - 1.0;
#else
	clip.y = -clip.y;
#endif
	return clip;
}

vec3 clipToUvDepth(vec3 clip) {
	vec2 uv = clip.xy;
	float depth = clip.z;
#if !BGFX_SHADER_LANGUAGE_GLSL
	uv.y = -uv.y;
#endif
	uv = uv * 0.5 + 0.5;
#if BGFX_SHADER_LANGUAGE_GLSL
	depth = depth * 0.5 + 0.5;
#endif
	return vec3(uv, depth);
}

vec4 transformH(mat4 mtx, vec3 p) {
	vec4 result = mul(mtx, vec4(p, 1.0));
	return vec4(result.xyz / result.w, result.w);
}

vec4 transform(mat4 mtx, vec3 p) {
	return mul(mtx, vec4(p, 1.0));
}

vec4 unpackFloat(float f) {
	const vec4 shift = vec4(1.0, 255.0, 65025.0, 160581375.0);
	const vec4 mask = vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
	vec4 res = fract(f * shift);
	res -= res.yzww * mask;
	return res;
}

float rgb2Luma(vec3 rgb) {
	return dot(vec3(0.2126729, 0.7151522, 0.0721750), rgb);
}

float rgb2PerceivedLuma(vec3 rgb) {
	return dot(vec3(0.299, 0.587, 0.114), rgb);
}

#endif // __UTILS_LIB_SH__
