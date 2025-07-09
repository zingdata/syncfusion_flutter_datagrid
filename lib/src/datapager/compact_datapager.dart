// ignore_for_file: avoid_setters_without_getters, avoid_redundant_argument_values

part of 'sfdatapager.dart';

class SfCompactDataPager extends StatefulWidget {
  /// Creates a compact widget describing a datapager.
  ///
  /// The [pageCount] and [delegate] argument must be defined and must not
  /// be null.
  const SfCompactDataPager(
      {required this.pageCount,
      required this.delegate,
      Key? key,
      this.itemHeight = 40.0,
      this.itemPadding = const EdgeInsets.all(5),
      this.navigationItemHeight = 40.0,
      this.navigationItemWidth = 40.0,
      this.firstPageItemVisible = true,
      this.lastPageItemVisible = true,
      this.nextPageItemVisible = true,
      this.previousPageItemVisible = true,
      this.visibleItemsCount = 3,
      this.initialPageIndex = 0,
      this.onPageNavigationStart,
      this.onPageNavigationEnd,
      this.onRowsPerPageChanged,
      this.availableRowsPerPage = const <int>[10, 15, 20],
      this.controller,
      this.totalRows})
      : assert(pageCount > 0),
        assert(itemHeight > 0),
        assert(visibleItemsCount > 0),
        assert(availableRowsPerPage.length != 0),
        assert((firstPageItemVisible ||
                lastPageItemVisible ||
                nextPageItemVisible ||
                previousPageItemVisible) &&
            (navigationItemHeight > 0 && navigationItemWidth > 0)),
        super(key: key);

  /// The number of pages required to display in [SfCompactDataPager].
  final double pageCount;

  /// The maximum number of page items to show in view.
  final int visibleItemsCount;

  /// The height of each item.
  final double itemHeight;

  /// The padding of each item including navigation items.
  final EdgeInsetsGeometry itemPadding;

  /// Decides whether first page navigation item should be visible.
  final bool firstPageItemVisible;

  /// Decides whether last page navigation item should be visible.
  final bool lastPageItemVisible;

  /// Decides whether previous page navigation item should be visible.
  final bool previousPageItemVisible;

  /// Decides whether next page navigation item should be visible.
  final bool nextPageItemVisible;

  /// The height of navigation items.
  final double navigationItemHeight;

  /// The width of navigation items.
  final double navigationItemWidth;

  /// A delegate that provides the row count details and method to listen the
  /// page navigation.
  final DataPagerDelegate delegate;

  /// The page to show when first creating the [SfCompactDataPager].
  final int initialPageIndex;

  /// An object that can be used to control the position to which this page is
  /// scrolled.
  final DataPagerController? controller;

  /// Called when page is being navigated.
  final PageNavigationStart? onPageNavigationStart;

  /// Called when page is successfully navigated.
  final PageNavigationEnd? onPageNavigationEnd;

  /// Invoked when the user selects a different number of rows per page.
  final ValueChanged<int?>? onRowsPerPageChanged;

  /// The options to offer for the rowsPerPage.
  final List<int> availableRowsPerPage;

  /// Total number of rows in the data source.
  /// Used for displaying "Rows X - Y of Total" format on web.
  final int? totalRows;

  @override
  SfCompactDataPagerState createState() => SfCompactDataPagerState();
}

/// A state class of a [SfCompactDataPager] StatefulWidget.
class SfCompactDataPagerState extends State<SfCompactDataPager> {
  static const double _kMobileViewWidthOnWeb = 767.0;
  static const Size _dropdownSize = Size(82, 36);
  
  DataPagerController? _controller;
  late SfLocalizations _localization;
  late DataPagerThemeHelper? _dataPagerThemeHelper;

  int _pageCount = 0;
  int _currentPageIndex = 0;
  int? _rowsPerPage;
  bool _isDesktop = false;
  bool _isInitialLoading = true;
  bool _isRowsPerPageChanged = false;
  TextDirection _textDirection = TextDirection.ltr;

  bool get _isRTL => _textDirection == TextDirection.rtl;
  int get _lastPageIndex => _pageCount - 1;

