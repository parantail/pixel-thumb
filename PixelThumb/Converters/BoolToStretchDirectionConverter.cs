using System.Globalization;
using System.Windows.Controls;
using System.Windows.Data;

namespace PixelThumb.Converters;

public class BoolToStretchDirectionConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return value is true ? StretchDirection.Both : StretchDirection.DownOnly;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
