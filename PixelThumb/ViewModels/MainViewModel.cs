using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Data;
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
    private bool _fitSmallImages = true;
    private bool _fitLargeImages = true;
    private int _pixelScale = 4;
    private string _currentFolder = string.Empty;
    private string _statusText = "Select a folder";
    private bool _isLoading;
    private CancellationTokenSource? _loadCts;

    private int? _filterMinWidth;
    private int? _filterMaxWidth;
    private int? _filterMinHeight;
    private int? _filterMaxHeight;
    private bool _isFilterPopupOpen;
    private CancellationTokenSource? _filterDebounceCts;

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

    public bool FitSmallImages
    {
        get => _fitSmallImages;
        set
        {
            _fitSmallImages = value;
            OnPropertyChanged();
        }
    }

    public bool FitLargeImages
    {
        get => _fitLargeImages;
        set
        {
            _fitLargeImages = value;
            OnPropertyChanged();
        }
    }

    public int PixelScale
    {
        get => _pixelScale;
        set
        {
            if (_pixelScale == value) return;
            _pixelScale = value;
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

    public int? FilterMinWidth
    {
        get => _filterMinWidth;
        set { _filterMinWidth = value; OnPropertyChanged(); OnFilterChanged(); }
    }

    public int? FilterMaxWidth
    {
        get => _filterMaxWidth;
        set { _filterMaxWidth = value; OnPropertyChanged(); OnFilterChanged(); }
    }

    public int? FilterMinHeight
    {
        get => _filterMinHeight;
        set { _filterMinHeight = value; OnPropertyChanged(); OnFilterChanged(); }
    }

    public int? FilterMaxHeight
    {
        get => _filterMaxHeight;
        set { _filterMaxHeight = value; OnPropertyChanged(); OnFilterChanged(); }
    }

    public bool IsFilterActive => FilterMinWidth.HasValue || FilterMaxWidth.HasValue ||
                                   FilterMinHeight.HasValue || FilterMaxHeight.HasValue;

    public bool IsFilterPopupOpen
    {
        get => _isFilterPopupOpen;
        set { _isFilterPopupOpen = value; OnPropertyChanged(); }
    }

    public ICommand SelectFolderCommand { get; }
    public ICommand ShowInfoCommand { get; }
    public ICommand OpenInExplorerCommand { get; }
    public ICommand ClearFiltersCommand { get; }

    public MainViewModel()
    {
        SelectFolderCommand = new RelayCommand(SelectFolder);
        ShowInfoCommand = new RelayCommand<ImageItem>(ShowInfo);
        OpenInExplorerCommand = new RelayCommand<ImageItem>(OpenInExplorer);
        ClearFiltersCommand = new RelayCommand(ClearFilters);

        var view = CollectionViewSource.GetDefaultView(Images);
        view.Filter = FilterPredicate;
    }

    private bool FilterPredicate(object obj)
    {
        if (!IsFilterActive) return true;
        if (obj is not ImageItem item) return true;

        // Show items that haven't loaded yet
        if (item.PixelWidth == 0 && item.PixelHeight == 0 && !item.IsLoaded) return true;

        if (FilterMinWidth.HasValue && item.PixelWidth < FilterMinWidth.Value) return false;
        if (FilterMaxWidth.HasValue && item.PixelWidth > FilterMaxWidth.Value) return false;
        if (FilterMinHeight.HasValue && item.PixelHeight < FilterMinHeight.Value) return false;
        if (FilterMaxHeight.HasValue && item.PixelHeight > FilterMaxHeight.Value) return false;

        return true;
    }

    private void OnFilterChanged()
    {
        OnPropertyChanged(nameof(IsFilterActive));
        _filterDebounceCts?.Cancel();
        _filterDebounceCts = new CancellationTokenSource();
        var token = _filterDebounceCts.Token;
        _ = DebounceFilterAsync(token);
    }

    private async Task DebounceFilterAsync(CancellationToken token)
    {
        try
        {
            await Task.Delay(300, token);
            if (token.IsCancellationRequested) return;
            CollectionViewSource.GetDefaultView(Images).Refresh();
            UpdateFilteredStatusText();
        }
        catch (TaskCanceledException) { }
    }

    private void ClearFilters()
    {
        FilterMinWidth = null;
        FilterMaxWidth = null;
        FilterMinHeight = null;
        FilterMaxHeight = null;
    }

    private void UpdateFilteredStatusText()
    {
        if (!IsFilterActive || Images.Count == 0) return;
        var view = CollectionViewSource.GetDefaultView(Images);
        var filteredCount = view.Cast<object>().Count();
        StatusText = $"{filteredCount} / {Images.Count} images";
    }

    private void SelectFolder()
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog
        {
            Title = "Select Image Folder(s)",
            Multiselect = true
        };

        if (dialog.ShowDialog() == true)
        {
            var folders = dialog.FolderNames;
            CurrentFolder = string.Join("; ", folders.Select(Path.GetFileName));
            _ = LoadImagesAsync(folders);
        }
    }

    private async Task LoadImagesAsync(string[] folderPaths)
    {
        _loadCts?.Cancel();
        _loadCts = new CancellationTokenSource();
        var token = _loadCts.Token;

        IsLoading = true;
        Images.Clear();
        StatusText = "Searching for images...";

        var files = await Task.Run(() =>
        {
            return folderPaths
                .SelectMany(folder => Directory.EnumerateFiles(folder, "*.*", SearchOption.AllDirectories))
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
            var folderDisplay = folderPaths.Length == 1
                ? folderPaths[0]
                : $"{folderPaths.Length} folders";
            StatusText = $"{Images.Count} images ({folderDisplay})";
            IsLoading = false;

            if (IsFilterActive)
            {
                CollectionViewSource.GetDefaultView(Images).Refresh();
                UpdateFilteredStatusText();
            }
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
