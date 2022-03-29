////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Height Fog shader to create a volumetric plane with fog in a 3D scene
// By Marty McFly and Otis_Inf
// (c) 2022 All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// This shader has been released under the following license:
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer. 
// 
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Additional Credits:
// Plane intersection code by Inigo 'Iq' Quilez: https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
// 
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Version history:
// 29-mar-2022: 	Fixed Fog start, it now works as intended, and added smoothing to the fog so it doesn't create hard edges anymore around geometry. 
//                  Overall it looks better now.
// 25-mar-2022: 	Added vertical/horizontal cloud control and wider range so more cloud details are possible
//                  Added blending in HDR
// 22-mar-2022: 	First release
////////////////////////////////////////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

namespace Heightfog
{
	#define HEIGHT_FOG_VERSION  "1.0.2"

// uncomment the line below to enable debug mode
//#define HF_DEBUG 1

	uniform float3 FogColor <
		ui_category = "General";
		ui_label = "Fog color";
		ui_type = "color";
	> = float3(0.8, 0.8, 0.8);
	
	uniform float FogDensity <
		ui_category = "General";
		ui_type = "drag";
		ui_label = "Fog density";
		ui_min = 0.000; ui_max=1.000;
		ui_step = 0.001;
		ui_tooltip = "Controls how thick the fog is at its thickest point";
	> = 1.0;
	
	uniform float FogStart <
		ui_category = "General";
		ui_label = "Fog start";
		ui_type = "drag";
		ui_min = 0.0; ui_max=1.000;
		ui_tooltip = "Controls where the fog starts, relative to the camera";
		ui_step = 0.001;
	> = 0;

	uniform float FogCurve <
		ui_category = "General";
		ui_type = "drag";
		ui_label = "Fog curve";
		ui_min = 0.001; ui_max=1000.00;
		ui_tooltip = "Controls how quickly the fog gets thicker";
		ui_step = 0.1;
	> = 25;

	uniform float FoV <
		ui_category = "General";
		ui_type = "drag";
		ui_label = "FoV (degrees)";
		ui_tooltip = "The Field of View of the scene, for being able to correctly place the fog in the scene";
		ui_min = 10; ui_max=140;
		ui_step = 0.1;
	> = 60;

	uniform float2 PlaneOrientation <
		ui_category = "General";
		ui_type = "drag";
		ui_label = "Fog plane orientation";
		ui_tooltip = "Rotates the fog plane to match the scene.\nFirst value is roll, second value is up/down";
		ui_min = -2; ui_max=2;
		ui_step = 0.001;
	> = float2(1.751, -0.464);

	uniform float PlaneZ <
		ui_category = "General";
		ui_type = "drag";
		ui_label = "Fog plane Z";
		ui_tooltip = "Moves the fog plane up/down. Negative values are moving the plane downwards";
		ui_min = -2; ui_max=2;
		ui_step = 0.001;
	> = -0.001;
	
	uniform bool MovingFog <
		ui_label = "Moving fog";
		ui_tooltip = "Controls whether the fog clouds are static or moving across the plane";
		ui_category = "Cloud configuration";
	> = false;

	uniform float MovementSpeed <
		ui_type = "drag";
		ui_label = "Cloud movement speed";
		ui_tooltip = "Configures the speed the clouds move. 0.0 is no movement, 1.0 is max speed";
		ui_min = 0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 0.4;
	
	uniform float FogCloudScaleVertical <
		ui_type = "drag";
		ui_label = "Cloud scale (vertical)";
		ui_tooltip = "Configures the cloud size of the fog, vertically";
		ui_min = 0.0; ui_max=20;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;
	
	uniform float FogCloudScaleHorizontal <
		ui_type = "drag";
		ui_label = "Cloud scale (horizotal)";
		ui_tooltip = "Configures the cloud size of the fog, horizontally";
		ui_min = 0.0; ui_max=10;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;

	uniform float FogCloudFactor <
		ui_type = "drag";
		ui_label = "Cloud factor";
		ui_tooltip = "Configures the amount of cloud forming in the fog.\n1.0 means full clouds, 0.0 means no clouds";
		ui_min = 0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;
	
	uniform float2 FogCloudOffset <
		ui_type = "drag";
		ui_label = "Cloud offset";
		ui_tooltip = "Configures the offset in the cloud texture of the fog.\nUse this instead of Moving fog to control the cloud position";
		ui_min = 0.0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = float2(0.0, 0.0);

#ifdef HF_DEBUG
	uniform bool DBVal1 <
		ui_label = "DBVal1";
		ui_category = "Debug";
	> = false;
	uniform bool DBVal2 <
		ui_label = "DBVal2";
		ui_category = "Debug";
	> = false;
	uniform float DBVal3f <
		ui_type = "drag";
		ui_label = "DBVal3f";
		ui_min = 0.0; ui_max=10;
		ui_step = 0.01;
		ui_category = "Debug";
	> = 1.0;
#endif

