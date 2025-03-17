using System.Collections.ObjectModel;
using System.Windows.Input;

namespace WpfGrowersApp.ViewModels
{
    public class HamburgerMenuViewModel : BaseViewModel
    {
        public ObservableCollection<MenuItem> MenuItems { get; set; }

        public ICommand NavigateCommand { get; set; }

        public HamburgerMenuViewModel()
        {
            MenuItems = new ObservableCollection<MenuItem>
            {
                new MenuItem { Title = "Home", Command = new RelayCommand(NavigateToHome) },
                new MenuItem { Title = "Growers", Command = new RelayCommand(NavigateToGrowers) },
                new MenuItem { Title = "Reports", Command = new RelayCommand(NavigateToReports) },
                new MenuItem { Title = "Settings", Command = new RelayCommand(NavigateToSettings) }
            };
        }

        private void NavigateToHome()
        {
            // Logic to navigate to Home
        }

        private void NavigateToGrowers()
        {
            // Logic to navigate to Growers
        }

        private void NavigateToReports()
        {
            // Logic to navigate to Reports
        }

        private void NavigateToSettings()
        {
            // Logic to navigate to Settings
        }
    }

    public class MenuItem
    {
        public string Title { get; set; }
        public ICommand Command { get; set; }
    }
}