using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using WpfGrowersApp.Models;
using WpfGrowersApp.Services;

namespace WpfGrowersApp.ViewModels
{
    public class GrowersViewModel : INotifyPropertyChanged
    {
        private readonly DataService _dataService;
        private ObservableCollection<Grower> _growers;
        private Grower _selectedGrower;

        public GrowersViewModel()
        {
            _dataService = new DataService();
            LoadGrowers();
            AddGrowerCommand = new RelayCommand(AddGrower);
            DeleteGrowerCommand = new RelayCommand(DeleteGrower, CanDeleteGrower);
        }

        public ObservableCollection<Grower> Growers
        {
            get => _growers;
            set
            {
                _growers = value;
                OnPropertyChanged();
            }
        }

        public Grower SelectedGrower
        {
            get => _selectedGrower;
            set
            {
                _selectedGrower = value;
                OnPropertyChanged();
                DeleteGrowerCommand.RaiseCanExecuteChanged();
            }
        }

        public ICommand AddGrowerCommand { get; }
        public ICommand DeleteGrowerCommand { get; }

        private void LoadGrowers()
        {
            Growers = new ObservableCollection<Grower>(_dataService.GetAllGrowers());
        }

        private void AddGrower()
        {
            var newGrower = new Grower(); // Initialize a new Grower object
            // Logic to add a new grower (e.g., open a dialog to enter details)
            LoadGrowers(); // Refresh the list after adding
        }

        private void DeleteGrower()
        {
            if (SelectedGrower != null)
            {
                _dataService.DeleteGrower(SelectedGrower);
                LoadGrowers(); // Refresh the list after deletion
            }
        }

        private bool CanDeleteGrower()
        {
            return SelectedGrower != null;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}