	uniform float timer < source = "timer"; >; // Time in milliseconds it took for the last frame 

#ifndef M_PI
	#define M_PI 3.1415927
#endif

#ifndef M_2PI
	#define M_2PI 6.283185
#endif

	#define PITCH_MULTIPLIER		1.751
	#define YAW_MULTIPLIER			-0.464
	#define BUFFER_ASPECT_RATIO2     float2(1.0, BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

	texture texFogNoise				< source = "fognoise.jpg"; > { Width = 512; Height = 512; Format = RGBA8; };
	sampler SamplerFogNoise				{ Texture = texFogNoise; AddressU = WRAP; AddressV = WRAP; AddressW = WRAP;};

	float3 AccentuateWhites(float3 fragment)
	{
		fragment = pow(abs(fragment), 2.2);
		return fragment / max((1.001 - fragment), 0.001);
	}
	
	
	float3 CorrectForWhiteAccentuation(float3 fragment)
	{
		float3 toReturn = fragment / (1.001 + fragment);
		return pow(abs(toReturn), 1.0 / 2.2);
	}


	float3 uvToProj(float2 uv, float z)
	{
		//optimized math to simplify matrix mul
		const float3 uvtoprojADD = float3(-tan(radians(FoV) * 0.5).xx, 1.0) * BUFFER_ASPECT_RATIO2.yxx;
		const float3 uvtoprojMUL = float3(-2.0 * uvtoprojADD.xy, 0.0);

		return (uv.xyx * uvtoprojMUL + uvtoprojADD) * z;
	}


	// from iq
	float planeIntersect(float3 ro, float3 rd, float4 p)
	{
		return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
	}


	void PS_FogIt(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target0)
	{
		float4 originalFragment = tex2D(ReShade::BackBuffer, texcoord);
		originalFragment.rgb = AccentuateWhites(originalFragment.rgb);
		float depth = lerp(1.0, 1000.0, ReShade::GetLinearizedDepth(texcoord))/1000.0;
		float phi = PlaneOrientation.x * M_2PI; //I can never tell longitude and latitude apart... let's use wikipedia definitions
		float theta = PlaneOrientation.y * M_PI;

		float3 planeNormal;
		planeNormal.x = cos(phi)*sin(theta);
		planeNormal.y = sin(phi)*sin(theta);
		planeNormal.z = cos(theta);
		planeNormal = normalize(planeNormal); //for sanity

		float4 iqplane = float4(planeNormal, PlaneZ);	//anchor point is _apparently_ ray dir * this length in IQ formula
		float3 scenePosition = uvToProj(texcoord, depth); 
		float sceneDistance = length(scenePosition); //actually length(position - camera) but as camera is 0 0 0, it's just length(position)
		float3 rayDirection = scenePosition / sceneDistance; //normalize(scenePosition)

		//camera at 0 0 0, so we pass 0.0 for ray origin (the first argument)
		float distanceToIntersect = planeIntersect(0, rayDirection, iqplane); //produces negative numbers if looking away from camera - makes sense as if you look away, you need to go _backwards_ i.e. in negative view direction
		float speedFactor = 100000.0 * (1-(MovementSpeed-0.01));
		float fogTextureValueHorizontally = tex2D(SamplerFogNoise, (texcoord + FogCloudOffset) * FogCloudScaleHorizontal + (MovingFog ? frac(timer / speedFactor) : 0.0)).r;
		float fogTextureValueVertically = tex2D(SamplerFogNoise, (texcoord + FogCloudOffset) * FogCloudScaleVertical + (MovingFog ? frac(timer / speedFactor) : 0.0)).r;
		distanceToIntersect *= lerp(1.0, fogTextureValueVertically, FogCloudFactor);
		distanceToIntersect = distanceToIntersect < 0 ? 10000000 : distanceToIntersect; //if negative, we didn't hit it, so set hit distance to infinity
		float distanceTraveled = (depth - distanceToIntersect);
		distanceTraveled = saturate(distanceTraveled-saturate(0.5 * (FogStart - distanceToIntersect)));
		distanceTraveled *= 1 - (1 - distanceTraveled);
		float lerpFactor = saturate(distanceTraveled * 10.0 * FogCurve * FogDensity * lerp(1.0, fogTextureValueHorizontally, FogCloudFactor));
		fragment.rgb = sceneDistance < distanceToIntersect ? originalFragment.rgb 
														   : lerp(originalFragment.rgb, FogColor.rgb, lerpFactor);
		fragment.rgb = CorrectForWhiteAccentuation(fragment.rgb);
		fragment.a = 1.0;
	}
	
	technique HeightFog
#if __RESHADE__ >= 40000
	< ui_tooltip = "Height Fog "
			HEIGHT_FOG_VERSION
			"\n===========================================\n\n"
			"Height Fog shader to introduce a volumetric fog plane into a 3D scene,\n"
			"Height Fog was written by Marty McFly and Otis_Inf"; >
#endif
	{
		pass ApplyFog { VertexShader = PostProcessVS; PixelShader = PS_FogIt; }
	}
}