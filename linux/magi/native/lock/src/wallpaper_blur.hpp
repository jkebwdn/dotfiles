#pragma once
#include <QImage>
namespace magi {
// One strong presentation default; working-pixel radius, independent of outputs.
inline constexpr double wallpaperTint = 0.42;
inline constexpr double wallpaperMaximumTint = 0.62;
inline constexpr double wallpaperDimStart = 0.30;
inline constexpr double wallpaperDimFull = 0.75;
inline constexpr int wallpaperWorkingExtent = 960;
inline constexpr int wallpaperBlurRadius = 9;
inline constexpr int wallpaperBlurPasses = 3;
QImage blurWallpaper(const QImage& source);
}
