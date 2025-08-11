import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones(); // Initialize timezone data
  runApp(MyApp());
}

/// The application that contains datagrid on it.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncfusion DataGrid Demo',
      theme: ThemeData(useMaterial3: false),
      home: MyHomePage(),
    );
  }
}

/// The home page of the application which hosts the datagrid.
class MyHomePage extends StatefulWidget {
  /// Creates the home page.
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Employee> employees = <Employee>[];
  late EmployeeDataSource employeeDataSource;

  @override
  void initState() {
    super.initState();
    employees = getEmployeeData();
    employeeDataSource = EmployeeDataSource(employeeData: employees);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syncfusion Flutter DataGrid')),
      body: SfDataGrid(
        source: employeeDataSource,
        columnWidthMode: ColumnWidthMode.fill,
        allowFiltering: true,
        columns: <GridColumn>[
          GridColumn(
            columnName: 'id',
            columnType: GridColumnType.number,
            label: Container(
              padding: EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: Text('ID'),
            ),
          ),
          GridColumn(
            columnName: 'name',
            columnType: GridColumnType.string,
            label: Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text('Name'),
            ),
          ),
          GridColumn(
            columnName: 'designation',
            columnType: GridColumnType.string,
            label: Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text('Designation', overflow: TextOverflow.ellipsis),
            ),
          ),
          GridColumn(
            columnName: 'salary',
            columnType: GridColumnType.number,
            label: Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text('Salary'),
            ),
          ),
          GridColumn(
            columnName: 'hireDate',
            columnType: GridColumnType.dateTime,
            timezone: 'America/New_York',
            label: Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text('Hire Date'),
            ),
          ),
        ],
      ),
    );
  }

  List<Employee> getEmployeeData() {
    return [
      Employee(10001, 'James', 'Project Lead', 20000, DateTime(2020, 1, 15)),
      Employee(10002, 'Kathryn', 'Manager', 30000, DateTime(2019, 3, 10)),
      Employee(10003, 'Lara', 'Developer', 15000, DateTime(2021, 7, 22)),
      Employee(10004, 'Michael', 'Designer', 15000, DateTime(2020, 11, 5)),
      Employee(10005, 'Martin', 'Developer', 15000, DateTime(2022, 2, 14)),
      Employee(10006, 'Newberry', 'Developer', 15000, DateTime(2021, 9, 18)),
      Employee(10007, 'Balnc', 'Developer', 15000, DateTime(2020, 6, 30)),
      Employee(10008, 'Perry', 'Developer', 15000, DateTime(2019, 12, 8)),
      Employee(10009, 'Gable', 'Developer', 15000, DateTime(2022, 4, 25)),
      Employee(10010, 'Grimes', 'Developer', 15000, DateTime(2021, 1, 12)),
    ];
  }
}

/// Custom business object class which contains properties to hold the detailed
/// information about the employee which will be rendered in datagrid.
class Employee {
  /// Creates the employee class with required details.
  Employee(this.id, this.name, this.designation, this.salary, this.hireDate);

  /// Id of an employee.
  final int id;

  /// Name of an employee.
  final String name;

  /// Designation of an employee.
  final String designation;

  /// Salary of an employee.
  final int salary;

  /// Hire date of an employee.
  final DateTime hireDate;
}

/// An object to set the employee collection data source to the datagrid. This
/// is used to map the employee data to the datagrid widget.
class EmployeeDataSource extends DataGridSource {
  /// Creates the employee data source class with required details.
  EmployeeDataSource({required List<Employee> employeeData}) {
    _employeeData =
        employeeData
            .map<DataGridRow>(
              (e) => DataGridRow(
                cells: [
                  DataGridCell<int>(columnName: 'id', value: e.id),
                  DataGridCell<String>(columnName: 'name', value: e.name),
                  DataGridCell<String>(
                    columnName: 'designation',
                    value: e.designation,
                  ),
                  DataGridCell<int>(columnName: 'salary', value: e.salary),
                  DataGridCell<DateTime>(columnName: 'hireDate', value: e.hireDate),
                ],
              ),
            )
            .toList();
  }

  List<DataGridRow> _employeeData = [];

  @override
  List<DataGridRow> get rows => _employeeData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        String displayValue = e.value.toString();
        if (e.value is DateTime) {
          final DateTime date = e.value as DateTime;
          displayValue = '${date.month}/${date.day}/${date.year}';
        }
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(8.0),
          child: Text(displayValue),
        );
      }).toList(),
    );
  }
}
