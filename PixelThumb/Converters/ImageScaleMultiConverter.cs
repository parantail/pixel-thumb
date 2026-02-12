using System.Globalization;
using System.Windows.Data;

namespace PixelThumb.Converters;

public class ImageScaleMultiConverter : IMultiValueConverter
{
    public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
    {
        if (values.Length < 6) return 1.0;

        var pixelWidth = values[0] is int pw ? (double)pw : 0;
        var pixelHeight = values[1] is int ph ? (double)ph : 0;
        var fitSmall = values[2] is bool fs && fs;
        var fitLarge = values[3] is bool fl && fl;
        var pixelScale = values[4] is int ps ? (double)ps : 1;
        var containerSize = values[5] is double cs ? cs : 0;

        if (pixelWidth <= 0 || pixelHeight <= 0 || containerSize <= 0)
            return 1.0;

        if (fitSmall)
        {
            var scale = Math.Min(containerSize / pixelWidth, containerSize / pixelHeight);
            if (!fitLarge)
                scale = Math.Max(scale, 1.0);
            return scale;
        }
        else
        {
            var scaledW = pixelWidth * pixelScale;
            var scaledH = pixelHeight * pixelScale;

            if (fitLarge && (scaledW > containerSize || scaledH > containerSize))
            {
                var fitScale = Math.Min(containerSize / scaledW, containerSize / scaledH);
                return pixelScale * fitScale;
            }

            return pixelScale;
        }
    }

    public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
