import 'package:flutter/material.dart';

import '../runtime/column.dart';
import '../sfdatagrid.dart';

/// A filter popup menu tile widget identical to the one used in cell_widget.dart
class _FilterPopupMenuTile extends StatelessWidget {
  const _FilterPopupMenuTile(
      {Key? key,
      required this.child,
      this.onTap,
      this.prefix,
      this.suffix,
      this.height,
      required this.style,
      this.prefixPadding = EdgeInsets.zero})
      : super(key: key);

  final Widget child;
  final Widget? prefix;
  final Widget? suffix;
  final double? height;
  final TextStyle style;
  final VoidCallback? onTap;
  final EdgeInsets prefixPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: MaterialButton(
        onPressed: onTap,
        child: Row(
          children: <Widget>[
            Padding(
              padding: prefixPadding,
              child: SizedBox(
                width: 24.0,
                height: 24.0,
                child: prefix,
              ),
            ),
            Expanded(
              child: DefaultTextStyle(style: style, child: child),
            ),
            if (suffix != null) SizedBox(width: 40.0, child: suffix)
          ],
        ),
      ),
    );
  }
}

/// A paginated list view widget specifically designed for checkbox filter values.
/// This widget handles loading states, pagination, and search functionality.
class PaginatedFilterListView extends StatefulWidget {
  const PaginatedFilterListView({
    Key? key,
    required this.helper,
    required this.dataGridThemeHelper,
    required this.onItemTap,
    required this.onStateChanged,
    this.searchText = '',
  }) : super(key: key);

  final DataGridFilterHelper helper;
  final DataGridThemeHelper dataGridThemeHelper;
  final Function(FilterElement) onItemTap;
  final VoidCallback onStateChanged;
  final String searchText;

  @override
  State<PaginatedFilterListView> createState() => _PaginatedFilterListViewState();
}