  /// Formats numbers with comma separators (e.g., 1000 -> 1,000)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  @override
  void initState() {
    super.initState();
    _rowsPerPage = _getAvailableRowsPerPage(getRowsPerPage(widget.delegate));
    _setPageCountInDataGridSource(widget.pageCount);
    _controller = widget.controller ?? DataPagerController()
      ..addListener(_handleDataPagerControlPropertyChanged);
    _addDelegateListener();
  }

  int? _getAvailableRowsPerPage(int? count) {
    if (count != null && widget.availableRowsPerPage.contains(count)) {
      return count;
    } else {
      return widget.availableRowsPerPage[0];
    }
  }

  void _addDelegateListener() {
    final Object delegate = widget.delegate;
    if (delegate is ChangeNotifier) {
      delegate.addListener(_handleDataPagerDelegatePropertyChanged);
    }
  }

  void _removeDelegateListener(SfCompactDataPager oldWidget) {
    final Object delegate = oldWidget.delegate;
    if (delegate is ChangeNotifier) {
      delegate.removeListener(_handleDataPagerDelegatePropertyChanged);
    }
  }

  void _handleDataPagerDelegatePropertyChanged() {
    if (!_suspendDataPagerUpdate && _isInitialLoading) {
      if (widget.initialPageIndex > 0) {
        final int index = widget.initialPageIndex;
        _handlePageItemTapped(index, _isInitialLoading);
      } else {
        _handlePageItemTapped(_currentPageIndex, _isInitialLoading);
      }
      _isInitialLoading = false;
    } else if (!_suspendDataPagerUpdate && _isRowsPerPageChanged) {
      _isRowsPerPageChanged = false;
      _handlePageItemTapped(_currentPageIndex);
    } else if (!_suspendDataPagerUpdate) {
      _handlePageItemTapped(_currentPageIndex);
    }
  }

  void _setPageCountInDataGridSource(double pageCount) {
    if (widget.delegate is DataGridSource) {
      setPageCount(widget.delegate, pageCount);
    }
  }

  Future<void> _handlePageItemTapped(int index, [bool isInitialLoading = false]) async {
    if (_suspendDataPagerUpdate) {
      return;
    }
    _suspendDataPagerUpdate = true;

    if (index > widget.pageCount - 1) {
      index = (widget.pageCount - 1).toInt();
    }

    final bool canRaiseNavigationEndCallback =
        _controller!.selectedPageIndex != index || isInitialLoading;
    final bool canChange = await _canChangePage(index, isInitialLoading);

    if (canChange) {
      if (mounted) {
        setState(() {
          _setCurrentPageIndex(index);
        });
      }
    }
    if (canRaiseNavigationEndCallback) {
      _raisePageNavigationEnd(canChange ? index : _currentPageIndex);
    }

    _suspendDataPagerUpdate = false;
  }

  Future<void> _handleDataPagerControlPropertyChanged({String? property}) async {
    _suspendDataPagerUpdate = true;
    
    switch (property) {
      case 'first':
        if (_currentPageIndex == 0) {
          _suspendDataPagerUpdate = false;
          return;
        }
        final bool canChangePage = await _canChangePage(0);
        if (canChangePage) {
          _setCurrentPageIndex(0);
        }
        _raisePageNavigationEnd(canChangePage ? 0 : _currentPageIndex);
        break;
      case 'last':
        if (_lastPageIndex <= 0) {
          _suspendDataPagerUpdate = false;
          return;
        }
        final bool canChangePage = await _canChangePage(_lastPageIndex);
        if (canChangePage) {
          _setCurrentPageIndex(_lastPageIndex);
        }
        _raisePageNavigationEnd(canChangePage ? _lastPageIndex : _currentPageIndex);
        break;
      case 'previous':
        final int previousIndex = _currentPageIndex - 1;
        if (previousIndex.isNegative || previousIndex == _currentPageIndex) {
          _suspendDataPagerUpdate = false;
          return;
        }
        final bool canChangePage = await _canChangePage(previousIndex);
        if (canChangePage) {
          _setCurrentPageIndex(previousIndex);
        }
        _raisePageNavigationEnd(canChangePage ? previousIndex : _currentPageIndex);
        break;
      case 'next':
        final int nextPageIndex = _currentPageIndex + 1;
        if (nextPageIndex > _lastPageIndex || nextPageIndex == _currentPageIndex) {
          _suspendDataPagerUpdate = false;
          return;
        }
        final bool canChangePage = await _canChangePage(nextPageIndex);
        if (canChangePage) {
          _setCurrentPageIndex(nextPageIndex);
        }
        _raisePageNavigationEnd(canChangePage ? nextPageIndex : _currentPageIndex);
        break;
      case 'selectedPageIndex':
        final int selectedPageIndex = _controller!.selectedPageIndex;
        if (selectedPageIndex < 0 ||
            selectedPageIndex > _lastPageIndex ||
            selectedPageIndex == _currentPageIndex) {
          _suspendDataPagerUpdate = false;
          return;
        }
        final bool canChangePage = await _canChangePage(selectedPageIndex, true);
        if (canChangePage) {
          _setCurrentPageIndex(selectedPageIndex);
        }
        _raisePageNavigationEnd(canChangePage ? selectedPageIndex : _currentPageIndex);
        break;
    }
    _suspendDataPagerUpdate = false;
  }

