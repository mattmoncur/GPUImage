#import "GPUImagePixellateFilter.h"

NSString *const kGPUImagePixellationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float fractionalWidthOfPixel;
 uniform highp float aspectRatio;

 void main()
 {
     highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
     
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
     gl_FragColor = texture2D(inputImageTexture, samplePos );
 }
 );

@interface GPUImagePixellateFilter ()

@property (readwrite, nonatomic) CGFloat aspectRatio;

@end

@implementation GPUImagePixellateFilter

@synthesize fractionalWidthOfAPixel = _fractionalWidthOfAPixel;
@synthesize aspectRatio = _aspectRatio;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePixellationFragmentShaderString]))
    {
		return nil;
    }
    
    fractionalWidthOfAPixelUniform = [filterProgram uniformIndex:@"fractionalWidthOfPixel"];
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];

    self.fractionalWidthOfAPixel = 0.05;
    
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];
    
    if (!CGSizeEqualToSize(oldInputSize, inputTextureSize))
    {
        [self setAspectRatio:(inputTextureSize.width / inputTextureSize.height)];
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setFractionalWidthOfAPixel:(CGFloat)newValue;
{
    CGFloat singlePixelSpacing;
    if (inputTextureSize.width != 0.0)
    {
        singlePixelSpacing = 1.0 / inputTextureSize.width;
    }
    else
    {
        singlePixelSpacing = 1.0 / 2048.0;
    }
    
    if (newValue < singlePixelSpacing)
    {
        _fractionalWidthOfAPixel = singlePixelSpacing;
    }
    else
    {
        _fractionalWidthOfAPixel = newValue;
    }
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(fractionalWidthOfAPixelUniform, _fractionalWidthOfAPixel);
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(aspectRatioUniform, _aspectRatio);
}

@end