class _PaginatedFilterListViewState extends State<PaginatedFilterListView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        if (widget.helper.checkboxFilterHelper.hasMoreData &&
            !widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore) {
          _loadMoreData();
        }
      }
    });
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) {
      return; // Prevent multiple concurrent requests
    }

    setState(() {
      _isLoadingMore = true;
    });
    try {
      await widget.helper.checkboxFilterHelper.loadNextPage();
      if (mounted) {
        setState(() {
          // Update local state to refresh the ListView with new data
        });
      }
      widget.onStateChanged();
    } catch (e) {
      debugPrint('Error loading more filter data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.searchText.isEmpty ? Icons.inbox_outlined : Icons.search_off,
              size: 48.0,
              color: widget.dataGridThemeHelper.filterPopupIconColor?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchText.isEmpty ? 'No values available' : 'No results found',
              style: widget.helper.textStyle.copyWith(
                color: widget.helper.textStyle.color?.withOpacity(0.7),
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.searchText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: widget.helper.textStyle.copyWith(
                  color: widget.helper.textStyle.color?.withOpacity(0.5),
                  fontSize: 14.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationLoadingIndicator() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.helper.checkboxFilterHelper.isLoading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: widget.helper.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Loading more...',
                  style: widget.helper.textStyle.copyWith(
                    fontSize: 11.0,
                    color: widget.helper.textStyle.color?.withOpacity(0.6),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildListItem(FilterElement item, int index) {
    final displayText = widget.helper.getDisplayValue(item.value);
    final TextStyle style = widget.helper.textStyle;

    return _FilterPopupMenuTile(
      style: style,
      height: widget.helper.tileHeight,
      prefixPadding: const EdgeInsets.only(left: 4.0, right: 10.0),
      prefix: Checkbox(
        value: item.isSelected,
        onChanged: (_) => widget.onItemTap(item),
      ),
      onTap: () => widget.onItemTap(item),
      child: Text(displayText, overflow: TextOverflow.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state if no items found and not loading
    if (widget.helper.checkboxFilterHelper.items.isEmpty &&
        !widget.helper.checkboxFilterHelper.isLoading) {
      return _buildEmptyState();
    }

    final itemCount = widget.helper.checkboxFilterHelper.items.length +
        (widget.helper.checkboxFilterHelper.hasMoreData ? 1 : 0);

    return Column(
      children: [
        // Show horizontal progress indicator when loading/searching
        if (widget.helper.checkboxFilterHelper.items.isEmpty &&
            widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore)
          Expanded(
            child: Container(
              height: 30,
              width: 30,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CircularProgressIndicator(
                color: widget.helper.primaryColor,
                backgroundColor: widget.helper.primaryColor.withOpacity(0.2),
                strokeWidth: 2.0,
              ),
            ),
          ),
        if (widget.helper.checkboxFilterHelper.items.isNotEmpty &&
            widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore)
          Container(
            height: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: LinearProgressIndicator(
              color: widget.helper.primaryColor,
              backgroundColor: widget.helper.primaryColor.withOpacity(0.2),
            ),
          ),
        // Show the list even when loading
        if (widget.helper.checkboxFilterHelper.items.isEmpty) const SizedBox.shrink() else Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: itemCount,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index < widget.helper.checkboxFilterHelper.items.length) {
                      final item = widget.helper.checkboxFilterHelper.items[index];
                      return _buildListItem(item, index);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
        if (widget.helper.checkboxFilterHelper.hasMoreData && _isLoadingMore)
          _buildPaginationLoadingIndicator(),
      ],
    );
  }
}

/// A specialized paginated list view for single selection in dialogs.
class _PaginatedSingleSelectionListView extends StatefulWidget {
  const _PaginatedSingleSelectionListView({
    Key? key,
    required this.helper,
    required this.dataGridThemeHelper,
    required this.onItemTap,
    required this.selectedValue,
    required this.onStateChanged,
    this.searchText = '',
  }) : super(key: key);

  final DataGridFilterHelper helper;
  final DataGridThemeHelper dataGridThemeHelper;
  final Function(FilterElement) onItemTap;
  final Object? selectedValue;
  final VoidCallback onStateChanged;
  final String searchText;

  @override
  State<_PaginatedSingleSelectionListView> createState() =>
      _PaginatedSingleSelectionListViewState();
}

class _PaginatedSingleSelectionListViewState extends State<_PaginatedSingleSelectionListView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initScrollListener();
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) {
      return; // Prevent multiple concurrent requests
    }
    final lastPosition = _scrollController.position.pixels;
    setState(() {
      _isLoadingMore = true;
    });
    _scrollController.animateTo(
      lastPosition,
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeInOut,
    );
    try {
      await widget.helper.checkboxFilterHelper.loadNextPage();
      if (mounted) {
        setState(() {
          // Update local state to refresh the ListView with new data
        });
      }
      widget.onStateChanged();
    } catch (e) {
      debugPrint('Error loading more filter data: $e');
    } finally {
      final lastPosition = _scrollController.position.pixels;
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      _scrollController.animateTo(
        lastPosition,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        if (widget.helper.checkboxFilterHelper.hasMoreData &&
            !widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore) {
          _loadMoreData();
        }
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.searchText.isEmpty ? Icons.inbox_outlined : Icons.search_off,
              size: 48.0,
              color: widget.dataGridThemeHelper.filterPopupIconColor?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchText.isEmpty ? 'No values available' : 'No results found',
              style: widget.helper.textStyle.copyWith(
                color: widget.helper.textStyle.color?.withOpacity(0.7),
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.searchText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: widget.helper.textStyle.copyWith(
                  color: widget.helper.textStyle.color?.withOpacity(0.5),
                  fontSize: 14.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationLoadingIndicator() {
    return Container(
      height: 50,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: widget.helper.checkboxFilterHelper.isLoading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: widget.helper.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Loading more...',
                  style: widget.helper.textStyle.copyWith(
                    fontSize: 11.0,
                    color: widget.helper.textStyle.color?.withOpacity(0.6),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildListItem(FilterElement item, int index) {
    final displayText = widget.helper.getDisplayValue(item.value);
    final isSelected = widget.selectedValue == item.value;
    final TextStyle style = widget.helper.textStyle;

    return _FilterPopupMenuTile(
      style: style,
      height: widget.helper.tileHeight,
      prefixPadding: const EdgeInsets.only(left: 4.0, right: 10.0),
      prefix: isSelected
          ? Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.helper.primaryColor,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14.0,
              ),
            )
          : const SizedBox(width: 20.0, height: 20.0),
      onTap: () => widget.onItemTap(item),
      child: Text(displayText, overflow: TextOverflow.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state if no items found and not loading
    if (widget.helper.checkboxFilterHelper.items.isEmpty &&
        !widget.helper.checkboxFilterHelper.isLoading) {
      return _buildEmptyState();
    }

    final itemCount = widget.helper.checkboxFilterHelper.items.length +
        (widget.helper.checkboxFilterHelper.hasMoreData ? 1 : 0);

    return Column(
      children: [
        // Show horizontal progress indicator when loading/searching
        if (widget.helper.checkboxFilterHelper.items.isEmpty &&
            widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore)
          Expanded(
            child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                color: widget.helper.primaryColor,
                backgroundColor: widget.helper.primaryColor.withOpacity(0.2),
              ),
            ),
          ),
        if (widget.helper.checkboxFilterHelper.items.isNotEmpty &&
            widget.helper.checkboxFilterHelper.isLoading &&
            !_isLoadingMore)
          Container(
            height: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: LinearProgressIndicator(
              color: widget.helper.primaryColor,
              backgroundColor: widget.helper.primaryColor.withOpacity(0.2),
            ),
          ),
        // Show the list even when loading

        // Show the list even when loading
        Expanded(
          child: widget.helper.checkboxFilterHelper.items.isEmpty
              ? Container() // Empty container when no items yet
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: itemCount,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index < widget.helper.checkboxFilterHelper.items.length) {
                      final item = widget.helper.checkboxFilterHelper.items[index];
                      return _buildListItem(item, index);
                    } else {
                      // Loading indicator for pagination
                      return _buildPaginationLoadingIndicator();
                    }
                  },
                ),
        ),
      ],
    );
  }
}

/// A paginated value picker dialog for selecting filter values.
/// This dialog provides a modern UI with search functionality and pagination support.
class PaginatedValuePickerDialog extends StatefulWidget {
  const PaginatedValuePickerDialog({
    Key? key,
    required this.helper,
    required this.dataGridThemeHelper,
    this.currentValue,
  }) : super(key: key);

  final DataGridFilterHelper helper;
  final DataGridThemeHelper dataGridThemeHelper;
  final Object? currentValue;

  @override
  State<PaginatedValuePickerDialog> createState() => _PaginatedValuePickerDialogState();
}

class _PaginatedValuePickerDialogState extends State<PaginatedValuePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  Object? _selectedValue;
  String _currentSearchText = '';

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_currentSearchText == value) {
      return;
    }

    setState(() {
      _currentSearchText = value;
    });

    widget.helper.checkboxFilterHelper.onSearchTextFieldTextChanged(
      value,
      onCompleted: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _onItemTap(FilterElement item) {
    setState(() {
      _selectedValue = item.value;
    });
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: widget.helper.textStyle,
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.dataGridThemeHelper.filterPopupOuterColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: widget.dataGridThemeHelper.filterPopupBorderColor!.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: widget.helper.primaryColor,
              width: 2.0,
            ),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? Icon(
                  Icons.search,
                  color: widget.dataGridThemeHelper.filterPopupIconColor?.withOpacity(0.6),
                  size: 20.0,
                )
              : IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: widget.dataGridThemeHelper.filterPopupIconColor?.withOpacity(0.8),
                    size: 20.0,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  tooltip: 'Clear search',
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          hintText: 'Search filter values...',
          hintStyle: widget.helper.textStyle.copyWith(
            color: widget.helper.textStyle.color?.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildValuesList() {
    return Expanded(
      child: Column(
        children: [
          // Show horizontal progress indicator when loading/searching
          if (widget.helper.checkboxFilterHelper.isLoading)
            Container(
              height: 4.0,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LinearProgressIndicator(
                color: widget.helper.primaryColor,
                backgroundColor: widget.helper.primaryColor.withOpacity(0.2),
              ),
            ),

          // Values list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _PaginatedSingleSelectionListView(
                helper: widget.helper,
                dataGridThemeHelper: widget.dataGridThemeHelper,
                onItemTap: _onItemTap,
                selectedValue: _selectedValue,
                onStateChanged: () {
                  if (mounted) {
                    setState(() {});
                  }
                },
                searchText: _currentSearchText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.45).clamp(400.0, 600.0);
    final dialogHeight = (screenSize.height * 0.7).clamp(500.0, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24.0),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: widget.dataGridThemeHelper.filterPopupBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20.0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 40.0,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget.dataGridThemeHelper.filterPopupBorderColor!.withOpacity(0.2),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: widget.helper.primaryColor,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Select Filter Value',
                      style: widget.helper.textStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18.0,
                        color: widget.helper.textStyle.color,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: widget.dataGridThemeHelper.filterPopupIconColor?.withOpacity(0.7),
                      size: 22.0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20.0,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search box
            _buildSearchBox(),

            // Values list
            _buildValuesList(),

            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 20.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: widget.dataGridThemeHelper.filterPopupBorderColor!.withOpacity(0.2),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  // Show selected count if any value is selected
                  if (_selectedValue != null)
                    Expanded(
                      child: Text(
                        'Selected: ${widget.helper.getDisplayValue(_selectedValue)}',
                        style: widget.helper.textStyle.copyWith(
                          color: widget.helper.primaryColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),

                  // Buttons
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: widget.helper.textStyle.copyWith(
                        color: widget.helper.textStyle.color?.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton(
                    onPressed: _selectedValue != null
                        ? () => Navigator.of(context).pop(_selectedValue)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.helper.primaryColor,
                      disabledBackgroundColor: widget.helper.primaryColor.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 0.0,
                    ),
                    child: Text(
                      'Apply',
                      style: widget.helper.textStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
