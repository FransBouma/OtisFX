////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Directional Depth Blur shader for ReShade
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2020 Frans Bouma
// All rights reserved.
// 
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
// Version History
// 10-apr-2020:		v0.9: First release
//
////////////////////////////////////////////////////////////////////////////////////////////////////


#include "ReShade.fxh"

namespace DirectionalDepthBlur
{
// Uncomment line below for debug info / code / controls
	#define CD_DEBUG 1
	
	#define DIRECTIONAL_DEPTH_BLUR_VERSION "v0.9"

	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////

	uniform float ManualFocusPlane <
		ui_category = "Focusing";
		ui_label= "Manual-focus plane";
		ui_type = "drag";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The depth of focal plane related to the camera";
	> = 0.010;
	uniform float FocusRange <
		ui_category = "Focusing";
		ui_label= "Focus range";
		ui_type = "drag";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The range around the focus plane that's more or less not blurred. 1.0 is the ManualFocusPlaneMaxRange.";
	> = 0.001;
	uniform float ManualFocusPlaneMaxRange <
		ui_category = "Focusing";
		ui_label= "Manual-focus plane max range";
		ui_type = "drag";
		ui_min = 10; ui_max = 300;
		ui_step = 1;
		ui_tooltip = "The depth of focal plane related to the camera when 'Use auto-focus' is off.\n'1.0' means the at the horizon. 0 means at the camera.\nOnly used if 'Use auto-focus' is disabled.";
	> = 10;
	uniform float BlurAngle <
		ui_category = "Blur tweaking";
		ui_label="Blur angle";
		ui_type = "drag";
		ui_min = 0.01; ui_max = 1.00;
		ui_tooltip = "The angle of the blur direction";
		ui_step = 0.01;
	> = 1.0;
	uniform float BlurLength <
		ui_category = "Blur tweaking";
		ui_label = "Blur length";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 1.0;
		ui_step = 0.001;
		ui_tooltip = "The length of the blur per pixel. 1.0 is the entire screen.";
	> = 0.001;
	uniform float BlurQuality <
		ui_category = "Blur tweaking";
		ui_label = "Blur quality";
		ui_type = "drag";
		ui_min = 0.01; ui_max = 1.0;
		ui_step = 0.01;
		ui_tooltip = "The quality of the blur. 1.0 means all pixels in the length are read,\n0.5 means half of them are read.";
	> = 0.5;
	uniform float ScaleFactor <
		ui_category = "Blur tweaking";
		ui_label = "Scale factor";
		ui_type = "drag";
		ui_min = 0.010; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The scale factor for the pixels to blur. Lower values downscale the\nsource frame and will result in wider blur strokes.";
	> = 1.000;
#if CD_DEBUG
	// ------------- DEBUG
	uniform bool DBVal1 <
		ui_category = "Debugging";
	> = false;
	uniform bool DBVal2 <
		ui_category = "Debugging";
	> = false;
	uniform float DBVal3f <
		ui_category = "Debugging";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_step = 0.01;
	> = 0.0;
	uniform float DBVal4f <
		ui_category = "Debugging";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 10.00;
		ui_step = 0.01;
	> = 1.0;
#endif
	//////////////////////////////////////////////////
	//
	// Defines, constants, samplers, textures, uniforms, structs
	//
	//////////////////////////////////////////////////

#ifndef BUFFER_PIXEL_SIZE
	#define BUFFER_PIXEL_SIZE	ReShade::PixelSize
#endif
#ifndef BUFFER_SCREEN_SIZE
	#define BUFFER_SCREEN_SIZE	ReShade::ScreenSize
#endif

	uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;
	
