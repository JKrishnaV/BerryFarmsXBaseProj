# WPF Growers Application

## Overview
The WPF Growers Application is a user-friendly desktop application designed to manage grower information efficiently. It features a modern GUI with a hamburger menu for easy navigation between different sections of the application, including a dedicated Growers screen for viewing and managing grower data.

## Project Structure
The project is organized into several key components:

- **WpfGrowersApp.sln**: The solution file that organizes the project and its components.
- **App.xaml**: Defines application-level resources and styles.
- **MainWindow.xaml**: The main window layout and controls.
- **Views**: Contains XAML files for different views, including the Growers screen and the hamburger menu.
- **ViewModels**: Contains the ViewModel classes that manage the data and logic for the views.
- **Models**: Contains the data models, including the Grower entity.
- **Services**: Contains services for data access and interactions with the SQL database.
- **Data**: Contains the Entity Framework database context for accessing grower data.
- **Resources**: Contains application-wide styles and resources.
- **App.config**: Configuration settings for the application.

## Setup Instructions
1. **Clone the Repository**: Clone the repository to your local machine using Git.
2. **Open the Solution**: Open the `WpfGrowersApp.sln` file in your preferred IDE.
3. **Restore NuGet Packages**: Restore any NuGet packages required for the project.
4. **Configure Database**: Update the connection string in `App.config` to point to your SQL database.
5. **Build the Project**: Build the solution to ensure all dependencies are resolved.
6. **Run the Application**: Start the application to view and manage grower information.

## Usage Guidelines
- Use the hamburger menu to navigate between different sections of the application.
- Access the Growers screen to view, add, edit, or delete grower information.
- Ensure that the SQL database is properly configured and accessible for data operations.

## Contributing
Contributions to the WPF Growers Application are welcome. Please fork the repository and submit a pull request with your changes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.