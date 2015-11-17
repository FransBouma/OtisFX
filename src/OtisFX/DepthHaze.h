NAMESPACE_ENTER(OFX)

#include OFX_SETTINGS_DEF

#if USE_DEPTHHAZE
///////////////////////////////////////////////////////////////////
// This effect works like a one-side DoF for distance haze, which slightly
// blurs far away elements. A normal DoF has a focus point and blurs using
// two planes. 
//
// It works by first blurring the screen buffer using 2-pass block blur and
// then blending the blurred result into the screen buffer based on depth
///////////////////////////////////////////////////////////////////

float ConvertToGrey(float4 fragment)
{
	return dot(fragment.rgb, float3(0.3, 0.59, 0.11));
}

void PS_OFX_DEH_BlockBlurHorizontal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(RFX_backbufferColor, texcoord);
	float originalGrayscale = ConvertToGrey(color);
	float n = 1.0f;

	[loop]
	for(int i = 1; i < 5; ++i) 
	{
		float2 sourceCoords = texcoord + float2(i * RFX_pixelSize.x, 0.0);
		float4 neighborFragment = tex2D(RFX_backbufferColor, sourceCoords);
		// detect contrast using grey scale comparison. Ignore high contrasting pixels to avoid edge bleed and shimmering
		if(abs(originalGrayscale - ConvertToGrey(neighborFragment)) < DEH_EdgeBleedThreshold)
		{
			color += neighborFragment;
			n++;
		}
		sourceCoords = texcoord - float2(i * RFX_pixelSize.x, 0.0);
		neighborFragment = tex2D(RFX_backbufferColor, sourceCoords);
		if(abs(originalGrayscale - ConvertToGrey(neighborFragment)) < DEH_EdgeBleedThreshold)
		{
			color += neighborFragment;
			n++;
		}
	}
	outFragment = color/n;
}

void PS_OFX_DEH_BlockBlurVertical(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(OFX_SamplerFragmentBuffer1, texcoord);
	float originalGrayscale = ConvertToGrey(color);
	float n=1.0f;
	
	[loop]
	for(int j = 1; j < 5; ++j) 
	{
		float2 sourceCoords = texcoord + float2(0.0, j * RFX_pixelSize.y);
		float4 neighborFragment = tex2D(OFX_SamplerFragmentBuffer1, sourceCoords);
		if(abs(originalGrayscale - ConvertToGrey(neighborFragment)) < DEH_EdgeBleedThreshold)
		{
			color += neighborFragment;
			n++;
		}
		sourceCoords = texcoord - float2(0.0, j * RFX_pixelSize.y);
		neighborFragment = tex2D(OFX_SamplerFragmentBuffer1, sourceCoords);
		if(abs(originalGrayscale - ConvertToGrey(neighborFragment)) < DEH_EdgeBleedThreshold)
		{
			color += neighborFragment;
			n++;
		}
	}
	outFragment = color/n;
}

void PS_OFX_DEH_BlendBlurWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	float4 blurredFragment = tex2D(OFX_SamplerFragmentBuffer2, texcoord);
	float4 screenBufferFragment = tex2D(RFX_backbufferColor, texcoord);
	float screenDepth = tex2D(RFX_depthTexColor,texcoord).r;
	fragment = lerp(screenBufferFragment, blurredFragment, clamp(screenDepth * DEH_EffectStrength, 0, 1)); 
}

technique OFX_DEH_Tech <bool enabled = false; int toggle = DEH_ToggleKey; >
{
	// 3 passes. First 2 passes blur screenbuffer into OFX_FragmentBuffer2 using 2 pass block blur with 10 samples each (so 2 passes needed)
	// 3rd pass blends blurred fragments based on depth with screenbuffer.
	pass OFX_DEH_Pass0
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlockBlurHorizontal;
		RenderTarget = OFX_FragmentBuffer1;
	}

	pass OFX_DEH_Pass1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlockBlurVertical;
		RenderTarget = OFX_FragmentBuffer2;
	}
	
	pass OFX_DEH_Pass2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlendBlurWithNormalBuffer;
	}
}
#endif

#include OFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()