using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using PixelThumb.Models;

namespace PixelThumb.ViewModels;

public class MainViewModel : INotifyPropertyChanged
{
    private static readonly HashSet<string> ImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".ico", ".tiff", ".tif"
    };

    private double _thumbnailSize = 96;
    private string _currentFolder = string.Empty;
    private string _statusText = "Select a folder";
    private bool _isLoading;
    private CancellationTokenSource? _loadCts;

    public ObservableCollection<ImageItem> Images { get; } = new();

    public double ThumbnailSize
    {
        get => _thumbnailSize;
        set
        {
            if (Math.Abs(_thumbnailSize - value) < 0.1) return;
            _thumbnailSize = value;
            OnPropertyChanged();
        }
    }

    public string CurrentFolder
    {
        get => _currentFolder;
        set { _currentFolder = value; OnPropertyChanged(); }
    }

    public string StatusText
    {
        get => _statusText;
        set { _statusText = value; OnPropertyChanged(); }
    }

    public bool IsLoading
    {
        get => _isLoading;
        set { _isLoading = value; OnPropertyChanged(); }
    }

    public ICommand SelectFolderCommand { get; }
    public ICommand ShowInfoCommand { get; }
    public ICommand OpenInExplorerCommand { get; }

    public MainViewModel()
    {
        SelectFolderCommand = new RelayCommand(SelectFolder);
        ShowInfoCommand = new RelayCommand<ImageItem>(ShowInfo);
        OpenInExplorerCommand = new RelayCommand<ImageItem>(OpenInExplorer);
    }

    private void SelectFolder()
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog
        {
            Title = "Select Image Folder"
        };

        if (dialog.ShowDialog() == true)
        {
            CurrentFolder = dialog.FolderName;
            _ = LoadImagesAsync(dialog.FolderName);
        }
    }

    private async Task LoadImagesAsync(string folderPath)
    {
        _loadCts?.Cancel();
        _loadCts = new CancellationTokenSource();
        var token = _loadCts.Token;

        IsLoading = true;
        Images.Clear();
        StatusText = "Searching for images...";

        var files = await Task.Run(() =>
        {
            return Directory.EnumerateFiles(folderPath, "*.*", SearchOption.AllDirectories)
                .Where(f => ImageExtensions.Contains(Path.GetExtension(f)))
                .ToList();
        }, token);

        if (token.IsCancellationRequested) return;

        StatusText = $"Loading {files.Count} images...";

        var items = files.Select(f => new ImageItem(f)).ToList();
        foreach (var item in items)
        {
            if (token.IsCancellationRequested) return;
            Images.Add(item);
        }

        StatusText = $"{Images.Count} images loaded";

        // Load thumbnails in batches on background thread
        const int batchSize = 50;
        for (int i = 0; i < items.Count; i += batchSize)
        {
            if (token.IsCancellationRequested) return;

            var batch = items.Skip(i).Take(batchSize).ToList();
            await Task.Run(() =>
            {
                foreach (var item in batch)
                {
                    if (token.IsCancellationRequested) return;
                    item.LoadThumbnail();
                }
            }, token);

            StatusText = $"Loading images {Math.Min(i + batchSize, items.Count)} / {items.Count}...";
        }

        if (!token.IsCancellationRequested)
        {
            StatusText = $"{Images.Count} images ({folderPath})";
            IsLoading = false;
        }
    }

    private void ShowInfo(ImageItem? item)
    {
        if (item == null) return;

        var info = $"File: {item.FileName}\n" +
                   $"Path: {item.FilePath}\n" +
                   $"Resolution: {item.PixelWidth} x {item.PixelHeight}\n" +
                   $"Size: {item.FileSizeText}";

        MessageBox.Show(info, "Image Info", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void OpenInExplorer(ImageItem? item)
    {
        if (item == null || !File.Exists(item.FilePath)) return;

        Process.Start("explorer.exe", $"/select,\"{item.FilePath}\"");
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}

public class RelayCommand : ICommand
{
    private readonly Action _execute;

    public RelayCommand(Action execute) => _execute = execute;

    public event EventHandler? CanExecuteChanged
    {
        add => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }

    public bool CanExecute(object? parameter) => true;
    public void Execute(object? parameter) => _execute();
}

public class RelayCommand<T> : ICommand
{
    private readonly Action<T?> _execute;

    public RelayCommand(Action<T?> execute) => _execute = execute;

    public event EventHandler? CanExecuteChanged
    {
        add => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }

    public bool CanExecute(object? parameter) => true;
    public void Execute(object? parameter) => _execute((T?)parameter);
}
