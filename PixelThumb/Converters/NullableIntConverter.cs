using System.Globalization;
using System.Windows.Data;

namespace PixelThumb.Converters;

public class NullableIntConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value is int i ? i.ToString() : string.Empty;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is string s && int.TryParse(s.Trim(), out var result) && result > 0)
            return result;
        return null;
    }
}
