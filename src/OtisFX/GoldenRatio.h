NAMESPACE_ENTER(OFX)
#include OFX_SETTINGS_DEF

#if USE_GOLDENRATIO

texture2D	GR_texSpirals < string source= "Reshade\\OtisFX\\Textures\\GoldenSpirals.png"; > { Width = 1748; Height = 1080; MipLevels = 1; Format = RGBA8; };
sampler2D	GR_samplerSpirals
{
	Texture = GR_texSpirals;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

void PS_OFX_GR_RenderSpirals(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 colFragment = tex2D(RFX_backbufferColor, float4(texcoord, 0, 0));
	float phiValue = ((1.0 + sqrt(5.0))/2.0);
	float aspectR = (float(BUFFER_WIDTH)/float(BUFFER_HEIGHT));
	float idealWidth = float(BUFFER_HEIGHT) * phiValue;
	float idealHeight = float(BUFFER_WIDTH) / phiValue;
	float4 sourceCoordFactor = float4(1.0, 1.0, 1.0, 1.0);

#if GR_ResizeMode==1	
	if(aspectR < phiValue)
	{
		// display spirals at full width, but resize across height
		sourceCoordFactor = float4(1.0, float(BUFFER_HEIGHT)/idealHeight, 1.0, idealHeight/float(BUFFER_HEIGHT));
	}
	else
	{
		// display spirals at full height, but resize across width
		sourceCoordFactor = float4(float(BUFFER_WIDTH)/idealWidth, 1.0, idealWidth/float(BUFFER_WIDTH), 1.0);
	}
#endif
	float4 spiralFragment = tex2D(GR_samplerSpirals, float4((texcoord.x * sourceCoordFactor.x) - ((1.0-sourceCoordFactor.z)/2.0),
														    (texcoord.y * sourceCoordFactor.y) - ((1.0-sourceCoordFactor.w)/2.0), 0, 0));
	outFragment = saturate(colFragment + (spiralFragment * GR_Opacity));
}

technique OFX_GR_Tech <bool enabled = false; int toggle = GR_ToggleKey; >
{
	pass OFX_GR_Desaturate
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_GR_RenderSpirals;
	}
}
#endif

#include OFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()