  Future<bool> _canChangePage(int index, [bool canRaiseNavigationStartCallback = false]) async {
    if (_controller!.selectedPageIndex != index || canRaiseNavigationStartCallback) {
      _raisePageNavigationStart(_currentPageIndex);
    }

    final bool canHandle = await widget.delegate.handlePageChange(_currentPageIndex, index);
    return canHandle;
  }

  void _raisePageNavigationStart(int pageIndex) {
    if (widget.onPageNavigationStart == null) {
      return;
    }
    widget.onPageNavigationStart!(pageIndex);
  }

  void _raisePageNavigationEnd(int pageIndex) {
    if (widget.onPageNavigationEnd == null) {
      return;
    }
    widget.onPageNavigationEnd!(pageIndex);
  }

  void _setCurrentPageIndex(int index) {
    _currentPageIndex = index;
    _controller!._selectedPageIndex = index;
  }

  bool _isNavigationItemDisabled(String type) {
    switch (type) {
      case 'First':
      case 'Previous':
        return _currentPageIndex == 0;
      case 'Next':
      case 'Last':
        return _currentPageIndex == _lastPageIndex;
      default:
        return false;
    }
  }

  void _showPageJumpDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page number (1-${_formatNumber(_pageCount)})',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (String value) {
              _jumpToPage(value);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _jumpToPage(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _jumpToPage(String pageText) {
    final int? pageNumber = int.tryParse(pageText);
    if (pageNumber != null && pageNumber >= 1 && pageNumber <= _pageCount) {
      _handlePageItemTapped(pageNumber - 1);
    }
  }

  Widget _buildNavigationButton({
    required String type,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final bool isDisabled = _isNavigationItemDisabled(type);
    
    return Padding(
      padding: widget.itemPadding,
      child: SizedBox(
        width: widget.navigationItemWidth,
        height: widget.navigationItemHeight,
        child: Material(
          color: isDisabled 
              ? _dataPagerThemeHelper!.disabledItemColor
              : _dataPagerThemeHelper!.itemColor,
          borderRadius: _dataPagerThemeHelper!.itemBorderRadius as BorderRadius?,
          child: InkWell(
            borderRadius: _dataPagerThemeHelper!.itemBorderRadius as BorderRadius?,
            onTap: isDisabled ? null : onPressed,
            child: Icon(
              icon,
              size: 20,
              color: isDisabled
                  ? _dataPagerThemeHelper!.disabledItemTextStyle!.color
                  : _dataPagerThemeHelper!.itemTextStyle!.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: widget.itemPadding,
      child: SizedBox(
        width: widget.navigationItemWidth,
        height: widget.navigationItemHeight,
        child: Material(
          color: isSelected 
              ? _dataPagerThemeHelper!.selectedItemColor
              : _dataPagerThemeHelper!.itemColor,
          borderRadius: _dataPagerThemeHelper!.itemBorderRadius as BorderRadius?,
          child: InkWell(
            borderRadius: _dataPagerThemeHelper!.itemBorderRadius as BorderRadius?,
            onTap: onPressed,
            child: Center(
              child: Text(
                text,
                style: isSelected
                    ? _dataPagerThemeHelper!.selectedItemTextStyle
                    : _dataPagerThemeHelper!.itemTextStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsisButton() {
    return Padding(
      padding: widget.itemPadding,
      child: GestureDetector(
        onTap: _showPageJumpDialog,
        child: Container(
          width: widget.navigationItemWidth + 10,
          height: widget.navigationItemHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: _dataPagerThemeHelper!.itemBorderColor!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '...',
              style: _dataPagerThemeHelper!.itemTextStyle,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageItems() {
    final List<Widget> items = [];
    final int currentPage = _currentPageIndex + 1;
    final int totalPages = _pageCount;
    
    if (totalPages <= widget.visibleItemsCount) {
      // Show all pages if total pages <= visibleItemsCount
      for (int i = 1; i <= totalPages; i++) {
        items.add(_buildPageButton(
          text: i.toString(),
          isSelected: i == currentPage,
          onPressed: () => _handlePageItemTapped(i - 1),
        ));
      }
    } else {
      // Show first page
      items.add(_buildPageButton(
        text: '1',
        isSelected: currentPage == 1,
        onPressed: () => _handlePageItemTapped(0),
      ));

      if (currentPage > 2) {
        // Show ellipsis if current page is not 2
        items.add(_buildEllipsisButton());
      }

      // Show current page if it's not 1 or last page
      if (currentPage != 1 && currentPage != totalPages) {
        items.add(_buildPageButton(
          text: currentPage.toString(),
          isSelected: true,
          onPressed: () => _handlePageItemTapped(_currentPageIndex),
        ));
      }

      if (currentPage < totalPages - 1) {
        // Show ellipsis if current page is not second to last
        if (currentPage != 1) {
          items.add(_buildEllipsisButton());
        }
      }

      // Show last page if more than 1 page
      if (totalPages > 1) {
        items.add(_buildPageButton(
          text: totalPages.toString(),
          isSelected: currentPage == totalPages,
          onPressed: () => _handlePageItemTapped(totalPages - 1),
        ));
      }
    }

    return items;
  }

  Widget _buildMobileCompactPager() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page indicator on top with labelMedium style
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'on page ${_formatNumber(_currentPageIndex + 1)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        // Navigation controls in a row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.previousPageItemVisible)
              _buildNavigationButton(
                type: 'Previous',
                icon: _isRTL ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'previous'),
              ),
            ..._buildPageItems(),
            if (widget.nextPageItemVisible)
              _buildNavigationButton(
                type: 'Next',
                icon: _isRTL ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'next'),
              ),
            const SizedBox(width: 16),
            if (widget.onRowsPerPageChanged != null) ...[
              Text(
                'Rows/page',
                style: _dataPagerThemeHelper!.itemTextStyle,
              ),
              const SizedBox(width: 8),
              _buildDropDownWidget(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWebRowRangePager() {
    final int startRow = (_currentPageIndex * _rowsPerPage!) + 1;
    final int endRow = min((_currentPageIndex + 1) * _rowsPerPage!, 
                           widget.totalRows ?? (widget.delegate as DataGridSource?)?.rows.length ?? 0);
    final int totalRows = widget.totalRows ?? (widget.delegate as DataGridSource?)?.rows.length ?? 0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row range indicator on top
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onTap: _showPageJumpDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _dataPagerThemeHelper!.itemBorderColor!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Rows ${_formatNumber(startRow)} - ${_formatNumber(endRow)} of ${_formatNumber(totalRows)}',
                style: _dataPagerThemeHelper!.itemTextStyle,
              ),
            ),
          ),
        ),
        // Navigation controls with visible page items
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.firstPageItemVisible)
              _buildNavigationButton(
                type: 'First',
                icon: _isRTL ? Icons.last_page : Icons.first_page,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'first'),
              ),
            if (widget.previousPageItemVisible)
              _buildNavigationButton(
                type: 'Previous',
                icon: _isRTL ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'previous'),
              ),
            ..._buildPageItems(), // Show visible page items
            if (widget.nextPageItemVisible)
              _buildNavigationButton(
                type: 'Next',
                icon: _isRTL ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'next'),
              ),
            if (widget.lastPageItemVisible)
              _buildNavigationButton(
                type: 'Last',
                icon: _isRTL ? Icons.first_page : Icons.last_page,
                onPressed: () => _handleDataPagerControlPropertyChanged(property: 'last'),
              ),
            if (widget.onRowsPerPageChanged != null) ...[
              const SizedBox(width: 16),
              Text(
                _localization.rowsPerPageDataPagerLabel,
                style: _dataPagerThemeHelper!.itemTextStyle,
              ),
              const SizedBox(width: 8),
              _buildDropDownWidget(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDropDownWidget() {
    final List<DropdownMenuItem<int>> availableRowsPerPage =
        widget.availableRowsPerPage.map<DropdownMenuItem<int>>((int value) {
      return DropdownMenuItem<int>(
        value: value,
        child: Text(
          _formatNumber(value),
          style: _dataPagerThemeHelper!.itemTextStyle,
          textAlign: _isRTL ? TextAlign.right : TextAlign.left,
        ),
      );
    }).toList();

    return Container(
      width: _dropdownSize.width,
      height: _dropdownSize.height,
      padding: !_isRTL
          ? const EdgeInsets.fromLTRB(16, 8, 7, 8)
          : const EdgeInsets.fromLTRB(7, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: _dataPagerThemeHelper!.dropdownButtonBorderColor!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          focusColor: Colors.transparent,
          itemHeight: 48,
          items: availableRowsPerPage,
          value: _rowsPerPage,
          iconSize: 22.0,
          onChanged: (int? value) {
            _isRowsPerPageChanged = true;
            _rowsPerPage = value;
            widget.onRowsPerPageChanged!(_rowsPerPage);
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
    _localization = SfLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);
    _dataPagerThemeHelper = DataPagerThemeHelper(context);
    _isDesktop = kIsWeb ||
        themeData.platform == TargetPlatform.macOS ||
        themeData.platform == TargetPlatform.windows ||
        themeData.platform == TargetPlatform.linux;
  }

  @override
  void didUpdateWidget(SfCompactDataPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool isDataPagerControllerChanged = oldWidget.controller != widget.controller;
    final bool isDelegateChanged = oldWidget.delegate != widget.delegate;

    if (isDataPagerControllerChanged ||
        isDelegateChanged ||
        oldWidget.pageCount != widget.pageCount ||
        oldWidget.availableRowsPerPage != widget.availableRowsPerPage ||
        oldWidget.onRowsPerPageChanged != widget.onRowsPerPageChanged ||
        oldWidget.visibleItemsCount != widget.visibleItemsCount ||
        oldWidget.initialPageIndex != widget.initialPageIndex) {
      
      _setPageCountInDataGridSource(widget.pageCount);

      if (isDelegateChanged) {
        _removeDelegateListener(oldWidget);
        _addDelegateListener();
      }

      if (oldWidget.availableRowsPerPage != widget.availableRowsPerPage) {
        _rowsPerPage = widget.availableRowsPerPage.contains(_rowsPerPage)
            ? _rowsPerPage
            : widget.availableRowsPerPage[0];
      }

      if (isDataPagerControllerChanged) {
        if (oldWidget.pageCount != widget.pageCount) {
          _currentPageIndex = 0;
        }
        oldWidget.controller?.removeListener(_handleDataPagerControlPropertyChanged);
        _controller = widget.controller ?? _controller!
          ..addListener(_handleDataPagerControlPropertyChanged);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _pageCount = widget.pageCount.toInt();
    
    if (_currentPageIndex >= _pageCount && _pageCount > 0) {
      _currentPageIndex = _pageCount - 1;
    }

    final bool isWebLayout = _isDesktop && MediaQuery.of(context).size.width > _kMobileViewWidthOnWeb;

    return Card(
      elevation: 0.0,
      color: _dataPagerThemeHelper!.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isWebLayout ? _buildWebRowRangePager() : _buildMobileCompactPager(),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleDataPagerControlPropertyChanged);
    _controller?.dispose();
    _setPageCountInDataGridSource(0.0);
    _removeDelegateListener(widget);
    super.dispose();
  }
}
