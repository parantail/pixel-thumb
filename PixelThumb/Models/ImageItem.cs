using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;
using System.Windows.Media.Imaging;

namespace PixelThumb.Models;

public class ImageItem : INotifyPropertyChanged
{
    private BitmapImage? _thumbnail;
    private bool _isLoaded;

    public string FilePath { get; }
    public string FileName { get; }
    public long FileSize { get; }
    public int PixelWidth { get; private set; }
    public int PixelHeight { get; private set; }

    public BitmapImage? Thumbnail
    {
        get => _thumbnail;
        private set { _thumbnail = value; OnPropertyChanged(); }
    }

    public bool IsLoaded
    {
        get => _isLoaded;
        private set { _isLoaded = value; OnPropertyChanged(); }
    }

    public string FileSizeText
    {
        get
        {
            if (FileSize < 1024) return $"{FileSize} B";
            if (FileSize < 1024 * 1024) return $"{FileSize / 1024.0:F1} KB";
            return $"{FileSize / (1024.0 * 1024.0):F1} MB";
        }
    }

    public ImageItem(string filePath)
    {
        FilePath = filePath;
        FileName = Path.GetFileName(filePath);
        var info = new FileInfo(filePath);
        FileSize = info.Exists ? info.Length : 0;
    }

    public void LoadThumbnail()
    {
        if (IsLoaded) return;

        try
        {
            var bi = new BitmapImage();
            bi.BeginInit();
            bi.UriSource = new Uri(FilePath, UriKind.Absolute);
            bi.CacheOption = BitmapCacheOption.OnLoad;
            bi.CreateOptions = BitmapCreateOptions.IgnoreColorProfile;
            bi.EndInit();
            bi.Freeze();

            PixelWidth = bi.PixelWidth;
            PixelHeight = bi.PixelHeight;
            Thumbnail = bi;
            IsLoaded = true;

            OnPropertyChanged(nameof(PixelWidth));
            OnPropertyChanged(nameof(PixelHeight));
        }
        catch
        {
            IsLoaded = true;
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
