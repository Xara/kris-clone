/** 
 * @file softenLightF.glsl
 *
 * $LicenseInfo:firstyear=2007&license=viewerlgpl$
 * $/LicenseInfo$
 */
 


#extension GL_ARB_texture_rectangle : enable
#extension GL_ARB_texture_multisample : enable

uniform sampler2DMS diffuseRect;
uniform sampler2DMS specularRect;
uniform sampler2DMS normalMap;
uniform sampler2DMS depthMap;
uniform sampler2D	  noiseMap;
uniform samplerCube environmentMap;
uniform sampler2D	  lightFunc;

uniform float blur_size;
uniform float blur_fidelity;

// Inputs
uniform vec4 morphFactor;
uniform vec3 camPosLocal;
//uniform vec4 camPosWorld;
uniform vec4 gamma;
uniform vec4 lightnorm;
uniform vec4 sunlight_color;
uniform vec4 ambient;
uniform vec4 blue_horizon;
uniform vec4 blue_density;
uniform vec4 haze_horizon;
uniform vec4 haze_density;
uniform vec4 cloud_shadow;
uniform vec4 density_multiplier;
uniform vec4 distance_multiplier;
uniform vec4 max_y;
uniform vec4 glow;
uniform float scene_light_strength;
uniform vec3 env_mat[3];
//uniform mat4 shadow_matrix[3];
//uniform vec4 shadow_clip;
uniform mat3 ssao_effect_mat;

varying vec4 vary_light;
varying vec2 vary_fragcoord;

vec3 vary_PositionEye;

vec3 vary_SunlitColor;
vec3 vary_AmblitColor;
vec3 vary_AdditiveColor;
vec3 vary_AtmosAttenuation;

uniform mat4 inv_proj;
uniform vec2 screen_res;

vec4 getPosition_d(vec2 pos_screen, float depth)
{
	vec2 sc = pos_screen.xy*2.0;
	sc /= screen_res;
	sc -= vec2(1.0,1.0);
	vec4 ndc = vec4(sc.x, sc.y, 2.0*depth-1.0, 1.0);
	vec4 pos = inv_proj * ndc;
	pos /= pos.w;
	pos.w = 1.0;
	return pos;
}

vec3 getPositionEye()
{
	return vary_PositionEye;
}
vec3 getSunlitColor()
{
	return vary_SunlitColor;
}
vec3 getAmblitColor()
{
	return vary_AmblitColor;
}
vec3 getAdditiveColor()
{
	return vary_AdditiveColor;
}
vec3 getAtmosAttenuation()
{
	return vary_AtmosAttenuation;
}


void setPositionEye(vec3 v)
{
	vary_PositionEye = v;
}

void setSunlitColor(vec3 v)
{
	vary_SunlitColor = v;
}

void setAmblitColor(vec3 v)
{
	vary_AmblitColor = v;
}

void setAdditiveColor(vec3 v)
{
	vary_AdditiveColor = v;
}

void setAtmosAttenuation(vec3 v)
{
	vary_AtmosAttenuation = v;
}

void calcAtmospherics(vec3 inPositionEye, float ambFactor) {

	vec3 P = inPositionEye;
	setPositionEye(P);
	
	//(TERRAIN) limit altitude
	if (P.y > max_y.x) P *= (max_y.x / P.y);
	if (P.y < -max_y.x) P *= (-max_y.x / P.y);

	vec3 tmpLightnorm = lightnorm.xyz;

	vec3 Pn = normalize(P);
	float Plen = length(P);

	vec4 temp1 = vec4(0);
	vec3 temp2 = vec3(0);
	vec4 blue_weight;
	vec4 haze_weight;
	vec4 sunlight = sunlight_color;
	vec4 light_atten;

	//sunlight attenuation effect (hue and brightness) due to atmosphere
	//this is used later for sunlight modulation at various altitudes
	light_atten = (blue_density * 1.0 + vec4(haze_density.r) * 0.25) * (density_multiplier.x * max_y.x);
		//I had thought blue_density and haze_density should have equal weighting,
		//but attenuation due to haze_density tends to seem too strong

	temp1 = blue_density + vec4(haze_density.r);
	blue_weight = blue_density / temp1;
	haze_weight = vec4(haze_density.r) / temp1;

	//(TERRAIN) compute sunlight from lightnorm only (for short rays like terrain)
	temp2.y = max(0.0, tmpLightnorm.y);
	temp2.y = 1. / temp2.y;
	sunlight *= exp( - light_atten * temp2.y);

	// main atmospheric scattering line integral
	temp2.z = Plen * density_multiplier.x;

	// Transparency (-> temp1)
	// ATI Bugfix -- can't store temp1*temp2.z*distance_multiplier.x in a variable because the ati
	// compiler gets confused.
	temp1 = exp(-temp1 * temp2.z * distance_multiplier.x);

	//final atmosphere attenuation factor
	setAtmosAttenuation(temp1.rgb);
	
	//compute haze glow
	//(can use temp2.x as temp because we haven't used it yet)
	temp2.x = dot(Pn, tmpLightnorm.xyz);
	temp2.x = 1. - temp2.x;
		//temp2.x is 0 at the sun and increases away from sun
	temp2.x = max(temp2.x, .03);	//was glow.y
		//set a minimum "angle" (smaller glow.y allows tighter, brighter hotspot)
	temp2.x *= glow.x;
		//higher glow.x gives dimmer glow (because next step is 1 / "angle")
	temp2.x = pow(temp2.x, glow.z);
		//glow.z should be negative, so we're doing a sort of (1 / "angle") function

	//add "minimum anti-solar illumination"
	temp2.x += .25;
	
	//increase ambient when there are more clouds
	vec4 tmpAmbient = ambient + (vec4(1.) - ambient) * cloud_shadow.x * 0.5;
	
	/*  decrease value and saturation (that in HSV, not HSL) for occluded areas
	 * // for HSV color/geometry used here, see http://gimp-savvy.com/BOOK/index.html?node52.html
	 * // The following line of code performs the equivalent of:
	 * float ambAlpha = tmpAmbient.a;
	 * float ambValue = dot(vec3(tmpAmbient), vec3(0.577)); // projection onto <1/rt(3), 1/rt(3), 1/rt(3)>, the neutral white-black axis
	 * vec3 ambHueSat = vec3(tmpAmbient) - vec3(ambValue);
	 * tmpAmbient = vec4(RenderSSAOEffect.valueFactor * vec3(ambValue) + RenderSSAOEffect.saturationFactor *(1.0 - ambFactor) * ambHueSat, ambAlpha);
	 */
	tmpAmbient = vec4(mix(ssao_effect_mat * tmpAmbient.rgb, tmpAmbient.rgb, ambFactor), tmpAmbient.a);

	//haze color
	setAdditiveColor(
		vec3(blue_horizon * blue_weight * (sunlight*(1.-cloud_shadow.x) + tmpAmbient)
	  + (haze_horizon.r * haze_weight) * (sunlight*(1.-cloud_shadow.x) * temp2.x
		  + tmpAmbient)));

	//brightness of surface both sunlight and ambient
	setSunlitColor(vec3(sunlight * .5));
	setAmblitColor(vec3(tmpAmbient * .25));
	setAdditiveColor(getAdditiveColor() * vec3(1.0 - temp1));
}

