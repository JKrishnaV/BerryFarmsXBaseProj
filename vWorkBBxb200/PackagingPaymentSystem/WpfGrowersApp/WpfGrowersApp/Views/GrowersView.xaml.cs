using System.Windows;
using WpfGrowersApp.ViewModels;

namespace WpfGrowersApp.Views
{
    public partial class GrowersView : Window
    {
        public GrowersView()
        {
            InitializeComponent();
            this.DataContext = new GrowersViewModel();
        }

        private void AddGrowerButton_Click(object sender, RoutedEventArgs e)
        {
            // Logic to add a new grower
        }

        private void EditGrowerButton_Click(object sender, RoutedEventArgs e)
        {
            // Logic to edit the selected grower
        }

        private void DeleteGrowerButton_Click(object sender, RoutedEventArgs e)
        {
            // Logic to delete the selected grower
        }

        private void RefreshButton_Click(object sender, RoutedEventArgs e)
        {
            // Logic to refresh the grower list
        }
    }
}