using System.ComponentModel;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using PixelThumb.Models;
using PixelThumb.ViewModels;

namespace PixelThumb;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        if (DataContext is MainViewModel vm)
        {
            vm.PropertyChanged += ViewModel_PropertyChanged;
        }
    }

    private void ViewModel_PropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(MainViewModel.ThumbnailSize))
        {
            ScrollToTop(ImageListBox);
        }
    }

    private static void ScrollToTop(DependencyObject depObj)
    {
        var scrollViewer = FindVisualChild<ScrollViewer>(depObj);
        scrollViewer?.ScrollToTop();
    }

    private void ImageListBox_MouseDoubleClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if (ImageListBox.SelectedItem is ImageItem item)
        {
            Process.Start(new ProcessStartInfo(item.FilePath) { UseShellExecute = true });
        }
    }

    private static T? FindVisualChild<T>(DependencyObject parent) where T : DependencyObject
    {
        for (int i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i);
            if (child is T found)
                return found;

            var result = FindVisualChild<T>(child);
            if (result != null)
                return result;
        }
        return null;
    }
}
