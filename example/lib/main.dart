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
    return [
      Employee(10001, 'James', 'Project Lead', 20000),
      Employee(10002, 'Kathryn', 'Manager', 30000),
      Employee(10003, 'Lara', 'Developer', 15000),
      Employee(10004, 'Michael', 'Designer', 15000),
      Employee(10005, 'Martin', 'Developer', 15000),
      Employee(10006, 'Newberry', 'Developer', 15000),
      Employee(10007, 'Balnc', 'Developer', 15000),
      Employee(10008, 'Perry', 'Developer', 15000),
      Employee(10009, 'Gable', 'Developer', 15000),
      Employee(10010, 'Grimes', 'Developer', 15000),
      Employee(10011, 'Oliver', 'Developer', 15000),
      Employee(10012, 'Harry', 'Developer', 15000),
      Employee(10013, 'Jack', 'Developer', 15000),
      Employee(10014, 'George', 'Developer', 15000),
      Employee(10015, 'Noah', 'Developer', 15000),
      Employee(10016, 'Charlie', 'Developer', 15000),
      Employee(10017, 'Jacob', 'Developer', 15000),
      Employee(10018, 'Thomas', 'Developer', 15000),
      Employee(10019, 'Oscar', 'Developer', 15000),
      Employee(10020, 'William', 'Developer', 15000),
      Employee(10021, 'James', 'Developer', 15000),
      Employee(10022, 'Alfie', 'Developer', 15000),
      Employee(10023, 'Henry', 'Developer', 15000),
      Employee(10024, 'Alexander', 'Developer', 15000),
      Employee(10025, 'Leo', 'Developer', 15000),
    ];
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
