import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

void main() {
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
  int rowsPerPage = 10;
  bool useCompactPager = true;

  @override
  void initState() {
    super.initState();
    employees = getEmployeeData();
    employeeDataSource = EmployeeDataSource(employeeData: employees);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion Flutter DataGrid'),
        actions: [
          Switch(
            value: useCompactPager,
            onChanged: (value) {
              setState(() {
                useCompactPager = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(useCompactPager ? 'Compact' : 'Regular'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfDataGrid(
              source: employeeDataSource,
              columnWidthMode: ColumnWidthMode.fill,
              rowsPerPage: rowsPerPage,
              columns: <GridColumn>[
                GridColumn(
                    columnName: 'id',
                    label: Container(
                        padding: EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Text(
                          'ID',
                        ))),
                GridColumn(
                    columnName: 'name',
                    label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text('Name'))),
                GridColumn(
                    columnName: 'designation',
                    label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text(
                          'Designation',
                          overflow: TextOverflow.ellipsis,
                        ))),
                GridColumn(
                    columnName: 'salary',
                    label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text('Salary'))),
              ],
            ),
          ),
          Container(
            height: 60,
            child: useCompactPager
                ? SfCompactDataPager(
                    delegate: employeeDataSource,
                    pageCount: (employees.length / rowsPerPage).ceil().toDouble(),
                    visibleItemsCount: 3, // Show max 3 page numbers
                    totalRows: employees.length, // Total rows for web display
                    availableRowsPerPage: const [5, 10, 15, 20],
                    onRowsPerPageChanged: (int? rowsPerPage) {
                      setState(() {
                        this.rowsPerPage = rowsPerPage!;
                        employeeDataSource.updateDataGrindSource();
                      });
                    },
                  )
                : SfDataPager(
                    delegate: employeeDataSource,
                    pageCount: (employees.length / rowsPerPage).ceil().toDouble(),
                    visibleItemsCount: 5,
                    availableRowsPerPage: const [5, 10, 15, 20],
                    onRowsPerPageChanged: (int? rowsPerPage) {
                      setState(() {
                        this.rowsPerPage = rowsPerPage!;
                        employeeDataSource.updateDataGrindSource();
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Employee> getEmployeeData() {
    List<Employee> employees = [];
    List<String> names = ['James', 'Kathryn', 'Lara', 'Michael', 'Martin', 'Newberry', 'Blanc', 'Perry', 'Gable', 'Grimes', 'Oliver', 'Harry', 'Jack', 'George', 'Noah', 'Charlie', 'Jacob', 'Thomas', 'Oscar', 'William', 'Alfie', 'Henry', 'Alexander', 'Leo', 'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Mia'];
    List<String> designations = ['Project Lead', 'Manager', 'Developer', 'Designer', 'Analyst', 'Tester', 'Architect', 'DevOps', 'Consultant'];
    
    // Generate 6700 employees for better pagination testing with comma formatting
    for (int i = 1; i <= 6700; i++) {
      employees.add(Employee(
        10000 + i,
        names[i % names.length],
        designations[i % designations.length],
        15000 + (i % 20) * 1000, // Vary salary
      ));
    }
    
    return employees;
  }
}

/// Custom business object class which contains properties to hold the detailed
/// information about the employee which will be rendered in datagrid.
class Employee {
  /// Creates the employee class with required details.
  Employee(this.id, this.name, this.designation, this.salary);

  /// Id of an employee.
  final int id;

  /// Name of an employee.
  final String name;

  /// Designation of an employee.
  final String designation;

  /// Salary of an employee.
  final int salary;
}

/// An object to set the employee collection data source to the datagrid. This
/// is used to map the employee data to the datagrid widget.
class EmployeeDataSource extends DataGridSource {
  /// Creates the employee data source class with required details.
  EmployeeDataSource({required List<Employee> employeeData}) {
    _employeeData = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<int>(columnName: 'id', value: e.id),
              DataGridCell<String>(columnName: 'name', value: e.name),
              DataGridCell<String>(
                  columnName: 'designation', value: e.designation),
              DataGridCell<int>(columnName: 'salary', value: e.salary),
            ]))
        .toList();
  }

  List<DataGridRow> _employeeData = [];

  @override
  List<DataGridRow> get rows => _employeeData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }

  @override
  Future<bool> handlePageChange(int oldPageIndex, int newPageIndex) async {
    return true;
  }

  /// Update DataGrid source
  void updateDataGrindSource() {
    notifyListeners();
  }
}
