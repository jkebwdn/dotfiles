#include "wallpaper_blur.hpp"
#include <algorithm>
namespace magi {
QImage blurWallpaper(const QImage& source) {
    if (source.isNull()) return {};
    auto image=source.scaled(wallpaperWorkingExtent,wallpaperWorkingExtent,
        Qt::KeepAspectRatio,Qt::SmoothTransformation).convertToFormat(QImage::Format_ARGB32_Premultiplied);
    QImage scratch(image.size(),image.format());
    if (image.isNull() || scratch.isNull()) return {};
    // Three separable box passes approximate a Gaussian. Sliding sums make each
    // pass O(pixels), not O(radius*pixels). Clamped edges avoid dark crop borders.
    auto pass=[](const QImage& input,QImage& output,bool vertical) {
        const int length=vertical?input.height():input.width();
        const int lines=vertical?input.width():input.height();
        constexpr int radius=wallpaperBlurRadius, divisor=radius*2+1;
        for(int line=0;line<lines;++line) {
            auto pixel=[&](int position) {
                position=std::clamp(position,0,length-1);
                return reinterpret_cast<const QRgb*>(input.constScanLine(vertical?position:line))[vertical?line:position];
            };
            int r=0,g=0,b=0,a=0;
            auto add=[&](QRgb p,int sign) { r+=sign*qRed(p);g+=sign*qGreen(p);b+=sign*qBlue(p);a+=sign*qAlpha(p); };
            for(int i=-radius;i<=radius;++i) add(pixel(i),1);
            for(int i=0;i<length;++i) {
                reinterpret_cast<QRgb*>(output.scanLine(vertical?i:line))[vertical?line:i]=qRgba(r/divisor,g/divisor,b/divisor,a/divisor);
                add(pixel(i-radius),-1); add(pixel(i+radius+1),1);
            }
        }
    };
    for(int i=0;i<wallpaperBlurPasses;++i) { pass(image,scratch,false);pass(scratch,image,true); }
    return image;
}
}