vec3 atmosLighting(vec3 light)
{
	light *= getAtmosAttenuation().r;
	light += getAdditiveColor();
	return (2.0 * light);
}

vec3 atmosTransport(vec3 light) {
	light *= getAtmosAttenuation().r;
	light += getAdditiveColor() * 2.0;
	return light;
}
vec3 atmosGetDiffuseSunlightColor()
{
	return getSunlitColor();
}

vec3 scaleDownLight(vec3 light)
{
	return (light / scene_light_strength );
}

vec3 scaleUpLight(vec3 light)
{
	return (light * scene_light_strength);
}

vec3 atmosAmbient(vec3 light)
{
	return getAmblitColor() + light / 2.0;
}

vec3 atmosAffectDirectionalLight(float lightIntensity)
{
	return getSunlitColor() * lightIntensity;
}

vec3 scaleSoftClip(vec3 light)
{
	//soft clip effect:
	light = 1. - clamp(light, vec3(0.), vec3(1.));
	light = 1. - pow(light, gamma.xxx);

	return light;
}

vec4 texture2DMS(sampler2DMS tex, ivec2 tc)
{
	vec4 ret = vec4(0,0,0,0);

	for (int i = 0; i < samples; ++i)
	{
		 ret += texelFetch(tex,tc,i);
	}

	return ret/samples;
}

void main() 
{
	vec2 tc = vary_fragcoord.xy;
	ivec2 itc = ivec2(tc);

	vec3 fcol = vec3(0,0,0);

	for (int i = 0; i < samples; ++i)
	{
		float depth = texelFetch(depthMap, itc, i).r;
		vec3 pos = getPosition_d(tc, depth).xyz;
		vec3 norm = texelFetch(normalMap, itc, i).xyz;

		norm = vec3((norm.xy-0.5)*2.0,norm.z); // unpack norm
		//vec3 nz = texture2D(noiseMap, vary_fragcoord.xy/128.0).xyz;
	
		float da = max(dot(norm.xyz, vary_light.xyz), 0.0);
	
		vec4 diffuse = texelFetch(diffuseRect, itc, i);
		if (diffuse.a >= 1.0)
		{
			fcol += diffuse.rgb;
		}
		else
		{
			vec4 spec = texelFetch(specularRect, itc, i);
	
			calcAtmospherics(pos.xyz, 1.0);
	
			vec3 col = atmosAmbient(vec3(0));
			col += atmosAffectDirectionalLight(max(min(da, 1.0), diffuse.a));
	
			col *= diffuse.rgb;
	
			if (spec.a > 0.0) // specular reflection
			{
				// the old infinite-sky shiny reflection
				//
				vec3 refnormpersp = normalize(reflect(pos.xyz, norm.xyz));
				float sa = dot(refnormpersp, vary_light.xyz);
				vec3 dumbshiny = vary_SunlitColor*texture2D(lightFunc, vec2(sa, spec.a)).a;

				// add the two types of shiny together
				col += dumbshiny * spec.rgb;
			}

			col = atmosLighting(col);
			col = scaleSoftClip(col);
			fcol += col;
		}
	}
				
	gl_FragColor.rgb = fcol.rgb/samples;
	gl_FragColor.a = 0.0;
}
