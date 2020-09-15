////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Magic Border shader
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

#include "ReShade.fxh"

namespace MagicBorder
{
	#define MAGIC_BORDER_VERSION "v0.1"

	uniform float Depth <
		ui_label = "Depth";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 300.00;
		ui_step = 0.01;
		ui_tooltip = "The depth the border is placed in the scene. 0.0 is at the camera, 1000.0 is at the horizon";
	> = 1.0;
	
	uniform float BorderWidth <
		ui_label = "Border width";
		ui_type = "drag";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The width of the border in % of half the height of the screen. 1.0 is everything is covered with the border, 0.001 is a minimal border";
	> = 0.1;
	
	uniform float4 BorderColor <
		ui_label = "Border color";
		ui_type= "color";
		ui_tooltip = "The color of the border. Use the alpha value for blending. ";
	> = float4(1.0, 1.0, 1.0, 1.0);
	
	uniform float4 PictureAreaColor <
		ui_label = "Picture area color";
		ui_type= "color";
		ui_tooltip = "The color of the area within the border. Use the alpha value for blending. ";
	> = float4(0.7, 0.7, 0.7, 1.0);
	
	
	struct VSBORDERINFO
	{
		float4 vpos : SV_Position;
		float2 texcoord : TEXCOORD0;
		float focusDepth : TEXCOORD1;
		float2 LeftTop : TEXCOORD2;
		float2 RightTop : TEXCOORD3;
		float2 LeftBottom : TEXCOORD4;
		float2 RightBottom : TEXCOORD5;
	};
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSBORDERINFO VS_CalculateBorderInfo(in uint id : SV_VertexID)
	{
		VSBORDERINFO borderInfo;
		
		borderInfo.texcoord.x = (id == 2) ? 2.0 : 0.0;
		borderInfo.texcoord.y = (id == 1) ? 2.0 : 0.0;
		borderInfo.vpos = float4(borderInfo.texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		
		float borderWidthTop = BorderWidth * 0.5;
		float borderWidthLeft = BorderWidth * 0.5;
		
		if(ReShade::AspectRatio >= 1.0)
		{
			// use height
			borderWidthLeft = borderWidthTop * (1.0 / ReShade::AspectRatio);
		}
		else
		{
			// use width
			borderWidthTop = borderWidthLeft * (1.0 / ReShade::AspectRatio);
		}
		
		borderInfo.LeftTop = float2(borderWidthLeft, borderWidthTop);
		borderInfo.RightTop = float2(1.0-borderWidthLeft, borderWidthTop);
		borderInfo.LeftBottom = float2(borderWidthLeft, 1.0-borderWidthTop);
		borderInfo.RightBottom = float2(1.0-borderWidthLeft, 1.0-borderWidthTop);
		return borderInfo;
	}
	
	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////
	
	void PS_DrawBorder(VSBORDERINFO borderInfo, out float4 fragment : SV_Target0)
	{
		// check if the current pixel is in the border
		float4 originalFragment = tex2D(ReShade::BackBuffer, borderInfo.texcoord);
		float depthFragment = ReShade::GetLinearizedDepth(borderInfo.texcoord);
		// first easy peasy no rotation calcs
		bool isInFrameArea = borderInfo.texcoord.x > borderInfo.LeftTop.x && borderInfo.texcoord.x < borderInfo.RightTop.x &&
		                     borderInfo.texcoord.y > borderInfo.LeftTop.y && borderInfo.texcoord.y < borderInfo.RightBottom.y;
		fragment = isInFrameArea ? PictureAreaColor : BorderColor;
		fragment = depthFragment > (Depth / 1000.0) ? lerp(originalFragment, fragment, fragment.a) : originalFragment;
	}
	
	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique MagicBorder
#if __RESHADE__ >= 40000
	< ui_tooltip = "Magic Border "
			MAGIC_BORDER_VERSION
			"\n===========================================\n\n"
			"Magic Border is an easy way to create a border in a shot and have part of your\n"
			"shot in front of the border, like it jumps out of the frame.\n\n"
			"Magic Border was written by Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; >
#endif
	{
		pass DrawBorder { VertexShader = VS_CalculateBorderInfo; PixelShader = PS_DrawBorder;}
	}
}