# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the Syncfusion Flutter DataGrid package - a commercial Flutter widget library for displaying and manipulating tabular data. The package provides rich features including sorting, filtering, editing, paging, grouping, selection, and more.

## Development Commands

### Flutter Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis (uses package:syncfusion_flutter_core/analysis_options.yaml)
- `flutter test` - Run tests (no test directory currently exists)
- `flutter pub publish --dry-run` - Validate package for publishing

### Example App
- `cd example && flutter run` - Run the example application
- `cd example && flutter build web/ios/android` - Build example for specific platform

## Architecture Overview

### Core Components

**SfDataGrid** (`lib/src/datagrid_widget/sfdatagrid.dart`) - The main widget that displays tabular data with extensive customization options.

**DataGridSource** - Abstract class that developers extend to provide data to the grid. Must implement:
- `rows` getter returning `List<DataGridRow>`  
- `buildRow()` method returning `DataGridRowAdapter`

**SfDataPager/SfCompactDataPager** (`lib/src/datapager/`) - Pagination widgets for handling large datasets.

### Key Architecture Patterns

**Widget-Renderer Pattern**: The grid uses a separation between widgets (UI) and renderers (business logic) similar to WPF/Silverlight patterns.

**Grid Common Layer** (`lib/src/grid_common/`) - Shared utilities for scroll management, line sizing, tree structures, and coordinate systems used across datagrid components.

**Selection Management** (`lib/src/datagrid_widget/selection/`) - Centralized handling of row/cell selection with keyboard navigation support.

**Column System** (`lib/src/datagrid_widget/runtime/column.dart`) - Flexible column definition supporting different data types, custom renderers, sorting, filtering, and resizing.

### Data Flow

1. Developer creates `DataGridSource` subclass with business data
2. `SfDataGrid` widget receives the data source
3. Internal generator (`runtime/generator.dart`) creates visual rows
4. Cell renderers (`runtime/cell_renderers.dart`) handle individual cell display
5. Scrolling system manages virtualization for performance

### Key Files Structure

- `lib/datagrid.dart` - Public API exports
- `lib/src/datagrid_widget/` - Main grid implementation
- `lib/src/datapager/` - Pagination components  
- `lib/src/grid_common/` - Shared utilities and helpers

### Development Guidelines

**DataGridSource Implementation**: Always extend `DataGridSource` rather than implementing it directly. The `rows` property should return immutable data structures. DataGridSource objects should be long-lived, not recreated with each build.

**Performance**: The grid is designed for large datasets with virtualization. Avoid heavy computations in `buildRow()` method.

**Theming**: Uses Syncfusion's theme system via `package:syncfusion_flutter_core/theme.dart`.

## Current Branch Context

Working on: `compact-datapager` branch
- Main development branch: `main`
- Recent commits focus on filter popup improvements and data synchronization