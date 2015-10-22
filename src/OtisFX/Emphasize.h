NAMESPACE_ENTER(OFX)
#include OFX_SETTINGS_DEF

#if USE_EMPHASIZE
texture   OFX_EMZ_CoCBuffer	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;  Format = RGBA16F;};
sampler2D OFX_EMZ_SamplerCoCBuffer
{
	Texture = OFX_EMZ_CoCBuffer;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

void PS_OFX_EMZ_CalculateCoCFragments(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 cocFragment : SV_Target0)
{
	const float scenedepth = tex2D(RFX_depthTexColor, texcoord).r;
	const float scenefocus =  EMZ_MANUALFOCUSDEPTH;
	const float desaturateFullRange = EMZ_FOCUSRANGEDEPTH+EMZ_FOCUSEDGEDEPTH;
	float depthdiff = abs(scenedepth-scenefocus);
	depthdiff = (depthdiff > desaturateFullRange) ? depthdiff = 1.0 : smoothstep(scenefocus, scenefocus+desaturateFullRange, scenefocus + depthdiff);
	cocFragment = saturate(float4(depthdiff, scenedepth, scenefocus, 0));
}

void PS_OFX_EMZ_Desaturate(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	const float depthDiffCoC = tex2D(OFX_EMZ_SamplerCoCBuffer, texcoord.xy).x;	
	const float4 colFragment = tex2Dlod(OFX_SamplerFragmentBuffer1, float4(texcoord, 0, 0));
	const float greyscaleAverage = (colFragment.x + colFragment.y + colFragment.z) / 3.0;
	float4 desColor = float4(greyscaleAverage, greyscaleAverage, greyscaleAverage, depthDiffCoC);
	desColor = lerp(desColor, float4(EMZ_BlendColor, depthDiffCoC), EMZ_BlendFactor);
	outFragment = lerp(colFragment, desColor, saturate(depthDiffCoC * EMZ_EffectFactor));
}

technique OFX_EMZ_Tech <bool enabled = RFX_Start_Enabled; int toggle = EMZ_ToggleKey; >
{
	pass OFX_EMZ_CoC
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_EMZ_CalculateCoCFragments;
		RenderTarget = OFX_EMZ_CoCBuffer;
	}
	pass OFX_EMZ_Desaturate
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_EMZ_Desaturate;
		RenderTarget = OFX_FragmentBuffer2;
	}
	pass OFX_EMZ_Overlay
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_Overlay;
	}
}
#endif

#include OFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()