	texture texDownsampledBackBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	texture texBlurDestination { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; 
	
	sampler samplerDownsampledBackBuffer { Texture = texDownsampledBackBuffer; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR;};
	sampler samplerBlurDestination { Texture = texBlurDestination; };
	
	struct VSPIXELINFO
	{
		float4 vpos : SV_Position;
		float2 texCoords : TEXCOORD0;
		float2 pixelDelta: TEXCOORD1;
		float blurLengthInPixels: TEXCOORD2;
		float focusPlane: TEXCOORD3;
		float focusRange: TEXCOORD4;
		float4 texCoordsScaled: TEXCOORD5;
	};
	
	//////////////////////////////////////////////////
	//
	// Functions
	//
	//////////////////////////////////////////////////
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSPIXELINFO VS_PixelInfo(in uint id : SV_VertexID)
	{
		VSPIXELINFO pixelInfo;
		
		pixelInfo.texCoords.x = (id == 2) ? 2.0 : 0.0;
		pixelInfo.texCoords.y = (id == 1) ? 2.0 : 0.0;
		pixelInfo.vpos = float4(pixelInfo.texCoords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		float angleToUse = 6.28318530717958 * BlurAngle;
		sincos(angleToUse, pixelInfo.pixelDelta.y, pixelInfo.pixelDelta.x);
		float pixelSizeLength = length(BUFFER_PIXEL_SIZE);
		pixelInfo.pixelDelta *= pixelSizeLength;
		pixelInfo.blurLengthInPixels = length(BUFFER_SCREEN_SIZE) * BlurLength;
		pixelInfo.focusPlane = (ManualFocusPlane * ManualFocusPlaneMaxRange) / 1000.0; 
		pixelInfo.focusRange = (FocusRange * ManualFocusPlaneMaxRange) / 1000.0;
		pixelInfo.texCoordsScaled = float4(pixelInfo.texCoords * ScaleFactor, pixelInfo.texCoords / ScaleFactor);
		return pixelInfo;
	}

	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////

	void PS_Blur(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		float3 color = tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb;
		float4 average = float4(color, 1.0);
		for(float tapIndex=0.0;tapIndex<pixelInfo.blurLengthInPixels;tapIndex+=(1/BlurQuality))
		{
			float2 tapCoords = (pixelInfo.texCoords + (pixelInfo.pixelDelta * tapIndex));
			float3 tapColor = tex2Dlod(samplerDownsampledBackBuffer, float4(tapCoords * ScaleFactor, 0, 0)).rgb;
			float tapDepth = ReShade::GetLinearizedDepth(tapCoords);
			float weight = tapDepth <= pixelInfo.focusPlane ? 0.0 : 1-(tapIndex/ pixelInfo.blurLengthInPixels);
			average.rgb+=(tapColor * weight);
			average.a+=weight;
		}
		fragment.rgb = average.rgb / average.a;
		fragment.a = 1.0;
	}


	void PS_Combiner(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		float colorDepth = ReShade::GetLinearizedDepth(pixelInfo.texCoords);
		float4 realColor = tex2Dlod(ReShade::BackBuffer, float4(pixelInfo.texCoords, 0, 0));
		if(colorDepth <= pixelInfo.focusPlane || (BlurLength <= 0.0))
		{
			fragment = realColor;
			return;
		}
		float3 color = tex2Dlod(samplerBlurDestination, float4(pixelInfo.texCoords, 0, 0)).rgb;
		float rangeEnd = (pixelInfo.focusPlane+pixelInfo.focusRange);
		float blendFactor = rangeEnd < colorDepth 
								? 1.0 
								: smoothstep(0, 1, 1-((rangeEnd-colorDepth) / pixelInfo.focusRange));
		fragment.rgb = lerp(realColor.rgb, color, blendFactor);
	}
	
	void PS_DownSample(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		float2 sourceCoords = pixelInfo.texCoordsScaled.zw;
		if(max(sourceCoords.x, sourceCoords.y) > 1.0001)
		{
			// source pixel is outside the frame
			discard;
		}
		fragment = tex2D(ReShade::BackBuffer, sourceCoords);
	}
	
	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique DirectionalDepthBlur
#if __RESHADE__ >= 40000
	< ui_tooltip = "Directional Depth Blur "
			DIRECTIONAL_DEPTH_BLUR_VERSION
			"\n===========================================\n\n"
			"Directional Depth Blur is a shader for adding far plane directional blur\n"
			"based on the depth of each pixel\n\n"
			"Directional Depth Blur was written by Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; >
#endif	
	{
		pass Downsample { VertexShader = VS_PixelInfo ; PixelShader = PS_DownSample; RenderTarget = texDownsampledBackBuffer; }
		pass BlurPass { VertexShader = VS_PixelInfo; PixelShader = PS_Blur; RenderTarget = texBlurDestination; }
		pass Combiner { VertexShader = VS_PixelInfo; PixelShader = PS_Combiner; }
	}
}